#!/bin/bash
################################################################################
# Notepad++ macOS Packaging Script
# Creates a distributable .dmg file with custom appearance
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
BUILD_DIR="${COCOA_DIR}/build"
PRODUCT_NAME="Notepad++"

# Default configuration
CONFIGURATION="${CONFIGURATION:-Release}"
OUTPUT_DIR="${OUTPUT_DIR:-${BUILD_DIR}}"
DMG_NAME="${DMG_NAME:-}"
NOTARIZE="${NOTARIZE:-0}"
SKIP_BUILD="${SKIP_BUILD:-0}"

# DMG settings
DMG_WINDOW_WIDTH=600
DMG_WINDOW_HEIGHT=450
DMG_ICON_SIZE=128
DMG_TEXT_SIZE=14
APP_ICON_X=150
APP_ICON_Y=180
APPS_ICON_X=450
APPS_ICON_Y=180

################################################################################
# Helper Functions
################################################################################

log() {
    echo -e "${BLUE}[PACKAGE]${NC} $1"
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

################################################################################
# Packaging Functions
################################################################################

get_app_version() {
    local app_bundle="$1"
    local version=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" \
                    "${app_bundle}/Contents/Info.plist" 2>/dev/null || echo "1.0.0")
    echo "${version}"
}

get_app_build() {
    local app_bundle="$1"
    local build=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" \
                  "${app_bundle}/Contents/Info.plist" 2>/dev/null || echo "1")
    echo "${build}"
}

verify_app_bundle() {
    print_header "Verifying Application Bundle"
    
    local app_bundle="${BUILD_DIR}/${CONFIGURATION}/${PRODUCT_NAME}.app"
    
    if [[ ! -d "${app_bundle}" ]]; then
        error "Application bundle not found at ${app_bundle}"
        error "Please run build.sh first to build the application."
        exit 1
    fi
    
    # Verify executable
    if [[ ! -f "${app_bundle}/Contents/MacOS/${PRODUCT_NAME}" ]]; then
        error "Application executable not found"
        exit 1
    fi
    
    # Verify frameworks
    for framework in Scintilla Lexilla; do
        if [[ ! -d "${app_bundle}/Contents/Frameworks/${framework}.framework" ]]; then
            error "${framework}.framework not found in app bundle"
            exit 1
        fi
    done
    
    local version=$(get_app_version "${app_bundle}")
    local build=$(get_app_build "${app_bundle}")
    
    success "Application bundle verified"
    log "Version: ${version} (Build ${build})"
}

create_dmg_staging() {
    print_header "Creating DMG Staging Area"
    
    local app_bundle="${BUILD_DIR}/${CONFIGURATION}/${PRODUCT_NAME}.app"
    local staging_dir="${BUILD_DIR}/dmg-staging"
    
    # Clean up old staging directory
    if [[ -d "${staging_dir}" ]]; then
        log "Removing old staging directory..."
        rm -rf "${staging_dir}"
    fi
    
    # Create staging directory
    mkdir -p "${staging_dir}"
    log "Staging directory: ${staging_dir}"
    
    # Copy application bundle
    log "Copying ${PRODUCT_NAME}.app..."
    cp -R "${app_bundle}" "${staging_dir}/"
    
    # Create symlink to Applications folder
    log "Creating Applications symlink..."
    ln -s /Applications "${staging_dir}/Applications"
    
    # Copy background image if exists
    local bg_image="${COCOA_DIR}/Resources/dmg-background.png"
    if [[ -f "${bg_image}" ]]; then
        log "Copying background image..."
        mkdir -p "${staging_dir}/.background"
        cp "${bg_image}" "${staging_dir}/.background/"
    fi
    
    # Create README if exists
    local readme="${ROOT_DIR}/macOS_README.md"
    if [[ -f "${readme}" ]]; then
        log "Copying README..."
        cp "${readme}" "${staging_dir}/README.txt"
    fi
    
    # Copy license
    local license="${ROOT_DIR}/LICENSE"
    if [[ -f "${license}" ]]; then
        log "Copying LICENSE..."
        cp "${license}" "${staging_dir}/LICENSE.txt"
    fi
    
    success "Staging area created"
    echo "${staging_dir}"
}

create_dmg() {
    print_header "Creating DMG File"
    
    local staging_dir="$1"
    local version=$(get_app_version "${staging_dir}/${PRODUCT_NAME}.app")
    
    # Determine DMG name
    if [[ -z "${DMG_NAME}" ]]; then
        DMG_NAME="${PRODUCT_NAME}-${version}-macOS"
    fi
    
    local temp_dmg="${BUILD_DIR}/${DMG_NAME}-temp.dmg"
    local final_dmg="${OUTPUT_DIR}/${DMG_NAME}.dmg"
    
    # Clean up old DMG files
    rm -f "${temp_dmg}" "${final_dmg}"
    
    # Create temporary DMG
    log "Creating temporary DMG..."
    
    # Calculate size (app size + 100MB buffer)
    local staging_size=$(du -sm "${staging_dir}" | cut -f1)
    local dmg_size=$((staging_size + 100))
    
    hdiutil create -srcfolder "${staging_dir}" \
        -volname "${PRODUCT_NAME}" \
        -fs HFS+ \
        -fsargs "-c c=64,a=16,e=16" \
        -format UDRW \
        -size ${dmg_size}m \
        "${temp_dmg}"
    
    success "Temporary DMG created"
    
    # Mount the DMG
    log "Mounting DMG..."
    local mount_point=$(hdiutil attach -readwrite -noverify -noautoopen "${temp_dmg}" | \
                        egrep '^/dev/' | sed 1q | awk '{print $3}')
    
    if [[ -z "${mount_point}" ]]; then
        error "Failed to mount DMG"
        exit 1
    fi
    
    log "Mounted at: ${mount_point}"
    
    # Customize DMG appearance
    customize_dmg_appearance "${mount_point}"
    
    # Wait for changes to be written
    sleep 2
    
    # Unmount
    log "Unmounting DMG..."
    hdiutil detach "${mount_point}" -quiet || true
    sleep 2
    
    # Convert to compressed DMG
    log "Compressing DMG..."
    hdiutil convert "${temp_dmg}" \
        -format UDZO \
        -imagekey zlib-level=9 \
        -o "${final_dmg}"
    
    # Clean up temp DMG
    rm -f "${temp_dmg}"
    
    # Calculate final size
    local dmg_size=$(du -h "${final_dmg}" | cut -f1)
    
    success "DMG created successfully"
    log "Location: ${final_dmg}"
    log "Size: ${dmg_size}"
    
    echo "${final_dmg}"
}

customize_dmg_appearance() {
    local mount_point="$1"
    
    log "Customizing DMG appearance..."
    
    # Use AppleScript to set window properties
    osascript <<EOF
tell application "Finder"
    tell disk "${PRODUCT_NAME}"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {100, 100, $((100 + DMG_WINDOW_WIDTH)), $((100 + DMG_WINDOW_HEIGHT))}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to ${DMG_ICON_SIZE}
        set text size of viewOptions to ${DMG_TEXT_SIZE}
        
        -- Set icon positions
        set position of item "${PRODUCT_NAME}.app" of container window to {${APP_ICON_X}, ${APP_ICON_Y}}
        set position of item "Applications" of container window to {${APPS_ICON_X}, ${APPS_ICON_Y}}
        
        -- Set background if exists
        try
            set background picture of viewOptions to file ".background:dmg-background.png"
        end try
        
        -- Position additional files
        try
            set position of item "README.txt" of container window to {150, 350}
        end try
        
        try
            set position of item "LICENSE.txt" of container window to {450, 350}
        end try
        
        close
        open
        update without registering applications
        delay 2
    end tell
end tell
EOF
    
    # Set custom icon for the DMG volume (if available)
    local volume_icon="${COCOA_DIR}/Resources/VolumeIcon.icns"
    if [[ -f "${volume_icon}" ]]; then
        log "Setting volume icon..."
        cp "${volume_icon}" "${mount_point}/.VolumeIcon.icns"
        SetFile -c icnC "${mount_point}/.VolumeIcon.icns"
        SetFile -a C "${mount_point}"
    fi
    
    # Hide background folder
    if [[ -d "${mount_point}/.background" ]]; then
        SetFile -a V "${mount_point}/.background" 2>/dev/null || true
    fi
    
    success "DMG appearance customized"
}

notarize_dmg() {
    print_header "Notarizing DMG"
    
    local dmg_file="$1"
    
    if [[ -z "${APPLE_ID}" ]] || [[ -z "${APPLE_TEAM_ID}" ]] || [[ -z "${APPLE_PASSWORD}" ]]; then
        error "Notarization requires APPLE_ID, APPLE_TEAM_ID, and APPLE_PASSWORD environment variables"
        exit 1
    fi
    
    log "Submitting to notarization service..."
    log "This may take several minutes..."
    
    # Submit for notarization
    xcrun notarytool submit "${dmg_file}" \
        --apple-id "${APPLE_ID}" \
        --team-id "${APPLE_TEAM_ID}" \
        --password "${APPLE_PASSWORD}" \
        --wait
    
    # Staple the ticket
    log "Stapling notarization ticket..."
    xcrun stapler staple "${dmg_file}"
    
    success "Notarization completed"
}

verify_dmg() {
    print_header "Verifying DMG"
    
    local dmg_file="$1"
    
    # Verify DMG can be mounted
    log "Testing DMG mount..."
    local mount_point=$(hdiutil attach -noverify -noautoopen "${dmg_file}" | \
                        egrep '^/dev/' | sed 1q | awk '{print $3}')
    
    if [[ -z "${mount_point}" ]]; then
        error "Failed to mount DMG for verification"
        exit 1
    fi
    
    # Verify app exists
    if [[ ! -d "${mount_point}/${PRODUCT_NAME}.app" ]]; then
        error "Application not found in DMG"
        hdiutil detach "${mount_point}" -quiet
        exit 1
    fi
    
    # Verify app signature (if signed)
    if codesign -v "${mount_point}/${PRODUCT_NAME}.app" 2>/dev/null; then
        log "Application signature verified"
    fi
    
    # Unmount
    hdiutil detach "${mount_point}" -quiet
    
    success "DMG verification passed"
}

print_usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Package Notepad++ macOS application into a distributable DMG

OPTIONS:
    -c, --configuration CONFIG  Build configuration (Debug|Release) [default: Release]
    -o, --output DIR           Output directory for DMG [default: build dir]
    -n, --name NAME            DMG file name (without .dmg extension)
    -s, --skip-build           Skip building, package existing app
    --notarize                 Notarize the DMG (requires Apple Developer account)
    -h, --help                 Show this help message

ENVIRONMENT VARIABLES:
    CONFIGURATION              Build configuration
    OUTPUT_DIR                 Output directory for DMG
    DMG_NAME                   Custom DMG file name
    SKIP_BUILD                 Skip build step (1=yes, 0=no)
    NOTARIZE                   Enable notarization (1=yes, 0=no)
    
    For notarization:
    APPLE_ID                   Apple ID email
    APPLE_TEAM_ID              Developer Team ID
    APPLE_PASSWORD             App-specific password

EXAMPLES:
    # Create DMG from existing build
    $(basename "$0")

    # Build and package in one step
    ${SCRIPT_DIR}/build.sh && $(basename "$0")

    # Create DMG with custom name
    $(basename "$0") -n "MyCustomName"

    # Notarize the DMG
    APPLE_ID="you@example.com" \\
    APPLE_TEAM_ID="ABCDE12345" \\
    APPLE_PASSWORD="xxxx-xxxx-xxxx-xxxx" \\
    $(basename "$0") --notarize

EOF
}

