# Xcode Build Configuration Guide

This document explains the Xcode project configuration for Notepad++ on macOS.

## Project Structure

The project consists of three Xcode projects:

1. **Scintilla.framework** (`scintilla/cocoa/Scintilla/Scintilla.xcodeproj`)
   - The text editing component
   - Must be built first
   - Output: `scintilla/cocoa/build/Release/Scintilla.framework`

2. **Lexilla.framework** (`lexilla/src/Lexilla/Lexilla.xcodeproj`)
   - Lexical analysis and syntax highlighting
   - Must be built second
   - Output: `lexilla/src/Lexilla/build/Release/Lexilla.framework`

3. **Notepad++.app** (`PowerEditor/cocoa/NotepadPlusPlus.xcodeproj`)
   - The main application
   - Depends on both frameworks above
   - Output: `PowerEditor/cocoa/build/Release/Notepad++.app`

## Build Requirements

- **macOS**: 11.0 (Big Sur) or later
- **Xcode**: 13.0 or later (recommended: 15.0+)
- **Xcode Command Line Tools**: Required
- **Architecture**: Supports both Intel (x86_64) and Apple Silicon (arm64)

## Configuration Overview

### Framework Search Paths

The main application project is configured to automatically find frameworks based on the build configuration:

```
$(PROJECT_DIR)/../../scintilla/cocoa/build/$(CONFIGURATION)
$(PROJECT_DIR)/../../lexilla/src/Lexilla/build/$(CONFIGURATION)
```

This means:
- Debug builds look in `.../build/Debug/`
- Release builds look in `.../build/Release/`

### Header Search Paths

The project includes comprehensive header search paths for all dependencies:

```
$(PROJECT_DIR)/../../scintilla/include
$(PROJECT_DIR)/../../scintilla/src
$(PROJECT_DIR)/../../lexilla/include
$(PROJECT_DIR)/../../lexilla/src
$(PROJECT_DIR)/AppKit
$(PROJECT_DIR)/Platform
$(PROJECT_DIR)/Controls
```

### Build Settings

- **Deployment Target**: macOS 10.15
- **C++ Standard**: GNU++20
- **C Standard**: GNU17
- **ARC**: Enabled (Automatic Reference Counting)
- **Code Signing**: Disabled for development (set to "-")

## Building from Xcode

### Option 1: Using Xcode GUI

1. **Open the main project:**
   ```bash
   open PowerEditor/cocoa/NotepadPlusPlus.xcodeproj
   ```

2. **First, build the dependencies:**
   - File → Open → `scintilla/cocoa/Scintilla/Scintilla.xcodeproj`
   - Select the "Scintilla" scheme
   - Product → Build (⌘B)
   - Close this project

3. **Then build Lexilla:**
   - File → Open → `lexilla/src/Lexilla/Lexilla.xcodeproj`
   - Select the "Lexilla" scheme  
   - Product → Build (⌘B)
   - Close this project

4. **Finally, build Notepad++:**
   - Return to the NotepadPlusPlus.xcodeproj window
   - Select the "Notepad++" scheme
   - Product → Build (⌘B)

5. **Run the app:**
   - Product → Run (⌘R)

### Option 2: Using xcodebuild Command Line

This is the recommended approach for automation and CI/CD:

```bash
# Build Scintilla framework
cd scintilla/cocoa
xcodebuild -project Scintilla/Scintilla.xcodeproj \
           -scheme Scintilla \
           -configuration Release \
           -arch $(uname -m) \
           build

# Build Lexilla framework  
cd ../../lexilla/src/Lexilla
xcodebuild -project Lexilla.xcodeproj \
           -scheme Lexilla \
           -configuration Release \
           -arch $(uname -m) \
           build

# Build Notepad++ application
cd ../../../PowerEditor/cocoa
xcodebuild -project NotepadPlusPlus.xcodeproj \
           -scheme Notepad++ \
           -configuration Release \
           -arch $(uname -m) \
           build
```

### Option 3: Using the Build Script

The easiest way is to use the provided build script:

```bash
cd PowerEditor/cocoa/scripts
./build.sh
```

This script automatically handles all three projects in the correct order.

## Build Configurations

### Debug vs Release

- **Debug**: 
  - Includes debug symbols
  - No optimization
  - Enables testability
  - Larger binaries

- **Release**:
  - Optimized for performance
  - Stripped debug symbols
  - Smaller binaries
  - Ready for distribution

To build Debug configuration:
```bash
xcodebuild -configuration Debug ...
```

### Architecture-Specific Builds

Build for specific architecture:

```bash
# Intel Macs
xcodebuild -arch x86_64 ...

# Apple Silicon Macs
xcodebuild -arch arm64 ...

# Universal Binary (both architectures)
xcodebuild -arch "x86_64 arm64" ...
```

## Project Files Added/Updated

### Shared Schemes

The following shared schemes have been added so the projects can be built from the command line or by other team members:

