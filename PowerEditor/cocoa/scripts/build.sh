#!/bin/bash
################################################################################
# Notepad++ macOS Build Script
# Builds Scintilla.framework, Lexilla.framework, and Notepad++.app
################################################################################

set -e  # Exit on error
set -u  # Exit on undefined variable

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
COCOA_DIR="${ROOT_DIR}/PowerEditor/cocoa"
SCINTILLA_DIR="${ROOT_DIR}/scintilla"
LEXILLA_DIR="${ROOT_DIR}/lexilla"
BUILD_DIR="${COCOA_DIR}/build"
PRODUCT_NAME="Notepad++"

# Default configuration
CONFIGURATION="${CONFIGURATION:-Release}"
ARCH="${ARCH:-$(uname -m)}"
DEPLOYMENT_TARGET="${MACOSX_DEPLOYMENT_TARGET:-11.0}"
CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY:-}"
TEAM_ID="${TEAM_ID:-}"
VERBOSE="${VERBOSE:-0}"

# Derived directories
SCINTILLA_PROJECT="${SCINTILLA_DIR}/cocoa/Scintilla/Scintilla.xcodeproj"
LEXILLA_PROJECT="${LEXILLA_DIR}/src/Lexilla/Lexilla.xcodeproj"
APP_BUNDLE="${BUILD_DIR}/${CONFIGURATION}/${PRODUCT_NAME}.app"
FRAMEWORKS_DIR="${APP_BUNDLE}/Contents/Frameworks"

################################################################################
# Helper Functions
################################################################################

log() {
    echo -e "${BLUE}[BUILD]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_header() {
    echo ""
    echo "======================================================================"
    echo "$1"
    echo "======================================================================"
}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        error "Required command '$1' not found. Please install it first."
        exit 1
    fi
}

get_xcodebuild_flags() {
    local flags="-configuration ${CONFIGURATION}"
    flags="${flags} -arch ${ARCH}"
    flags="${flags} MACOSX_DEPLOYMENT_TARGET=${DEPLOYMENT_TARGET}"
    
    if [[ -n "${CODE_SIGN_IDENTITY}" ]]; then
        flags="${flags} CODE_SIGN_IDENTITY='${CODE_SIGN_IDENTITY}'"
    fi
    
    if [[ -n "${TEAM_ID}" ]]; then
        flags="${flags} DEVELOPMENT_TEAM='${TEAM_ID}'"
    fi
    
    if [[ "${VERBOSE}" == "1" ]]; then
        flags="${flags} -verbose"
    else
        flags="${flags} -quiet"
    fi
    
    echo "${flags}"
}

################################################################################
# Build Functions
################################################################################

build_scintilla() {
    print_header "Building Scintilla.framework"
    
    if [[ ! -d "${SCINTILLA_PROJECT}" ]]; then
        error "Scintilla project not found at ${SCINTILLA_PROJECT}"
        exit 1
    fi
    
    log "Building for architecture: ${ARCH}"
    log "Configuration: ${CONFIGURATION}"
    log "Deployment target: ${DEPLOYMENT_TARGET}"
    
    cd "${SCINTILLA_DIR}/cocoa"
    
    local xcode_flags=$(get_xcodebuild_flags)
    
    eval xcodebuild -project Scintilla/Scintilla.xcodeproj \
        -scheme Scintilla \
        ${xcode_flags} \
        SYMROOT="${BUILD_DIR}" \
        OBJROOT="${BUILD_DIR}/Intermediates" \
        build
    
    # Verify framework was built
    local scintilla_framework="${BUILD_DIR}/${CONFIGURATION}/Scintilla.framework"
    if [[ -d "${scintilla_framework}" ]]; then
        success "Scintilla.framework built successfully"
        log "Location: ${scintilla_framework}"
    else
        error "Failed to build Scintilla.framework"
        exit 1
    fi
}

