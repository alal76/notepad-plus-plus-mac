# macOS Release Process

This document describes how to create and publish macOS releases for Notepad++.

## Quick Start: Create a Release

The fastest way to create a release:

```bash
# 1. Ensure your code is ready
git checkout main
git pull

# 2. Create and push a version tag
git tag v1.0.0
git push origin v1.0.0

# 3. That's it! GitHub Actions will automatically:
#    - Build the macOS app
#    - Create a DMG package
#    - Publish a GitHub Release
```

Monitor the build at: https://github.com/alal76/notepad-plus-plus-mac/actions

## Overview

The macOS build and release process is automated via GitHub Actions. The workflow automatically:

1. **Builds** the Notepad++ application for macOS
2. **Packages** it into a distributable DMG file
3. **Uploads** artifacts for all builds
4. **Publishes** releases when a version tag is pushed

## Automated Builds

### When Builds Occur

Builds are triggered automatically for:

- **Pull Requests**: Builds and uploads artifacts for testing
- **Push to main/master/develop**: Builds and uploads artifacts
- **Version Tags** (e.g., `v1.0.0`): Builds, packages, and creates a GitHub Release
- **Manual Trigger**: Can be triggered manually from the Actions tab

### Build Process

The GitHub Actions workflow (`.github/workflows/macos_build.yml`) performs:

1. **Checkout**: Clones the repository with submodules
2. **Setup Xcode**: Configures the latest stable Xcode
3. **Build Frameworks**: Compiles Scintilla.framework and Lexilla.framework
4. **Build App**: Compiles Notepad++.app
5. **Create DMG**: Packages the app into a macOS disk image
6. **Upload Artifacts**: Makes the DMG available for download
7. **Create Release**: (For tags only) Creates a GitHub Release with release notes

## Creating a Release

### Step 1: Update Version Information

Before creating a release, update version information in the app's `Info.plist`:

```bash
# Edit PowerEditor/cocoa/Info.plist
# Update CFBundleShortVersionString and CFBundleVersion
```

### Step 2: Commit Changes

```bash
git add .
git commit -m "Bump version to X.Y.Z"
git push origin main
```

### Step 3: Create and Push a Version Tag

```bash
# Create a tag (use semantic versioning: vMAJOR.MINOR.PATCH)
git tag v1.0.0

# Push the tag to trigger the release workflow
git push origin v1.0.0
```

### Step 4: Wait for Build to Complete

The GitHub Actions workflow will:
- Build the app for macOS
- Create a DMG package
- Create a GitHub Release automatically
- Attach the DMG to the release

Monitor progress at: `https://github.com/alal76/notepad-plus-plus-mac/actions`

### Step 5: Verify the Release

1. Go to `https://github.com/alal76/notepad-plus-plus-mac/releases`
2. Find your newly created release
3. Download and test the DMG file
4. Verify the app runs correctly

## Manual Package Creation

If you need to create a package manually (outside of CI):

### Prerequisites

- macOS 11.0 (Big Sur) or later
- Xcode 13.0 or later
- Xcode Command Line Tools installed

### Build and Package

```bash
# Clone the repository
git clone https://github.com/alal76/notepad-plus-plus-mac.git
cd notepad-plus-plus-mac

# Build the application
cd PowerEditor/cocoa/scripts
./build.sh -c Release

# Create DMG package
./package.sh -c Release -n "Notepad++-1.0.0-macOS"
```

The DMG will be created at: `PowerEditor/cocoa/build/Notepad++-1.0.0-macOS.dmg`

### Package Options

```bash
# Build and package with custom name
./package.sh -n "MyCustomName"

# Skip rebuild, just package existing build
./package.sh -s

# Build for specific configuration
./package.sh -c Debug

# Package to custom output directory
./package.sh -o /path/to/output
```

## Code Signing and Notarization

For public distribution, macOS packages should be code signed and notarized.

### Code Signing

To sign the application:

```bash
# Build with code signing
./build.sh -c Release -s "Developer ID Application: Your Name (TEAM_ID)"

# Then package
./package.sh -c Release
```

### Notarization

To notarize the DMG (requires Apple Developer account):

```bash
export APPLE_ID="your-apple-id@example.com"
export APPLE_TEAM_ID="YOUR_TEAM_ID"
export APPLE_PASSWORD="app-specific-password"

./package.sh -c Release --notarize
```

### GitHub Actions Code Signing

To enable code signing in GitHub Actions, add these secrets to your repository:

1. Go to Settings → Secrets and variables → Actions
2. Add the following secrets:
   - `MACOS_CERTIFICATE`: Base64-encoded .p12 certificate
   - `MACOS_CERTIFICATE_PASSWORD`: Certificate password
   - `APPLE_ID`: Your Apple ID email
   - `APPLE_TEAM_ID`: Your developer team ID
   - `APPLE_APP_PASSWORD`: App-specific password

Then update the workflow to use these secrets for signing and notarization.

## Distribution Checklist

Before releasing to the public, verify:

- [ ] DMG opens correctly on macOS 11.0+
- [ ] App installs to Applications folder
- [ ] App launches without errors
- [ ] App works on both Intel and Apple Silicon Macs
- [ ] All core features work as expected
- [ ] Release notes are accurate and complete
- [ ] Version number is correct in About dialog
- [ ] App is code signed (for public distribution)
- [ ] App is notarized (for public distribution)

## Version Numbering

Follow [Semantic Versioning](https://semver.org/):

- **MAJOR** version: Incompatible API changes
- **MINOR** version: New functionality (backwards compatible)
- **PATCH** version: Bug fixes (backwards compatible)

Examples:
- `v1.0.0` - Initial stable release
- `v1.1.0` - New features added
- `v1.1.1` - Bug fixes
- `v2.0.0` - Major changes/breaking changes

## Troubleshooting

### Build Fails in GitHub Actions

1. Check the Actions tab for detailed logs
2. Verify all build scripts have execute permissions
3. Ensure submodules are properly initialized
4. Check for Xcode version compatibility issues

### DMG Creation Fails

1. Verify the app bundle was built successfully
2. Check that required frameworks are included
3. Ensure sufficient disk space for DMG creation
4. Review package.sh logs for specific errors

### Notarization Fails

1. Verify your Apple Developer credentials
2. Check that app is properly code signed
3. Ensure app-specific password is correct
4. Review notarization logs:
   ```bash
   # Get the submission ID from notarytool submit output, then:
   xcrun notarytool log <submission-id> \
     --apple-id <apple-id> \
     --team-id <team-id> \
     --password <app-specific-password>
   ```

## Additional Resources

- [BUILD.md](BUILD.md) - Build instructions
- [INSTALL_MACOS.md](INSTALL_MACOS.md) - Installation guide
- [macOS_README.md](macOS_README.md) - macOS port documentation
- [Apple Developer Documentation](https://developer.apple.com/documentation/)

## Support

For issues or questions:

- Report bugs: https://github.com/alal76/notepad-plus-plus-mac/issues
- Discussions: https://github.com/alal76/notepad-plus-plus-mac/discussions