################################################################################
# Main
################################################################################

main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -c|--configuration)
                CONFIGURATION="$2"
                shift 2
                ;;
            -o|--output)
                OUTPUT_DIR="$2"
                shift 2
                ;;
            -n|--name)
                DMG_NAME="$2"
                shift 2
                ;;
            -s|--skip-build)
                SKIP_BUILD=1
                shift
                ;;
            --notarize)
                NOTARIZE=1
                shift
                ;;
            -h|--help)
                print_usage
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                print_usage
                exit 1
                ;;
        esac
    done
    
    # Check prerequisites
    check_command hdiutil
    check_command SetFile || warn "SetFile not found. Install Xcode Command Line Tools for full functionality."
    
    print_header "Notepad++ macOS Packaging"
    log "Configuration: ${CONFIGURATION}"
    log "Output directory: ${OUTPUT_DIR}"
    
    # Build if needed
    if [[ "${SKIP_BUILD}" == "0" ]]; then
        log "Building application first..."
        "${SCRIPT_DIR}/build.sh" -c "${CONFIGURATION}"
    fi
    
    # Create output directory
    mkdir -p "${OUTPUT_DIR}"
    
    # Verify application bundle
    verify_app_bundle
    
    # Create DMG
    staging_dir=$(create_dmg_staging)
    dmg_file=$(create_dmg "${staging_dir}")
    
    # Clean up staging directory
    log "Cleaning up staging area..."
    rm -rf "${staging_dir}"
    
    # Notarize if requested
    if [[ "${NOTARIZE}" == "1" ]]; then
        notarize_dmg "${dmg_file}"
    fi
    
    # Verify DMG
    verify_dmg "${dmg_file}"
    
    print_header "Packaging Completed Successfully"
    success "DMG file created: ${dmg_file}"
    
    echo ""
    echo "Next steps:"
    echo "  1. Test the DMG: open \"${dmg_file}\""
    echo "  2. Test installation: drag app to Applications and launch"
    
    if [[ "${NOTARIZE}" == "0" ]]; then
        echo "  3. For distribution, consider notarizing the DMG:"
        echo "     ${SCRIPT_DIR}/package.sh --notarize"
    fi
    
    echo ""
    echo "Distribution checklist:"
    echo "  [ ] DMG opens correctly"
    echo "  [ ] App installs to Applications"
    echo "  [ ] App launches without errors"
    echo "  [ ] App is properly signed (if applicable)"
    echo "  [ ] App is notarized (for public distribution)"
}

# Run main function
main "$@"
