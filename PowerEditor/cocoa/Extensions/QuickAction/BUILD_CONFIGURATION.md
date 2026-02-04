# Xcode Build Configuration for Quick Action Extension

This document provides instructions for integrating the Quick Action extension into your Xcode project.

## Quick Setup

### 1. Create Extension Target

In Xcode:
```
File → New → Target → macOS → Application Extension → Action Extension
```

**Settings:**
- Product Name: `NotepadQuickAction`
- Organization Identifier: `org.notepad-plus-plus`
- Language: Objective-C
- Project: Notepad++ (add to existing project)

### 2. Configure Extension Target

#### Build Settings

In the NotepadQuickAction target settings:

**General Tab:**
- Bundle Identifier: `org.notepad-plus-plus.QuickAction`
- Version: `1.0`
- Build: `1`
- Deployment Target: `macOS 10.15`

**Signing & Capabilities:**
- Enable App Sandbox
- Add capabilities:
  - User Selected Files: Read Only
  - Network: Outgoing Connections (Client)

**Build Settings:**
- Base SDK: Latest macOS
- macOS Deployment Target: `10.15`
- Architectures: `$(ARCHS_STANDARD)` (arm64, x86_64)
- Build Active Architecture Only: `No` (for Release)

#### Linked Frameworks
Add the following frameworks to your extension target:
- `Cocoa.framework`
- `Foundation.framework`
- `UniformTypeIdentifiers.framework` (macOS 11.0+, weak link for 10.15)

### 3. Replace Template Files

Delete the auto-generated files and add the Quick Action files:

**Remove:**
- `ActionViewController.h` (template)
- `ActionViewController.m` (template)
- `Action.js` (template)
- `Info.plist` (will be replaced)

**Add to Extension Target:**
- `ActionViewController.h` (from this directory)
- `ActionViewController.mm` (from this directory) - Note: .mm not .m
- `Action.js` (from this directory)
- `Info.plist` (from this directory)
- `NotepadQuickAction.entitlements` (from this directory)

### 4. Update Main App Target

In your main Notepad++ app target:

**General Tab → Embedded Binaries:**
- Add `NotepadQuickAction.appex`

This ensures the extension is bundled inside your main app at:
```
Notepad++.app/Contents/PlugIns/NotepadQuickAction.appex
```

**Info.plist:**
Ensure your main app has the correct bundle identifier:
```xml
<key>CFBundleIdentifier</key>
<string>org.notepad-plus-plus</string>
```

### 5. Scheme Configuration

Edit your scheme (Product → Scheme → Edit Scheme):

**Run:**
- Executable: `Notepad++.app`
- Build Configuration: `Debug`

**Test:**
- Add your extension target if you want to debug it

## Manual Build Steps

### Build Extension Only
```bash
xcodebuild -scheme NotepadQuickAction -configuration Release build
```

### Build Main App with Extension
```bash
xcodebuild -scheme Notepad++ -configuration Release build
```

### Install Locally for Testing
```bash
# Build and copy to Applications
xcodebuild -scheme Notepad++ -configuration Release build DSTROOT=/ INSTALL_PATH=/Applications

# Reload plugin kit
pluginkit -a /Applications/Notepad++.app/Contents/PlugIns/NotepadQuickAction.appex
```

## Debugging

### Enable Extension Debugging

1. **Set Extension Scheme:**
   - Product → Scheme → Manage Schemes
   - Select `NotepadQuickAction`
   - Check "Show this scheme"

2. **Configure Run:**
   - Edit Scheme → Run
   - Executable: Ask on Launch
   - Wait for executable to be launched

3. **Debug Session:**
   - Run the extension scheme
   - Trigger the Quick Action from Finder
   - Xcode will attach debugger to the extension process

### View Console Logs

```bash
# View all extension-related logs
log stream --predicate 'process == "NotepadQuickAction"' --level debug

# View NSExtension logs
log stream --predicate 'subsystem == "com.apple.NSExtension"' --level debug
```

### Common Build Issues

**Issue: "No such module 'UniformTypeIdentifiers'"**
- Solution: Set deployment target to 10.15 and weak-link the framework
- Or use `@available(macOS 11.0, *)` guards and fallback to older APIs

**Issue: Extension not appearing in Finder**
- Solution: Make sure extension is embedded in main app bundle
- Run: `pluginkit -m -v` to list all extensions
- Force register: `pluginkit -a YourApp.app`

**Issue: Code signing errors**
- Solution: Ensure both app and extension have proper signing
- Use same Team ID for both targets
- Check that entitlements are properly configured

## File Structure

After building, your app bundle should look like:

```
Notepad++.app/
├── Contents/
│   ├── Info.plist
│   ├── MacOS/
│   │   └── Notepad++
│   ├── PlugIns/
│   │   └── NotepadQuickAction.appex/
│   │       ├── Contents/
│   │       │   ├── Info.plist
│   │       │   ├── MacOS/
│   │       │   │   └── NotepadQuickAction
│   │       │   └── Resources/
│   │       │       └── Action.js
│   │       └── NotepadQuickAction.entitlements
│   └── Resources/
```

## Code Signing

### Development Signing

For local testing:
```bash
codesign --force --deep --sign - /Applications/Notepad++.app
```

### Distribution Signing

For App Store or distribution:
```bash
# Sign extension first
codesign --force --sign "Developer ID Application: Your Name" \
  --entitlements NotepadQuickAction.entitlements \
  Notepad++.app/Contents/PlugIns/NotepadQuickAction.appex

# Then sign main app
codesign --force --sign "Developer ID Application: Your Name" \
  --entitlements Notepad.entitlements \
  Notepad++.app
```

## Testing Checklist

After building and installing:

- [ ] Extension appears in System Preferences → Extensions → Finder
- [ ] Right-click on a .txt file shows "Open in Notepad++" in Quick Actions
- [ ] Opening a file launches Notepad++ correctly
- [ ] Multiple file selection works
- [ ] Extension works with different file types (code, text, config files)
- [ ] Error handling works (e.g., when Notepad++ is not installed)
- [ ] Extension works from Touch Bar (if available)
- [ ] Web content can be opened from Safari
- [ ] Selected text can be opened from any app

## Troubleshooting Build

### Clean Build
```bash
xcodebuild clean -scheme NotepadQuickAction
xcodebuild clean -scheme Notepad++
rm -rf ~/Library/Developer/Xcode/DerivedData/Notepad*
```

### Verify Extension
```bash
# Check if extension is properly embedded
unzip -l Notepad++.app | grep NotepadQuickAction

# Check bundle IDs
/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" \
  Notepad++.app/Contents/Info.plist

/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" \
  Notepad++.app/Contents/PlugIns/NotepadQuickAction.appex/Contents/Info.plist
```

## CI/CD Integration

### GitHub Actions Example
```yaml
- name: Build Notepad++ with Extension
  run: |
    xcodebuild -scheme Notepad++ \
      -configuration Release \
      -derivedDataPath build \
      CODE_SIGN_IDENTITY="" \
      CODE_SIGNING_REQUIRED=NO
    
- name: Verify Extension
  run: |
    ls -la build/Build/Products/Release/Notepad++.app/Contents/PlugIns/
    test -d build/Build/Products/Release/Notepad++.app/Contents/PlugIns/NotepadQuickAction.appex
```

## Resources

- [Apple Extension Programming Guide](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/)
- [App Extension Best Practices](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/ExtensionCreation.html)
- [Action Extensions](https://developer.apple.com/documentation/foundation/nsextensionitem)
- [UniformTypeIdentifiers](https://developer.apple.com/documentation/uniformtypeidentifiers)
