################################################################################
# Notepad++ macOS Makefile
# Build automation for Notepad++ macOS port
################################################################################

# Configuration
PRODUCT_NAME := Notepad++
CONFIGURATION ?= Release
ARCH ?= $(shell uname -m)
MACOSX_DEPLOYMENT_TARGET ?= 11.0

# Directories
ROOT_DIR := $(shell cd ../../.. && pwd)
COCOA_DIR := $(ROOT_DIR)/PowerEditor/cocoa
SCINTILLA_DIR := $(ROOT_DIR)/scintilla
LEXILLA_DIR := $(ROOT_DIR)/lexilla
BUILD_DIR := $(COCOA_DIR)/build
SCRIPTS_DIR := $(COCOA_DIR)/scripts

# Build outputs
APP_BUNDLE := $(BUILD_DIR)/$(CONFIGURATION)/$(PRODUCT_NAME).app
SCINTILLA_FRAMEWORK := $(BUILD_DIR)/$(CONFIGURATION)/Scintilla.framework
LEXILLA_FRAMEWORK := $(BUILD_DIR)/$(CONFIGURATION)/Lexilla.framework
DMG_FILE := $(BUILD_DIR)/$(PRODUCT_NAME)-$(shell date +%Y%m%d)-macOS.dmg

# Code signing (optional)
CODE_SIGN_IDENTITY ?=
TEAM_ID ?=

