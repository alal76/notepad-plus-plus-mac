#!/bin/bash
################################################################################
# Notepad++ macOS Quick Install Script
# One-command installer that clones, builds, packages, and installs Notepad++
#
# Usage:
#   bash <(curl -fsSL https://raw.githubusercontent.com/alal76/notepad-plus-plus-mac/main/quick-install.sh)
#
# Or download and run:
#   curl -fsSL https://raw.githubusercontent.com/alal76/notepad-plus-plus-mac/main/quick-install.sh -o quick-install.sh
#   bash quick-install.sh
################################################################################

set -e  # Exit on error

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Configuration
REPO_URL="https://github.com/alal76/notepad-plus-plus-mac.git"
REPO_DIR="$HOME/.notepad-plus-plus-mac-build"
PRODUCT_NAME="Notepad++"
INSTALL_DIR="/Applications"
APP_BUNDLE="${INSTALL_DIR}/${PRODUCT_NAME}.app"

################################################################################
# Helper Functions
################################################################################

print_banner() {
    clear
    echo -e "${CYAN}${BOLD}"
    cat << 'EOF'
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║     Notepad++ for macOS - One-Command Quick Installer        ║
║                                                               ║
║  This script will:                                            ║
║  • Clone the repository                                       ║
║  • Build Scintilla and Lexilla frameworks                     ║
║  • Build and package the Notepad++ application                ║
║  • Install to /Applications                                   ║
║                                                               ║
║  Original Notepad++ by Don HO                                 ║
║  macOS Port: github.com/alal76/notepad-plus-plus-mac          ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

log() {
    echo -e "${BLUE}[QUICK-INSTALL]${NC} $1"
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
    echo -e "${CYAN}${BOLD}======================================================================"
    echo "$1"
    echo -e "======================================================================${NC}"
}

prompt_continue() {
    echo ""
    read -p "Press Enter to continue or Ctrl+C to cancel..."
    echo ""
}

################################################################################
# System Checks
################################################################################

check_macos() {
    print_header "Checking System Requirements"
    
    if [[ "$OSTYPE" != "darwin"* ]]; then
        error "This script is for macOS only."
        exit 1
    fi
    
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

check_xcode_tools() {
    log "Checking for Xcode Command Line Tools..."
    
    if ! command -v git &> /dev/null || ! command -v xcodebuild &> /dev/null; then
        warn "Xcode Command Line Tools not found"
        log "Installing Xcode Command Line Tools..."
        
        xcode-select --install 2>/dev/null || true
        
        echo ""
        warn "Please complete the installation in the popup window"
        warn "After installation completes, run this script again:"
        echo ""
        echo -e "  ${BOLD}bash <(curl -fsSL https://raw.githubusercontent.com/alal76/notepad-plus-plus-mac/main/quick-install.sh)${NC}"
        echo ""
        exit 0
    fi
    
    success "Xcode Command Line Tools found"
}

check_disk_space() {
    log "Checking disk space..."
    
    local available_gb=$(df -g "$HOME" 2>/dev/null | awk 'NR==2 {print $4}')
    
    if [[ -z "$available_gb" ]]; then
        available_gb=$(df -h "$HOME" | awk 'NR==2 {print $4}')
        log "Available disk space: $available_gb"
    else
        log "Available disk space: ${available_gb}G"
        if [[ "$available_gb" -lt 5 ]]; then
            warn "Low disk space. At least 5 GB recommended."
            warn "Current available: ${available_gb}G"
        else
            success "Sufficient disk space available"
        fi
    fi
}

################################################################################
# Installation Functions
################################################################################

clone_repository() {
    print_header "Cloning Repository"
    
    # Remove old build directory if it exists
    if [[ -d "$REPO_DIR" ]]; then
        warn "Removing existing build directory: $REPO_DIR"
        rm -rf "$REPO_DIR"
    fi
    
    log "Cloning from: $REPO_URL"
    log "Destination: $REPO_DIR"
    
    git clone --depth 1 "$REPO_URL" "$REPO_DIR" 2>&1 | while read line; do
        echo "  $line"
    done
    
    if [[ ! -d "$REPO_DIR" ]]; then
        error "Failed to clone repository"
        exit 1
    fi
    
    success "Repository cloned successfully"
}

build_and_package() {
    print_header "Building and Packaging Notepad++"
    
    cd "$REPO_DIR"
    
    log "Starting build process..."
    log "This may take 5-10 minutes depending on your Mac..."
    echo ""
    
    # Check if build script exists
    if [[ ! -x "$REPO_DIR/PowerEditor/cocoa/scripts/build.sh" ]]; then
        error "Build script not found"
        exit 1
    fi
    
    # Build the application
    log "Building application..."
    cd "$REPO_DIR/PowerEditor/cocoa/scripts"
    
    if ! bash build.sh 2>&1 | grep -E "(\[BUILD\]|\[SUCCESS\]|\[ERROR\])"; then
        error "Build failed"
        exit 1
    fi
    
    success "Application built successfully"
    
    # Package the application (create DMG)
    log "Creating DMG package..."
    
    if [[ -x "$REPO_DIR/PowerEditor/cocoa/scripts/package.sh" ]]; then
        if bash package.sh -s 2>&1 | grep -E "(\[PACKAGE\]|\[SUCCESS\]|\[ERROR\])"; then
            success "DMG package created successfully"
        else
            warn "DMG packaging failed (non-critical, continuing with installation)"
        fi
    else
        warn "Package script not found, skipping DMG creation"
    fi
}

install_application() {
    print_header "Installing Notepad++"
    
    local built_app="$REPO_DIR/PowerEditor/cocoa/build/Release/${PRODUCT_NAME}.app"
    
    if [[ ! -d "$built_app" ]]; then
        error "Built application not found at: $built_app"
        exit 1
    fi
    
    # Check if already installed
    if [[ -d "$APP_BUNDLE" ]]; then
        warn "Notepad++ is already installed at ${APP_BUNDLE}"
        read -p "Replace existing installation? [y/N]: " replace
        
        if [[ "$replace" =~ ^[Yy]$ ]]; then
            log "Removing existing installation..."
            rm -rf "$APP_BUNDLE"
        else
            log "Keeping existing installation, installation cancelled"
            cleanup
            exit 0
        fi
    fi
    
    # Copy to Applications
    log "Installing to ${INSTALL_DIR}..."
    
    if [[ ! -w "$INSTALL_DIR" ]]; then
        log "Administrator privileges required..."
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
    
    # Register file associations
    log "Registering file associations..."
    /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
        -f "$APP_BUNDLE" 2>/dev/null || true
    success "File associations registered"
}

cleanup() {
    print_header "Cleaning Up"
    
    if [[ -d "$REPO_DIR" ]]; then
        log "Removing temporary build directory..."
        rm -rf "$REPO_DIR"
        success "Cleanup complete"
    fi
}

show_completion_message() {
    print_header "Installation Complete! 🎉"
    
    echo -e "${GREEN}${BOLD}"
    echo "✓ Notepad++ has been successfully installed on your Mac!"
    echo -e "${NC}"
    echo ""
    echo "Application location: ${APP_BUNDLE}"
    echo ""
    echo -e "${CYAN}${BOLD}Next steps:${NC}"
    echo "  1. Launch Notepad++ from Applications folder"
    echo "  2. Or run: ${BOLD}open -a 'Notepad++'${NC}"
    echo "  3. Right-click files in Finder → 'Get Info' → 'Open with' to set as default editor"
    echo ""
    
    # Ask if user wants to open the app now
    read -p "Would you like to launch Notepad++ now? [Y/n]: " launch
    if [[ "$launch" != "n" && "$launch" != "N" ]]; then
        log "Launching Notepad++..."
        open -a "Notepad++" 2>/dev/null || open "$APP_BUNDLE"
    fi
    
    echo ""
    echo -e "${CYAN}Thank you for using Notepad++ on macOS!${NC}"
    echo ""
    echo "Original Notepad++ by Don HO: https://notepad-plus-plus.org/"
    echo "macOS Port: https://github.com/alal76/notepad-plus-plus-mac"
    echo ""
    
    # Show DMG location if it exists
    local dmg_file=$(find "$REPO_DIR/PowerEditor/cocoa/build" -name "*.dmg" -type f 2>/dev/null | head -n 1)
    if [[ -n "$dmg_file" && -f "$dmg_file" ]]; then
        echo -e "${YELLOW}Note:${NC} A distributable DMG file was created at:"
        echo "  $dmg_file"
        echo ""
    fi
}

show_error_help() {
    echo ""
    error "Installation failed!"
    echo ""
    echo "For help, please:"
    echo "  • Check the error messages above"
    echo "  • Visit: https://github.com/alal76/notepad-plus-plus-mac/issues"
    echo "  • See INSTALL_MACOS.md for manual installation instructions"
    echo ""
    echo "You can also try manual installation:"
    echo "  git clone https://github.com/alal76/notepad-plus-plus-mac.git"
    echo "  cd notepad-plus-plus-mac"
    echo "  ./install.sh"
    echo ""
}

################################################################################
# Main Installation Flow
################################################################################

main() {
    # Set error handler
    trap 'show_error_help; cleanup; exit 1' ERR
    
    # Show banner
    print_banner
    
    # Show what will happen
    echo "This installer will:"
    echo "  • Check system requirements"
    echo "  • Clone the repository to: $REPO_DIR"
    echo "  • Build the application (5-10 minutes)"
    echo "  • Create a DMG package"
    echo "  • Install to: $APP_BUNDLE"
    echo "  • Clean up temporary files"
    
    prompt_continue
    
    # Run installation steps
    check_macos
    check_xcode_tools
    check_disk_space
    clone_repository
    build_and_package
    install_application
    cleanup
    show_completion_message
}

# Run main function
main "$@"