- `PowerEditor/cocoa/NotepadPlusPlus.xcodeproj/xcshareddata/xcschemes/Notepad++.xcscheme`
- `scintilla/cocoa/Scintilla/Scintilla.xcodeproj/xcshareddata/xcschemes/Scintilla.xcscheme`
- `lexilla/src/Lexilla/Lexilla.xcodeproj/xcshareddata/xcschemes/Lexilla.xcscheme`

### Project Configuration Updates

**PowerEditor/cocoa/NotepadPlusPlus.xcodeproj/project.pbxproj:**
- Fixed MainMenu.xib path to `Resources/Base.lproj/MainMenu.xib`
- Added all header files (.h) to project structure
- Updated framework search paths to use `$(CONFIGURATION)` variable
- Added comprehensive header search paths
- Updated LastUpgradeCheck to 1500 (Xcode 15.0)

## Troubleshooting

### "Framework not found Scintilla"

**Cause**: Scintilla framework hasn't been built yet or is in the wrong location.

**Solution**: Build Scintilla first:
```bash
cd scintilla/cocoa
xcodebuild -project Scintilla/Scintilla.xcodeproj \
           -scheme Scintilla \
           -configuration Release \
           build
```

### "Framework not found Lexilla"

**Cause**: Lexilla framework hasn't been built yet.

**Solution**: Build Lexilla:
```bash
cd lexilla/src/Lexilla
xcodebuild -project Lexilla.xcodeproj \
           -scheme Lexilla \
           -configuration Release \
           build
```

### "No such file or directory: MainMenu.xib"

**Cause**: Old project configuration with incorrect path.

**Solution**: This has been fixed in the latest project configuration. Make sure you have the updated project.pbxproj file.

### Build settings not found

**Cause**: Using an older version of Xcode.

**Solution**: Update to Xcode 13.0 or later. The project is configured for Xcode 15.0 but should work with 13.0+.

### Code signing errors

**Cause**: Missing code signing identity for distribution.

**Solution for Development**:
```bash
# Remove code signing requirement temporarily
codesign --remove-signature build/Release/Notepad++.app
```

**Solution for Distribution**:
Set your code signing identity in the project build settings.

## Clean Build

To perform a clean build:

```bash
# Clean all projects
cd scintilla/cocoa
xcodebuild -project Scintilla/Scintilla.xcodeproj -scheme Scintilla clean

cd ../../lexilla/src/Lexilla  
xcodebuild -project Lexilla.xcodeproj -scheme Lexilla clean

cd ../../../PowerEditor/cocoa
xcodebuild -project NotepadPlusPlus.xcodeproj -scheme Notepad++ clean
```

Or using the build script:
```bash
cd PowerEditor/cocoa/scripts
./build.sh clean
```

## Advanced Configuration

### Custom Build Location

By default, Xcode builds to:
- `scintilla/cocoa/build/`
- `lexilla/src/Lexilla/build/`
- `PowerEditor/cocoa/build/`

To change this, modify the `CONFIGURATION_BUILD_DIR` build setting.

### Optimization Levels

Release builds use default Apple optimization (`-Os`). To change:

1. Open the project in Xcode
2. Select the target
3. Build Settings → Optimization Level
4. Change as needed

### Adding Source Files

When adding new source files:

1. Add the `.mm` or `.m` file to the appropriate group in Xcode
2. Add the corresponding `.h` file to the same group
3. Ensure the `.mm`/`.m` file is in the "Compile Sources" build phase
4. The `.h` file should NOT be in "Compile Sources"

## Integration with CI/CD

Example GitHub Actions workflow:

```yaml
name: Build macOS

on: [push, pull_request]

jobs:
  build:
    runs-on: macos-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Build Scintilla
      run: |
        cd scintilla/cocoa
        xcodebuild -project Scintilla/Scintilla.xcodeproj \
                   -scheme Scintilla \
                   -configuration Release \
                   build
    
    - name: Build Lexilla
      run: |
        cd lexilla/src/Lexilla
        xcodebuild -project Lexilla.xcodeproj \
                   -scheme Lexilla \
                   -configuration Release \
                   build
    
    - name: Build Notepad++
      run: |
        cd PowerEditor/cocoa
        xcodebuild -project NotepadPlusPlus.xcodeproj \
                   -scheme Notepad++ \
                   -configuration Release \
                   build
```

## Additional Resources

- [BUILD.md](../../BUILD.md) - General build instructions
- [INSTALL_MACOS.md](../../INSTALL_MACOS.md) - Installation guide
- [macOS_QUICKSTART.md](../../macOS_QUICKSTART.md) - Quick start guide
- [Apple Xcode Documentation](https://developer.apple.com/documentation/xcode)

## Changes Log

### 2024-02-08
- Fixed MainMenu.xib path reference
- Added all header files to project structure  
- Updated framework search paths to use $(CONFIGURATION)
- Added comprehensive header search paths
- Updated to Xcode 15.0 compatibility
- Created shared build schemes for all projects
- Updated .gitignore for Xcode artifacts