build_lexilla() {
    print_header "Building Lexilla.framework"
    
    if [[ ! -d "${LEXILLA_PROJECT}" ]]; then
        error "Lexilla project not found at ${LEXILLA_PROJECT}"
        exit 1
    fi
    
    log "Building for architecture: ${ARCH}"
    log "Configuration: ${CONFIGURATION}"
    
    cd "${LEXILLA_DIR}/src/Lexilla"
    
    local xcode_flags=$(get_xcodebuild_flags)
    
    eval xcodebuild -project Lexilla.xcodeproj \
        -scheme Lexilla \
        ${xcode_flags} \
        SYMROOT="${BUILD_DIR}" \
        OBJROOT="${BUILD_DIR}/Intermediates" \
        build
    
    # Verify framework was built
    local lexilla_framework="${BUILD_DIR}/${CONFIGURATION}/Lexilla.framework"
    if [[ -d "${lexilla_framework}" ]]; then
        success "Lexilla.framework built successfully"
        log "Location: ${lexilla_framework}"
    else
        error "Failed to build Lexilla.framework"
        exit 1
    fi
}

find_app_project() {
    # Look for Xcode project in cocoa directory
    local project=$(find "${COCOA_DIR}" -maxdepth 1 -name "*.xcodeproj" | head -n 1)
    
    if [[ -z "${project}" ]]; then
        # Try to find in subdirectories
        project=$(find "${COCOA_DIR}" -maxdepth 2 -name "*.xcodeproj" | head -n 1)
    fi
    
    echo "${project}"
}

build_app() {
    print_header "Building ${PRODUCT_NAME}.app"
    
    local app_project=$(find_app_project)
    
    if [[ -z "${app_project}" ]]; then
        error "No Xcode project found in ${COCOA_DIR}"
        error "Please create an Xcode project for the macOS app first."
        exit 1
    fi
    
    log "Using project: ${app_project}"
    log "Configuration: ${CONFIGURATION}"
    
    cd "${COCOA_DIR}"
    
    local xcode_flags=$(get_xcodebuild_flags)
    
    # Try to auto-detect scheme name
    local scheme=$(xcodebuild -project "${app_project}" -list 2>/dev/null | \
                   grep -A 1 "Schemes:" | tail -n 1 | xargs)
    
    if [[ -z "${scheme}" ]]; then
        scheme="${PRODUCT_NAME}"
    fi
    
    log "Using scheme: ${scheme}"
    
    eval xcodebuild -project "${app_project}" \
        -scheme "${scheme}" \
        ${xcode_flags} \
        SYMROOT="${BUILD_DIR}" \
        OBJROOT="${BUILD_DIR}/Intermediates" \
        build
    
    if [[ -d "${APP_BUNDLE}" ]]; then
        success "${PRODUCT_NAME}.app built successfully"
        log "Location: ${APP_BUNDLE}"
    else
        error "Failed to build ${PRODUCT_NAME}.app"
        exit 1
    fi
}

copy_frameworks() {
    print_header "Copying Frameworks to App Bundle"
    
    if [[ ! -d "${APP_BUNDLE}" ]]; then
        error "App bundle not found at ${APP_BUNDLE}"
        exit 1
    fi
    
    # Create Frameworks directory if it doesn't exist
    mkdir -p "${FRAMEWORKS_DIR}"
    
    # Copy Scintilla.framework
    local scintilla_src="${BUILD_DIR}/${CONFIGURATION}/Scintilla.framework"
    if [[ -d "${scintilla_src}" ]]; then
        log "Copying Scintilla.framework..."
        rm -rf "${FRAMEWORKS_DIR}/Scintilla.framework"
        cp -R "${scintilla_src}" "${FRAMEWORKS_DIR}/"
        success "Scintilla.framework copied"
    else
        error "Scintilla.framework not found at ${scintilla_src}"
        exit 1
    fi
    
    # Copy Lexilla.framework
    local lexilla_src="${BUILD_DIR}/${CONFIGURATION}/Lexilla.framework"
    if [[ -d "${lexilla_src}" ]]; then
        log "Copying Lexilla.framework..."
        rm -rf "${FRAMEWORKS_DIR}/Lexilla.framework"
        cp -R "${lexilla_src}" "${FRAMEWORKS_DIR}/"
        success "Lexilla.framework copied"
    else
        error "Lexilla.framework not found at ${lexilla_src}"
        exit 1
    fi
    
    # Update framework load paths
    fix_framework_paths
}

