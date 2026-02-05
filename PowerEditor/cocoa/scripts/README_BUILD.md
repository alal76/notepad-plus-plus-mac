# Notepad++ macOS - Build Documentation

Complete guide for building and packaging Notepad++ for macOS.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Build System Overview](#build-system-overview)
- [Building from Source](#building-from-source)
- [Creating Distributable DMG](#creating-distributable-dmg)
- [Build Configuration](#build-configuration)
- [Code Signing](#code-signing)
- [Troubleshooting](#troubleshooting)
- [Advanced Topics](#advanced-topics)

## Prerequisites

### Required Software

| Software | Minimum Version | Recommended | Installation |
|----------|----------------|-------------|--------------|
| macOS | 11.0 (Big Sur) | 13.0+ (Ventura) | N/A |
| Xcode | 13.0 | 14.3+ | Mac App Store |
| Command Line Tools | Latest | Latest | `xcode-select --install` |

### Verify Installation

```bash
# Check macOS version
sw_vers

# Check Xcode version
xcodebuild -version

# Check Command Line Tools
xcode-select -p
```

Expected output:
```
ProductName:    macOS
ProductVersion: 13.0

Xcode 14.3
Build version 14E222b

/Applications/Xcode.app/Contents/Developer
```

### Optional Software

- **Apple Developer Account**: Required for code signing and notarization
- **Developer ID Certificate**: Required for distribution outside the Mac App Store
- **Git**: For version control (usually pre-installed)

## Quick Start

### 1. Clone Repository

```bash
git clone https://github.com/alal76/notepad-plus-plus-mac.git
cd notepad-plus-plus-mac
```

### 2. Build Application

```bash
# Navigate to scripts directory
cd PowerEditor/cocoa/scripts

# Build everything (frameworks + app)
./build.sh

# Or use Make
make all
```

### 3. Run Application

```bash
# Open the built application
open ../build/Release/Notepad++.app

# Or use Make
make run
```

### 4. Create DMG (Optional)

```bash
# Create distributable DMG
./package.sh

# Or use Make
make dmg
```

## Build System Overview

The build system consists of three main components:

### 1. build.sh - Main Build Script

Handles building all components:
- Scintilla.framework (text editor engine)
- Lexilla.framework (syntax highlighting)
- Notepad++.app (main application)
- Framework integration
- Resource copying
- Code signing (optional)

### 2. package.sh - DMG Creation Script

Creates distributable DMG files:
- Staging app bundle
- DMG creation with custom appearance
- Applications folder symlink
- Optional notarization

### 3. Makefile - Build Automation

Provides convenient targets for common tasks:
- Component builds (frameworks, app)
- Configuration management (Debug/Release)
- Architecture selection (arm64/x86_64)
- Installation and testing

### Build Directory Structure

```
PowerEditor/cocoa/
├── build/
│   ├── Release/
│   │   ├── Notepad++.app          # Built application
│   │   ├── Scintilla.framework    # Editor framework
│   │   ├── Lexilla.framework      # Lexer framework
│   │   └── Notepad++-*.dmg        # Distributable DMG
│   ├── Debug/
│   │   └── ...                    # Debug builds
│   └── Intermediates/             # Build intermediates
├── scripts/
│   ├── build.sh                   # Build script
│   ├── package.sh                 # Packaging script
│   └── Makefile                   # Build automation
└── Resources/
    ├── Info.plist                 # App metadata
    └── ...                        # Icons, resources
```

## Building from Source

### Using build.sh

#### Build Everything (Recommended)

```bash
./build.sh
```

This builds:
1. Scintilla.framework
2. Lexilla.framework
3. Notepad++.app
4. Copies frameworks into app
5. Copies resources
6. Signs app (if configured)

#### Build Specific Components

```bash
# Build frameworks only
./build.sh frameworks

# Build Scintilla only
./build.sh scintilla

# Build Lexilla only
./build.sh lexilla

# Build app only (assumes frameworks exist)
./build.sh app

# Clean all build artifacts
./build.sh clean
```

#### Build Options

```bash
# Debug build
./build.sh -c Debug

# Specific architecture
./build.sh -a arm64      # Apple Silicon
./build.sh -a x86_64     # Intel

# Custom deployment target
./build.sh -t 12.0

# With code signing
./build.sh -s "Developer ID Application: Your Name (TEAM_ID)"

# Verbose output
./build.sh -v

# Combine options
./build.sh -c Debug -a arm64 -v
```

### Using Makefile

#### Common Commands

```bash
# Build everything (default)
make

# Build specific components
make frameworks     # Build both frameworks
make scintilla      # Build Scintilla only
make lexilla        # Build Lexilla only
make app            # Build application

# Configuration-specific builds
make debug          # Build Debug configuration
make release        # Build Release configuration

# Architecture-specific builds
make arm64          # Build for Apple Silicon
make x86_64         # Build for Intel
make universal      # Build universal binary

# Clean up
make clean          # Remove build artifacts
make distclean      # Deep clean including Xcode builds

# Development
make run            # Build and run application
make xcode          # Open in Xcode
make install        # Install to /Applications

# Information
make info           # Show build configuration
make status         # Show build status
make help           # Show all available targets
```

#### Makefile Variables

```bash
# Set configuration
make CONFIGURATION=Debug

# Set architecture
make ARCH=x86_64

# Set deployment target
make MACOSX_DEPLOYMENT_TARGET=12.0

# With code signing
make CODE_SIGN_IDENTITY="Developer ID Application: Your Name"

# Combine multiple variables
make CONFIGURATION=Release ARCH=arm64
```

### Build Time

Approximate build times on Apple Silicon (M1):

| Target | Time | Notes |
|--------|------|-------|
| Scintilla | 10-15s | First build |
| Lexilla | 5-10s | First build |
| App | 15-30s | Depends on app size |
| **Total** | **30-60s** | Clean build |
| Incremental | 5-15s | Only changed files |

## Creating Distributable DMG

### Using package.sh

#### Basic DMG Creation

```bash
# Create DMG from existing build
./package.sh

# Build and package in one step
./build.sh && ./package.sh

# Skip rebuilding
./package.sh --skip-build
```

#### DMG Options

```bash
# Custom output directory
./package.sh -o ~/Desktop

# Custom DMG name
./package.sh -n "Notepad++-CustomBuild"

# Specific configuration
./package.sh -c Debug

# With notarization (requires Apple Developer account)
./package.sh --notarize
```

### DMG Customization

The DMG includes:
- **Notepad++.app**: The application bundle
- **Applications symlink**: For easy drag-and-drop installation
- **README.txt**: Installation instructions (if exists)
- **LICENSE.txt**: License information
- **Custom background**: Visual appearance (if configured)
- **Custom icon**: Volume icon (if configured)

### Using Makefile

```bash
# Create DMG
make dmg

# The DMG will be created in:
# PowerEditor/cocoa/build/Notepad++-YYYYMMDD-macOS.dmg
```

## Build Configuration

### Environment Variables

Set before running build scripts:

```bash
# Build configuration
export CONFIGURATION=Release        # Debug or Release
export ARCH=arm64                   # arm64 or x86_64
export MACOSX_DEPLOYMENT_TARGET=11.0  # Minimum macOS version

# Code signing
export CODE_SIGN_IDENTITY="Developer ID Application: Your Name (TEAM_ID)"
export TEAM_ID="ABCDE12345"

# Verbose output
export VERBOSE=1

# Run build
./build.sh
```

### Configuration Files

#### Info.plist

Location: `PowerEditor/cocoa/Resources/Info.plist`

Key settings:
- **CFBundleIdentifier**: `org.notepad-plus-plus`
- **CFBundleShortVersionString**: App version (e.g., `8.6.0`)
- **LSMinimumSystemVersion**: Minimum macOS version
- **CFBundleDocumentTypes**: Supported file types

#### Entitlements

Location: `PowerEditor/cocoa/Resources/Notepad++.entitlements`

Required for:
- Hardened Runtime
- App sandboxing (if needed)
- Notarization

### Debug vs Release Builds

| Aspect | Debug | Release |
|--------|-------|---------|
| Optimization | `-O0` | `-O3` |
| Symbols | Full | Stripped |
| Assertions | Enabled | Disabled |
| Size | Larger | Smaller |
| Performance | Slower | Faster |
| Use Case | Development | Distribution |

```bash
# Debug build
./build.sh -c Debug
make debug

# Release build
./build.sh -c Release
make release
```

## Code Signing

### Why Code Sign?

- **Required** for notarization
- **Required** for distribution outside the App Store
- Provides user trust and security
- Prevents modification tampering

### Getting a Certificate

1. **Enroll** in [Apple Developer Program](https://developer.apple.com/programs/) ($99/year)
2. **Generate** certificate in Xcode:
   - Xcode → Preferences → Accounts
   - Select your Apple ID
   - Manage Certificates → Create "Developer ID Application"
3. **Verify** certificate:
   ```bash
   security find-identity -v -p codesigning
   ```

### Signing the Application

#### Using build.sh

```bash
# Find your signing identity
security find-identity -v -p codesigning

# Expected output:
# 1) ABCDEF1234567890 "Developer ID Application: Your Name (TEAM_ID)"

# Build with signing
./build.sh -s "Developer ID Application: Your Name (TEAM_ID)"

# Or set environment variable
export CODE_SIGN_IDENTITY="Developer ID Application: Your Name (TEAM_ID)"
./build.sh
```

#### Using Makefile

```bash
make CODE_SIGN_IDENTITY="Developer ID Application: Your Name (TEAM_ID)"
```

#### Verify Signature

```bash
# Check if app is signed
codesign -v ../build/Release/Notepad++.app

# Detailed verification
codesign -dvv ../build/Release/Notepad++.app

# Check entitlements
codesign -d --entitlements - ../build/Release/Notepad++.app
```

### Notarization

Required for distribution on macOS 10.15+.

#### Prerequisites

- Signed application
- Apple Developer account
- App-specific password (create at appleid.apple.com)

#### Notarize DMG

```bash
# Set credentials
export APPLE_ID="you@example.com"
export APPLE_TEAM_ID="ABCDE12345"
export APPLE_PASSWORD="xxxx-xxxx-xxxx-xxxx"  # App-specific password

# Build, package, and notarize
./build.sh -s "Developer ID Application: Your Name (TEAM_ID)"
./package.sh --notarize
```

#### Check Notarization Status

```bash
# Check if DMG is notarized
spctl -a -t open --context context:primary-signature -v Notepad++.dmg

# Check if app is notarized
spctl -a -t exec -v ../build/Release/Notepad++.app
```

## Troubleshooting

### Build Failures

#### Framework Not Found

**Error:**
```
framework not found Scintilla
```

**Solution:**
```bash
# Build frameworks first
./build.sh frameworks

# Or check framework search paths in Xcode
```

#### Xcode Project Not Found

**Error:**
```
No Xcode project found in PowerEditor/cocoa
```

**Solution:**
```bash
# Create Xcode project first (see macOS_QUICKSTART.md)
# Or check that project exists:
ls -la PowerEditor/cocoa/*.xcodeproj
```

#### Code Signing Failures

**Error:**
```
code object is not signed at all
```

**Solution:**
```bash
# Check available identities
security find-identity -v -p codesigning

# Ensure certificate is valid
# Ensure CODE_SIGN_IDENTITY is set correctly
```

### Runtime Issues

#### App Won't Launch

**Symptoms:**
- App bounces in Dock and quits
- Crash on launch

**Debug:**
```bash
# Run from command line to see errors
../build/Release/Notepad++.app/Contents/MacOS/Notepad++

# Check crash logs
open ~/Library/Logs/DiagnosticReports/

# Check frameworks are present
ls -la ../build/Release/Notepad++.app/Contents/Frameworks/
```

#### Framework Loading Errors

**Error:**
```
Library not loaded: @rpath/Scintilla.framework/...
```

**Solution:**
```bash
# Check framework paths
otool -L ../build/Release/Notepad++.app/Contents/MacOS/Notepad++

# Rebuild with frameworks
./build.sh all
```

#### Permission Denied

**Error:**
```
Permission denied when opening files
```

**Solution:**
- Check app entitlements
- Ensure app is properly signed
- Check file permissions

### DMG Creation Issues

#### DMG Mount Fails

**Error:**
```
hdiutil: attach failed
```

**Solution:**
```bash
# Unmount any existing mounts
hdiutil detach /Volumes/Notepad++

# Clean and retry
rm -rf build/dmg-staging
./package.sh
```

#### SetFile Command Not Found

**Warning:**
```
SetFile not found
```

**Solution:**
```bash
# Install Xcode Command Line Tools
xcode-select --install

# Verify installation
which SetFile
```

### Clean Build

If all else fails, try a clean build:

```bash
# Clean everything
make distclean

# Or manually
rm -rf PowerEditor/cocoa/build

# Rebuild
./build.sh
```

## Advanced Topics

### Universal Binaries

Build for both Apple Silicon and Intel:

```bash
# Build for arm64
./build.sh -a arm64 -c Release

# Build for x86_64
./build.sh -a x86_64 -c Release

# Combine with lipo
lipo -create \
  build/Release-arm64/Notepad++.app/Contents/MacOS/Notepad++ \
  build/Release-x86_64/Notepad++.app/Contents/MacOS/Notepad++ \
  -output build/Release/Notepad++.app/Contents/MacOS/Notepad++

# Or use Makefile (TODO)
make universal
```

### Custom Build Locations

```bash
# Custom build directory
BUILD_DIR=/tmp/notepad-build ./build.sh

# Custom output for DMG
./package.sh -o ~/Desktop
```

### Continuous Integration

Example GitHub Actions workflow:

```yaml
name: Build macOS

on: [push, pull_request]

jobs:
  build:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Xcode
        uses: maxim-lobanov/setup-xcode@v1
        with:
          xcode-version: latest-stable
      
      - name: Build
        run: |
          cd PowerEditor/cocoa/scripts
          ./build.sh -c Release
      
      - name: Create DMG
        run: |
          cd PowerEditor/cocoa/scripts
          ./package.sh --skip-build
      
      - name: Upload Artifact
        uses: actions/upload-artifact@v3
        with:
          name: Notepad++-macOS
          path: PowerEditor/cocoa/build/*.dmg
```

### Custom Framework Locations

If frameworks are built elsewhere:

```bash
# Set custom paths in build.sh
SCINTILLA_FRAMEWORK=/path/to/Scintilla.framework
LEXILLA_FRAMEWORK=/path/to/Lexilla.framework
```

### Debugging Build Scripts

```bash
# Enable verbose output
./build.sh -v

# Enable bash debugging
bash -x build.sh

# Check build log
./build.sh 2>&1 | tee build.log
```

## Getting Help

### Documentation

- [macOS_QUICKSTART.md](../../../macOS_QUICKSTART.md) - Getting started guide
- [macOS_PORT_PLAN.md](../../../macOS_PORT_PLAN.md) - Architecture details
- [macOS_README.md](../../../macOS_README.md) - General information

### Resources

- [Xcode Documentation](https://developer.apple.com/documentation/xcode)
- [Scintilla Documentation](https://www.scintilla.org/ScintillaDoc.html)
- [Apple Code Signing Guide](https://developer.apple.com/support/code-signing/)
- [Notarization Guide](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)

### Community

- [Notepad++ Forum](https://community.notepad-plus-plus.org/)
- [GitHub Issues](https://github.com/alal76/notepad-plus-plus-mac/issues)
- [Scintilla Mailing List](https://groups.google.com/g/scintilla-interest)

### Reporting Issues

When reporting build issues, include:

1. **System Information:**
   ```bash
   sw_vers
   xcodebuild -version
   ```

2. **Build Command Used:**
   ```bash
   ./build.sh -c Release -v
   ```

3. **Full Error Output:**
   ```bash
   ./build.sh 2>&1 | tee build.log
   # Attach build.log
   ```

4. **Build Status:**
   ```bash
   make status
   ```

## Summary

### Quick Reference

| Task | Command |
|------|---------|
| Build everything | `./build.sh` or `make` |
| Build Debug | `./build.sh -c Debug` or `make debug` |
| Build for Intel | `./build.sh -a x86_64` |
| Create DMG | `./package.sh` or `make dmg` |
| Clean build | `./build.sh clean` or `make clean` |
| Install to /Applications | `make install` |
| Run app | `make run` |
| Open in Xcode | `make xcode` |
| Show help | `make help` |

### Build Checklist

- [ ] Prerequisites installed (Xcode, Command Line Tools)
- [ ] Repository cloned
- [ ] Build frameworks: `./build.sh frameworks`
- [ ] Build app: `./build.sh app`
- [ ] Test app: `make run`
- [ ] Create DMG: `./package.sh`
- [ ] Test DMG installation
- [ ] Code sign (for distribution)
- [ ] Notarize (for public release)

---

**Last Updated:** 2024
**Notepad++ macOS Port:** https://github.com/alal76/notepad-plus-plus-mac