# Build scripts
BUILD_SCRIPT := $(SCRIPTS_DIR)/build.sh
PACKAGE_SCRIPT := $(SCRIPTS_DIR)/package.sh

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
NC := \033[0m

################################################################################
# Phony targets
################################################################################

.PHONY: all clean frameworks scintilla lexilla app dmg install uninstall \
        test debug release help xcode-schemes rebuild distclean

################################################################################
# Default target
################################################################################

all: app
	@echo "$(GREEN)✓ Build complete$(NC)"

################################################################################
# Build targets
################################################################################

# Build Scintilla framework
scintilla: $(SCINTILLA_FRAMEWORK)

$(SCINTILLA_FRAMEWORK):
	@echo "$(BLUE)Building Scintilla.framework...$(NC)"
	@$(BUILD_SCRIPT) scintilla
	@echo "$(GREEN)✓ Scintilla.framework built$(NC)"

# Build Lexilla framework
lexilla: $(LEXILLA_FRAMEWORK)

$(LEXILLA_FRAMEWORK):
	@echo "$(BLUE)Building Lexilla.framework...$(NC)"
	@$(BUILD_SCRIPT) lexilla
	@echo "$(GREEN)✓ Lexilla.framework built$(NC)"

# Build both frameworks
frameworks: scintilla lexilla
	@echo "$(GREEN)✓ All frameworks built$(NC)"

# Build the application
app: frameworks $(APP_BUNDLE)

$(APP_BUNDLE): $(SCINTILLA_FRAMEWORK) $(LEXILLA_FRAMEWORK)
	@echo "$(BLUE)Building $(PRODUCT_NAME).app...$(NC)"
	@$(BUILD_SCRIPT) app
	@echo "$(GREEN)✓ $(PRODUCT_NAME).app built$(NC)"

# Build everything and create DMG
dmg: app
	@echo "$(BLUE)Creating DMG...$(NC)"
	@SKIP_BUILD=1 $(PACKAGE_SCRIPT)
	@echo "$(GREEN)✓ DMG created$(NC)"

################################################################################
# Configuration-specific targets
################################################################################

debug:
	@$(MAKE) all CONFIGURATION=Debug

release:
	@$(MAKE) all CONFIGURATION=Release

################################################################################
# Architecture-specific targets
################################################################################

arm64:
	@$(MAKE) all ARCH=arm64

x86_64:
	@$(MAKE) all ARCH=x86_64

universal:
	@echo "$(BLUE)Building universal binary...$(NC)"
	@$(MAKE) all ARCH=arm64
	@$(MAKE) all ARCH=x86_64
	@echo "$(YELLOW)TODO: Combine into universal binary with lipo$(NC)"

################################################################################
# Clean targets
################################################################################

clean:
	@echo "$(BLUE)Cleaning build artifacts...$(NC)"
	@rm -rf $(BUILD_DIR)
	@echo "$(GREEN)✓ Clean complete$(NC)"

distclean: clean
	@echo "$(BLUE)Deep cleaning...$(NC)"
	@cd $(SCINTILLA_DIR)/cocoa && xcodebuild clean -project Scintilla/Scintilla.xcodeproj -scheme Scintilla 2>/dev/null || true
	@cd $(LEXILLA_DIR)/src/Lexilla && xcodebuild clean -project Lexilla.xcodeproj -scheme Lexilla 2>/dev/null || true
	@echo "$(GREEN)✓ Deep clean complete$(NC)"

################################################################################
# Installation targets
################################################################################

install: app
	@echo "$(BLUE)Installing to /Applications...$(NC)"
	@if [ -d "/Applications/$(PRODUCT_NAME).app" ]; then \
		echo "$(YELLOW)Warning: Existing installation found. Removing...$(NC)"; \
		rm -rf "/Applications/$(PRODUCT_NAME).app"; \
	fi
	@cp -R $(APP_BUNDLE) /Applications/
	@echo "$(GREEN)✓ Installed to /Applications/$(PRODUCT_NAME).app$(NC)"

uninstall:
	@echo "$(BLUE)Uninstalling from /Applications...$(NC)"
	@if [ -d "/Applications/$(PRODUCT_NAME).app" ]; then \
		rm -rf "/Applications/$(PRODUCT_NAME).app"; \
		echo "$(GREEN)✓ Uninstalled$(NC)"; \
	else \
		echo "$(YELLOW)Not installed$(NC)"; \
	fi

################################################################################
# Development targets
################################################################################

# Rebuild everything from scratch
rebuild: clean all

# Run the application
run: app
	@echo "$(BLUE)Launching $(PRODUCT_NAME)...$(NC)"
	@open $(APP_BUNDLE)

# Open in Xcode (auto-detect project)
xcode:
	@echo "$(BLUE)Opening in Xcode...$(NC)"
	@PROJECT=$$(find $(COCOA_DIR) -maxdepth 1 -name "*.xcodeproj" | head -n 1); \
	if [ -z "$$PROJECT" ]; then \
		echo "$(YELLOW)No Xcode project found in $(COCOA_DIR)$(NC)"; \
		exit 1; \
	fi; \
	open "$$PROJECT"

# List available Xcode schemes
xcode-schemes:
	@echo "$(BLUE)Available Xcode schemes:$(NC)"
	@echo ""
	@echo "Scintilla:"
	@xcodebuild -project $(SCINTILLA_DIR)/cocoa/Scintilla/Scintilla.xcodeproj -list 2>/dev/null | grep -A 100 "Schemes:" | tail -n +2 || true
	@echo ""
	@echo "Lexilla:"
	@xcodebuild -project $(LEXILLA_DIR)/src/Lexilla/Lexilla.xcodeproj -list 2>/dev/null | grep -A 100 "Schemes:" | tail -n +2 || true
	@echo ""
	@PROJECT=$$(find $(COCOA_DIR) -maxdepth 1 -name "*.xcodeproj" | head -n 1); \
	if [ -n "$$PROJECT" ]; then \
		echo "Notepad++:"; \
		xcodebuild -project "$$PROJECT" -list 2>/dev/null | grep -A 100 "Schemes:" | tail -n +2 || true; \
	fi

################################################################################
# Testing targets
################################################################################

test: app
	@echo "$(BLUE)Running tests...$(NC)"
	@echo "$(YELLOW)TODO: Implement automated tests$(NC)"

# Test the frameworks in isolation
test-frameworks: frameworks
	@echo "$(BLUE)Testing frameworks...$(NC)"
	@if [ -d "$(SCINTILLA_FRAMEWORK)" ]; then \
		echo "$(GREEN)✓ Scintilla.framework exists$(NC)"; \
	else \
		echo "$(YELLOW)✗ Scintilla.framework not found$(NC)"; \
	fi
	@if [ -d "$(LEXILLA_FRAMEWORK)" ]; then \
		echo "$(GREEN)✓ Lexilla.framework exists$(NC)"; \
	else \
		echo "$(YELLOW)✗ Lexilla.framework not found$(NC)"; \
	fi

################################################################################
# Info targets
################################################################################

# Show build information
info:
	@echo "$(BLUE)Notepad++ macOS Build Information$(NC)"
	@echo ""
	@echo "Configuration:        $(CONFIGURATION)"
	@echo "Architecture:         $(ARCH)"
	@echo "Deployment Target:    $(MACOSX_DEPLOYMENT_TARGET)"
	@echo "Product Name:         $(PRODUCT_NAME)"
	@echo ""
	@echo "Directories:"
	@echo "  Root:               $(ROOT_DIR)"
	@echo "  Cocoa:              $(COCOA_DIR)"
	@echo "  Scintilla:          $(SCINTILLA_DIR)"
	@echo "  Lexilla:            $(LEXILLA_DIR)"
	@echo "  Build:              $(BUILD_DIR)"
	@echo ""
	@echo "Build Outputs:"
	@echo "  App Bundle:         $(APP_BUNDLE)"
	@echo "  Scintilla:          $(SCINTILLA_FRAMEWORK)"
	@echo "  Lexilla:            $(LEXILLA_FRAMEWORK)"
	@echo ""
	@if [ -n "$(CODE_SIGN_IDENTITY)" ]; then \
		echo "Code Signing:         $(CODE_SIGN_IDENTITY)"; \
	else \
		echo "Code Signing:         $(YELLOW)Not configured$(NC)"; \
	fi
	@echo ""
	@echo "System Information:"
	@echo "  macOS Version:      $$(sw_vers -productVersion)"
	@echo "  Xcode Version:      $$(xcodebuild -version | head -n 1 || echo 'Not found')"
	@echo ""

# Show what would be built
status:
	@echo "$(BLUE)Build Status$(NC)"
	@echo ""
	@if [ -d "$(SCINTILLA_FRAMEWORK)" ]; then \
		echo "$(GREEN)✓$(NC) Scintilla.framework"; \
	else \
		echo "$(YELLOW)✗$(NC) Scintilla.framework (needs build)"; \
	fi
	@if [ -d "$(LEXILLA_FRAMEWORK)" ]; then \
		echo "$(GREEN)✓$(NC) Lexilla.framework"; \
	else \
		echo "$(YELLOW)✗$(NC) Lexilla.framework (needs build)"; \
	fi
	@if [ -d "$(APP_BUNDLE)" ]; then \
		echo "$(GREEN)✓$(NC) $(PRODUCT_NAME).app"; \
		VERSION=$$(defaults read "$(APP_BUNDLE)/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo "unknown"); \
		echo "  Version: $$VERSION"; \
		SIZE=$$(du -sh "$(APP_BUNDLE)" | cut -f1); \
		echo "  Size: $$SIZE"; \
	else \
		echo "$(YELLOW)✗$(NC) $(PRODUCT_NAME).app (needs build)"; \
	fi
	@echo ""

################################################################################
# Help target
################################################################################

help:
	@echo "$(BLUE)Notepad++ macOS Build System$(NC)"
	@echo ""
	@echo "$(GREEN)Common Targets:$(NC)"
	@echo "  make              - Build the application (default)"
	@echo "  make all          - Build everything"
	@echo "  make clean        - Remove build artifacts"
	@echo "  make rebuild      - Clean and build"
	@echo "  make install      - Install to /Applications"
	@echo "  make run          - Build and run the application"
	@echo ""
	@echo "$(GREEN)Component Targets:$(NC)"
	@echo "  make frameworks   - Build Scintilla and Lexilla frameworks"
	@echo "  make scintilla    - Build Scintilla.framework only"
	@echo "  make lexilla      - Build Lexilla.framework only"
	@echo "  make app          - Build Notepad++.app only"
	@echo "  make dmg          - Create distributable DMG"
	@echo ""
	@echo "$(GREEN)Configuration Targets:$(NC)"
	@echo "  make debug        - Build Debug configuration"
	@echo "  make release      - Build Release configuration"
	@echo ""
	@echo "$(GREEN)Architecture Targets:$(NC)"
	@echo "  make arm64        - Build for Apple Silicon"
	@echo "  make x86_64       - Build for Intel"
	@echo "  make universal    - Build universal binary (both architectures)"
	@echo ""
	@echo "$(GREEN)Development Targets:$(NC)"
	@echo "  make xcode        - Open project in Xcode"
	@echo "  make xcode-schemes - List available Xcode schemes"
	@echo "  make test         - Run tests"
	@echo ""
	@echo "$(GREEN)Info Targets:$(NC)"
	@echo "  make info         - Show build configuration"
	@echo "  make status       - Show build status"
	@echo "  make help         - Show this help message"
	@echo ""
	@echo "$(GREEN)Variables:$(NC)"
	@echo "  CONFIGURATION     - Debug or Release (default: Release)"
	@echo "  ARCH              - arm64 or x86_64 (default: current)"
	@echo "  CODE_SIGN_IDENTITY - Code signing identity (optional)"
	@echo "  TEAM_ID           - Development team ID (optional)"
	@echo ""
	@echo "$(GREEN)Examples:$(NC)"
	@echo "  make CONFIGURATION=Debug"
	@echo "  make ARCH=x86_64"
	@echo "  make CODE_SIGN_IDENTITY='Developer ID Application: Your Name'"
	@echo ""
