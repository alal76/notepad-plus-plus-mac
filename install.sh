#!/bin/bash
################################################################################
# Notepad++ macOS Installation Script
# Automates the installation process for Notepad++ on macOS
################################################################################

set -e  # Exit on error

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}"
BUILD_SCRIPT="${ROOT_DIR}/PowerEditor/cocoa/scripts/build.sh"
PACKAGE_SCRIPT="${ROOT_DIR}/PowerEditor/cocoa/scripts/package.sh"
PRODUCT_NAME="Notepad++"
INSTALL_DIR="/Applications"
APP_BUNDLE="${INSTALL_DIR}/${PRODUCT_NAME}.app"

# Installation options
SKIP_DEPENDENCIES=0
SKIP_BUILD=0
CREATE_DMG=0
VERBOSE=0

################################################################################
# Helper Functions
################################################################################

print_banner() {
    echo -e "${CYAN}"
    cat << 'EOF'
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║           Notepad++ for macOS - Installation Script          ║
║                                                               ║
║  Original Notepad++ by Don HO                                ║
║  macOS Port: https://github.com/alal76/notepad-plus-plus-mac ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

log() {
    echo -e "${BLUE}[INSTALL]${NC} $1"
}

success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

error() {
    echo -e "${RED}[✗]${NC} $1" >&2
}

warn() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_header() {
    echo ""
    echo -e "${CYAN}======================================================================"
    echo "$1"
    echo -e "======================================================================${NC}"
}

prompt_yes_no() {
    local prompt="$1"
    local default="${2:-n}"
    
    if [[ "$default" == "y" ]]; then
        prompt="$prompt [Y/n]: "
    else
        prompt="$prompt [y/N]: "
    fi
    
    while true; do
        read -p "$prompt" yn
        yn=${yn:-$default}
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

################################################################################
# System Check Functions
################################################################################

check_macos_version() {
    print_header "Checking System Requirements"
    
    local os_version=$(sw_vers -productVersion)
    local major_version=$(echo "$os_version" | cut -d '.' -f 1)
    
    log "macOS version: $os_version"
    
    if [[ "$major_version" -lt 11 ]]; then
        error "macOS 11.0 (Big Sur) or later is required"
        error "Your version: $os_version"
        exit 1
    fi
    
    success "macOS version is compatible"
}

check_architecture() {
    local arch=$(uname -m)
    log "Architecture: $arch"
    
    if [[ "$arch" != "x86_64" && "$arch" != "arm64" ]]; then
        error "Unsupported architecture: $arch"
        exit 1
    fi
    
    success "Architecture is supported"
}

check_disk_space() {
    # Get available space in gigabytes
    local available_gb=$(df -g . 2>/dev/null | awk 'NR==2 {print $4}')
    
    # If df -g is not supported, fall back to df -h and parse
    if [[ -z "$available_gb" ]]; then
        available_gb=$(df -h . | awk 'NR==2 {print $4}')
        log "Available disk space: $available_gb"
        # Simple heuristic check
        local numeric=$(echo "$available_gb" | grep -o '^[0-9.]*')
        if [[ "$available_gb" =~ [Gg]i?$ ]] && (( $(echo "$numeric >= 1" | bc -l 2>/dev/null || echo 0) )); then
            success "Sufficient disk space available"
            return
        fi
    else
        log "Available disk space: ${available_gb}G"
        if [[ "$available_gb" -ge 1 ]]; then
            success "Sufficient disk space available"
            return
        fi
    fi
    
    warn "Low disk space. At least 1 GB recommended for installation."
}

check_xcode_tools() {
    print_header "Checking Development Tools"
    
    if ! command -v xcodebuild &> /dev/null; then
        warn "Xcode Command Line Tools not found"
        
        if prompt_yes_no "Install Xcode Command Line Tools now?" "y"; then
            log "Installing Xcode Command Line Tools..."
            xcode-select --install
            
            echo ""
            warn "Please complete the installation in the popup window"
            warn "Press Enter after installation is complete..."
            read -r
            
            # Verify installation
            if command -v xcodebuild &> /dev/null; then
                success "Xcode Command Line Tools installed"
            else
                error "Installation failed or incomplete"
                exit 1
            fi
        else
            error "Xcode Command Line Tools are required for building"
            exit 1
        fi
    else
        local xcode_version=$(xcodebuild -version | head -n 1)
        success "Found: $xcode_version"
    fi
}

check_git() {
    if ! command -v git &> /dev/null; then
        error "Git is not installed. Please install Xcode Command Line Tools."
        exit 1
    fi
    success "Git is available"
}

################################################################################
# Build Functions
################################################################################

build_application() {
    print_header "Building Notepad++ for macOS"
    
    if [[ ! -x "$BUILD_SCRIPT" ]]; then
        error "Build script not found at: $BUILD_SCRIPT"
        exit 1
    fi
    
    log "Starting build process..."
    log "This may take several minutes..."
    echo ""
    
    local build_flags=""
    if [[ "$VERBOSE" == "1" ]]; then
        build_flags="-v"
    fi
    
    # Run the build script
    cd "$(dirname "$BUILD_SCRIPT")"
    
    if [[ "$VERBOSE" == "1" ]]; then
        bash "$BUILD_SCRIPT" $build_flags
        local build_status=$?
    else
        bash "$BUILD_SCRIPT" $build_flags 2>&1 | grep -E "(\[BUILD\]|\[SUCCESS\]|\[ERROR\])" || true
        local build_status=${PIPESTATUS[0]}
    fi
    
    if [[ $build_status -eq 0 ]]; then
        success "Build completed successfully"
    else
        error "Build failed with exit code $build_status"
        echo ""
        error "Try running with --verbose flag for more details:"
        error "  $0 --verbose"
        exit 1
    fi
    
    cd "$ROOT_DIR"
}

################################################################################
# Installation Functions
################################################################################

install_application() {
    print_header "Installing Notepad++"
    
    local built_app="${ROOT_DIR}/PowerEditor/cocoa/build/Release/${PRODUCT_NAME}.app"
    
    if [[ ! -d "$built_app" ]]; then
        error "Built application not found at: $built_app"
        error "Please run the build first"
        exit 1
    fi
    
    # Check if already installed
    if [[ -d "$APP_BUNDLE" ]]; then
        warn "Notepad++ is already installed at ${APP_BUNDLE}"
        
        if prompt_yes_no "Replace existing installation?" "y"; then
            log "Removing existing installation..."
            rm -rf "$APP_BUNDLE"
        else
            log "Installation cancelled"
            exit 0
        fi
    fi
    
    # Copy to Applications
    log "Copying to ${INSTALL_DIR}..."
    
    # Check if we need sudo
    if [[ ! -w "$INSTALL_DIR" ]]; then
        warn "Administrator privileges required to install to ${INSTALL_DIR}"
        sudo cp -R "$built_app" "$APP_BUNDLE"
    else
        cp -R "$built_app" "$APP_BUNDLE"
    fi
    
    # Verify installation
    if [[ -d "$APP_BUNDLE" ]]; then
        success "Installed to ${APP_BUNDLE}"
        
        # Get version
        local version=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" \
                       "${APP_BUNDLE}/Contents/Info.plist" 2>/dev/null || echo "unknown")
        log "Version: $version"
    else
        error "Installation failed"
        exit 1
    fi
}

setup_file_associations() {
    print_header "Setting Up File Associations"
    
    if [[ ! -d "$APP_BUNDLE" ]]; then
        warn "Application not found. Skipping file associations."
        return
    fi
    
    log "Registering file associations with Launch Services..."
    
    # Reset Launch Services database for the app
    /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
        -f "$APP_BUNDLE" 2>/dev/null || true
    
    success "File associations registered"
    echo ""
    log "To set Notepad++ as default editor for a file type:"
    log "  1. Right-click a file in Finder"
    log "  2. Select 'Get Info' (⌘I)"
    log "  3. Under 'Open with:', select Notepad++"
    log "  4. Click 'Change All...' to apply to all files of this type"
}

create_command_line_alias() {
    print_header "Command Line Setup (Optional)"
    
    if prompt_yes_no "Add command line alias 'npp'?" "n"; then
        local shell_config=""
        
        # Detect shell
        if [[ "$SHELL" == *"zsh"* ]]; then
            shell_config="$HOME/.zshrc"
        elif [[ "$SHELL" == *"bash"* ]]; then
            shell_config="$HOME/.bash_profile"
        else
            warn "Unsupported shell: $SHELL"
            return
        fi
        
        # Check if alias already exists
        if grep -q "^[[:space:]]*alias npp=" "$shell_config" 2>/dev/null; then
            log "Alias 'npp' already exists in $shell_config"
        else
            log "Adding alias to $shell_config..."
            echo "" >> "$shell_config"
            echo "# Notepad++ macOS" >> "$shell_config"
            echo "alias npp='open -a \"Notepad++\"'" >> "$shell_config"
            
            success "Alias added to $shell_config"
            log "Restart your terminal or run: source $shell_config"
            log "Usage: npp myfile.txt"
        fi
    fi
}

create_dmg_package() {
    if [[ "$CREATE_DMG" != "1" ]]; then
        return
    fi
    
    print_header "Creating DMG Package"
    
    if [[ ! -x "$PACKAGE_SCRIPT" ]]; then
        warn "Package script not found. Skipping DMG creation."
        return
    fi
    
    log "Creating distributable DMG..."
    bash "$PACKAGE_SCRIPT" -s
    
    if [[ $? -eq 0 ]]; then
        success "DMG created successfully"
    else
        warn "DMG creation failed (non-critical)"
    fi
}

################################################################################
# Main Installation Flow
################################################################################

print_usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Install Notepad++ on macOS

OPTIONS:
    --skip-dependencies    Skip checking/installing dependencies
    --skip-build          Skip building (install existing build)
    --create-dmg          Create a DMG package after installation
    --verbose             Show detailed build output
    -h, --help            Show this help message

EXAMPLES:
    # Standard installation
    $(basename "$0")

    # Quick reinstall (skip dependencies and use existing build)
    $(basename "$0") --skip-dependencies --skip-build

    # Build with verbose output
    $(basename "$0") --verbose

    # Create distributable DMG
    $(basename "$0") --create-dmg

EOF
}

main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-dependencies)
                SKIP_DEPENDENCIES=1
                shift
                ;;
            --skip-build)
                SKIP_BUILD=1
                shift
                ;;
            --create-dmg)
                CREATE_DMG=1
                shift
                ;;
            --verbose)
                VERBOSE=1
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
    
    # Show banner
    print_banner
    
    # System checks
    if [[ "$SKIP_DEPENDENCIES" != "1" ]]; then
        check_macos_version
        check_architecture
        check_disk_space
        check_xcode_tools
        check_git
    else
        log "Skipping dependency checks"
    fi
    
    # Build
    if [[ "$SKIP_BUILD" != "1" ]]; then
        build_application
    else
        log "Skipping build step"
    fi
    
    # Install
    install_application
    
    # Post-installation
    setup_file_associations
    create_command_line_alias
    create_dmg_package
    
    # Final message
    print_header "Installation Complete!"
    
    success "Notepad++ has been successfully installed on your Mac!"
    echo ""
    log "Application location: ${APP_BUNDLE}"
    log "Version: $(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" \
                "${APP_BUNDLE}/Contents/Info.plist" 2>/dev/null || echo "unknown")"
    echo ""
    echo -e "${GREEN}Next steps:${NC}"
    echo "  1. Launch Notepad++ from Applications folder"
    echo "  2. Or run: open -a 'Notepad++'"
    echo "  3. See INSTALL_MACOS.md for more information"
    echo ""
    echo -e "${CYAN}Thank you for using Notepad++ on macOS!${NC}"
    echo ""
    echo "Original Notepad++ by Don HO: https://notepad-plus-plus.org/"
    echo "macOS Port: https://github.com/alal76/notepad-plus-plus-mac"
    echo ""
}

# Run main function
main "$@"