fix_framework_paths() {
    log "Fixing framework load paths..."
    
    local executable="${APP_BUNDLE}/Contents/MacOS/${PRODUCT_NAME}"
    
    if [[ ! -f "${executable}" ]]; then
        warn "Executable not found at ${executable}"
        return
    fi
    
    # Fix Scintilla load path
    install_name_tool -change \
        "@rpath/Scintilla.framework/Versions/A/Scintilla" \
        "@executable_path/../Frameworks/Scintilla.framework/Versions/A/Scintilla" \
        "${executable}" 2>/dev/null || true
    
    # Fix Lexilla load path
    install_name_tool -change \
        "@rpath/Lexilla.framework/Versions/A/Lexilla" \
        "@executable_path/../Frameworks/Lexilla.framework/Versions/A/Lexilla" \
        "${executable}" 2>/dev/null || true
    
    success "Framework load paths updated"
}

copy_resources() {
    print_header "Copying Resources"
    
    local resources_src="${COCOA_DIR}/Resources"
    local resources_dest="${APP_BUNDLE}/Contents/Resources"
    
    if [[ ! -d "${resources_src}" ]]; then
        warn "Resources directory not found at ${resources_src}"
        return
    fi
    
    # Copy config files (if they exist)
    for config_file in config.xml langs.xml stylers.xml; do
        if [[ -f "${ROOT_DIR}/PowerEditor/src/${config_file}" ]]; then
            log "Copying ${config_file}..."
            cp "${ROOT_DIR}/PowerEditor/src/${config_file}" "${resources_dest}/"
        fi
    done
    
    # Copy icons (if they exist)
    if [[ -d "${resources_src}/Icons" ]]; then
        log "Copying icons..."
        cp -R "${resources_src}/Icons" "${resources_dest}/"
    fi
    
    # Copy themes (if they exist)
    if [[ -d "${ROOT_DIR}/PowerEditor/src/themes" ]]; then
        log "Copying themes..."
        mkdir -p "${resources_dest}/themes"
        cp -R "${ROOT_DIR}/PowerEditor/src/themes/"* "${resources_dest}/themes/" 2>/dev/null || true
    fi
    
    success "Resources copied"
}

code_sign_app() {
    print_header "Code Signing"
    
    if [[ -z "${CODE_SIGN_IDENTITY}" ]]; then
        warn "No code signing identity specified. Skipping code signing."
        warn "Set CODE_SIGN_IDENTITY environment variable to enable signing."
        return
    fi
    
    log "Signing with identity: ${CODE_SIGN_IDENTITY}"
    
    # Sign frameworks first
    for framework in "${FRAMEWORKS_DIR}"/*.framework; do
        if [[ -d "${framework}" ]]; then
            log "Signing $(basename "${framework}")..."
            codesign --force --deep --sign "${CODE_SIGN_IDENTITY}" \
                --timestamp --options runtime \
                "${framework}"
        fi
    done
    
    # Sign the app bundle
    log "Signing ${PRODUCT_NAME}.app..."
    
    local entitlements="${COCOA_DIR}/Resources/${PRODUCT_NAME}.entitlements"
    local sign_flags="--force --deep --sign ${CODE_SIGN_IDENTITY} --timestamp --options runtime"
    
    if [[ -f "${entitlements}" ]]; then
        sign_flags="${sign_flags} --entitlements ${entitlements}"
    fi
    
    eval codesign ${sign_flags} "${APP_BUNDLE}"
    
    # Verify signature
    log "Verifying signature..."
    codesign --verify --verbose "${APP_BUNDLE}"
    
    success "Code signing completed"
}

verify_app() {
    print_header "Verifying Application"
    
    if [[ ! -d "${APP_BUNDLE}" ]]; then
        error "App bundle not found"
        exit 1
    fi
    
    # Check executable exists
    local executable="${APP_BUNDLE}/Contents/MacOS/${PRODUCT_NAME}"
    if [[ ! -f "${executable}" ]]; then
        error "Executable not found at ${executable}"
        exit 1
    fi
    
    # Check frameworks
    for framework in Scintilla Lexilla; do
        if [[ ! -d "${FRAMEWORKS_DIR}/${framework}.framework" ]]; then
            error "${framework}.framework not found in app bundle"
            exit 1
        fi
    done
    
    # Check Info.plist
    if [[ ! -f "${APP_BUNDLE}/Contents/Info.plist" ]]; then
        error "Info.plist not found"
        exit 1
    fi
    
    # Get app version
    local version=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" \
                    "${APP_BUNDLE}/Contents/Info.plist" 2>/dev/null || echo "unknown")
    
    success "Application verification passed"
    log "App bundle: ${APP_BUNDLE}"
    log "Version: ${version}"
    log "Architecture: ${ARCH}"
    
    # Show app size
    local app_size=$(du -sh "${APP_BUNDLE}" | cut -f1)
    log "Size: ${app_size}"
}

print_usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] [TARGETS]

Build script for Notepad++ macOS

TARGETS:
    scintilla   - Build Scintilla.framework only
    lexilla     - Build Lexilla.framework only
    frameworks  - Build both frameworks
    app         - Build Notepad++.app only
    all         - Build everything (default)
    clean       - Clean build artifacts

OPTIONS:
    -c, --configuration CONFIG  Build configuration (Debug|Release) [default: Release]
    -a, --arch ARCH            Target architecture (arm64|x86_64) [default: current]
    -t, --target VERSION       macOS deployment target [default: 11.0]
    -s, --sign IDENTITY        Code signing identity
    -i, --team-id ID           Development team ID
    -v, --verbose              Verbose output
    -h, --help                 Show this help message

ENVIRONMENT VARIABLES:
    CONFIGURATION              Build configuration
    ARCH                       Target architecture
    MACOSX_DEPLOYMENT_TARGET   Deployment target version
    CODE_SIGN_IDENTITY         Code signing identity
    TEAM_ID                    Development team ID
    VERBOSE                    Enable verbose output (1=yes, 0=no)

EXAMPLES:
    # Build everything in Release mode
    $(basename "$0")

    # Build in Debug mode
    $(basename "$0") -c Debug

    # Build for Intel Macs
    $(basename "$0") -a x86_64

    # Build frameworks only
    $(basename "$0") frameworks

    # Build with code signing
    $(basename "$0") -s "Developer ID Application: Your Name (TEAM_ID)"

    # Clean build
    $(basename "$0") clean

EOF
}

################################################################################
# Main
################################################################################

main() {
    local targets=()
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -c|--configuration)
                CONFIGURATION="$2"
                shift 2
                ;;
            -a|--arch)
                ARCH="$2"
                shift 2
                ;;
            -t|--target)
                DEPLOYMENT_TARGET="$2"
                shift 2
                ;;
            -s|--sign)
                CODE_SIGN_IDENTITY="$2"
                shift 2
                ;;
            -i|--team-id)
                TEAM_ID="$2"
                shift 2
                ;;
            -v|--verbose)
                VERBOSE=1
                shift
                ;;
            -h|--help)
                print_usage
                exit 0
                ;;
            clean|scintilla|lexilla|frameworks|app|all)
                targets+=("$1")
                shift
                ;;
            *)
                error "Unknown option: $1"
                print_usage
                exit 1
                ;;
        esac
    done
    
    # Default to 'all' if no targets specified
    if [[ ${#targets[@]} -eq 0 ]]; then
        targets=("all")
    fi
    
    # Check prerequisites
    check_command xcodebuild
    check_command install_name_tool
    
    print_header "Notepad++ macOS Build"
    log "Root directory: ${ROOT_DIR}"
    log "Configuration: ${CONFIGURATION}"
    log "Architecture: ${ARCH}"
    log "Deployment target: ${DEPLOYMENT_TARGET}"
    
    # Process targets
    for target in "${targets[@]}"; do
        case $target in
            clean)
                print_header "Cleaning Build Artifacts"
                rm -rf "${BUILD_DIR}"
                success "Clean completed"
                ;;
            scintilla)
                build_scintilla
                ;;
            lexilla)
                build_lexilla
                ;;
            frameworks)
                build_scintilla
                build_lexilla
                ;;
            app)
                build_app
                copy_frameworks
                copy_resources
                code_sign_app
                verify_app
                ;;
            all)
                build_scintilla
                build_lexilla
                build_app
                copy_frameworks
                copy_resources
                code_sign_app
                verify_app
                ;;
        esac
    done
    
    print_header "Build Completed Successfully"
    success "All tasks completed!"
    
    if [[ -d "${APP_BUNDLE}" ]]; then
        echo ""
        echo "To run the application:"
        echo "  open \"${APP_BUNDLE}\""
        echo ""
        echo "To create a distributable DMG:"
        echo "  ${SCRIPT_DIR}/package.sh"
    fi
}

# Run main function
main "$@"
