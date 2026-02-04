# Notepad++ Quick Action Extension

This Quick Action extension allows you to quickly open files, text, and URLs in Notepad++ directly from Finder, Touch Bar, and other macOS system contexts.

## Features

- **Right-click integration**: Open files directly from Finder's context menu
- **Touch Bar support**: Quick access from the MacBook Pro Touch Bar
- **Multiple file support**: Open up to 100 files at once
- **Text support**: Create new files from selected text
- **Web integration**: Download and open web page sources from Safari and other browsers
- **Universal compatibility**: Works with all text-based file types

## System Requirements

- macOS 10.15 (Catalina) or later
- Notepad++ for macOS installed in Applications folder

## Installation

The Quick Action extension is bundled with Notepad++ for macOS. To enable it:

### Method 1: Automatic Installation
1. Build Notepad++ with the extension included (see Build Instructions below)
2. Launch Notepad++ at least once
3. The extension should be automatically registered with macOS

### Method 2: Manual Activation
If the Quick Action doesn't appear automatically:

1. Open **System Preferences** → **Extensions** → **Finder**
2. Look for "Open in Notepad++" in the list
3. Check the box to enable it

Alternatively, you can enable it via System Settings on macOS 13+:
1. Open **System Settings** → **Privacy & Security** → **Extensions** → **Finder**
2. Enable "Open in Notepad++"

## Usage

### From Finder
1. Right-click (or Control-click) on one or more files
2. Navigate to **Quick Actions** in the context menu
3. Click **"Open in Notepad++"**

### From Touch Bar
1. Select files in Finder
2. Look for the Notepad++ icon in your Touch Bar
3. Tap to open selected files

### From Safari (Web Content)
1. Right-click on a web page or selected text
2. Navigate to **Services** menu
3. Click **"Open in Notepad++"** to download and open the page source

### From Any Application (Selected Text)
1. Select text in any application
2. Right-click on the selection
3. Navigate to **Services** → **"Open in Notepad++"**
4. A temporary file will be created with your selected text

## Build Instructions

### Adding to Xcode Project

1. **Add the Extension Target:**
   ```
   File → New → Target → Application Extension → Action Extension
   Name: NotepadQuickAction
   Bundle Identifier: org.notepad-plus-plus.QuickAction
   ```

2. **Replace the generated files with the provided files:**
   - `Info.plist`
   - `ActionViewController.h`
   - `ActionViewController.mm`
   - `Action.js`

3. **Update the main app target:**
   - Add the extension to **Embedded Binaries** in the main app target
   - The extension will be included in `Notepad++.app/Contents/PlugIns/`

4. **Build settings:**
   - Set deployment target to macOS 10.15
   - Enable App Sandbox (required for extensions)
   - Add entitlements if needed (see Entitlements section)

### Building from Command Line

If using `xcodebuild`:
```bash
xcodebuild -target NotepadQuickAction -configuration Release
```

The built extension will be located at:
```
build/Release/Notepad++.app/Contents/PlugIns/NotepadQuickAction.appex
```

## Entitlements

The extension requires the following entitlements to function:

**NotepadQuickAction.entitlements:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.files.user-selected.read-only</key>
    <true/>
    <key>com.apple.security.network.client</key>
    <true/>
</dict>
</plist>
```

Add this entitlements file to your extension target in Xcode:
1. Select the NotepadQuickAction target
2. Go to **Signing & Capabilities**
3. Add the entitlements file or configure App Sandbox capabilities

## Troubleshooting

### Extension not appearing in Finder
1. Make sure Notepad++ is installed in `/Applications/`
2. Launch Notepad++ at least once to register the extension
3. Check System Preferences → Extensions → Finder
4. Try running: `pluginkit -m -v` to see all installed extensions
5. Force reload extensions: `pluginkit -r /Applications/Notepad++.app`

### "Notepad++ application not found" error
- Ensure Notepad++ is installed with bundle identifier `org.notepad-plus-plus`
- Check that the app is in a standard location (`/Applications/`)
- Verify the app is not quarantined: `xattr -d com.apple.quarantine /Applications/Notepad++.app`

### Files not opening
- Check that Notepad++ has permission to access files
- Grant Full Disk Access if needed: System Preferences → Security & Privacy → Privacy → Full Disk Access
- Verify the extension has proper entitlements

### Extension crashes
- Check Console.app for crash logs (search for "NotepadQuickAction")
- Ensure the extension is compiled for your macOS version
- Rebuild with debug symbols enabled for more information

## Technical Details

### Architecture
- **Language**: Objective-C++ (.mm files for Cocoa/C++ interop)
- **Framework**: Cocoa, Foundation, UniformTypeIdentifiers
- **Extension Type**: UI Services (Action Extension)
- **Communication**: Uses NSWorkspace to launch the main app with file URLs

### File Type Support
The extension accepts files conforming to:
- `public.plain-text` (txt, log, etc.)
- `public.source-code` (all programming languages)
- `public.script` (shell scripts, Python, etc.)
- `public.xml`, `public.json`, `public.html`
- All types registered with Notepad++ in its Info.plist

### Implementation Notes
1. **File Opening**: Uses `NSWorkspace.openURLs:withApplicationAtURL:` for reliable app launching
2. **Text Handling**: Creates temporary files for text selections (cleaned up by system)
3. **Web Content**: Downloads URL content via NSURLSession before opening
4. **Multiple Files**: Can handle up to 100 files in a single action
5. **Error Handling**: Displays alerts for common errors (app not found, file access denied)

## Customization

### Changing the Icon
Replace `NSActionTemplate` in Info.plist with a custom icon:
```xml
<key>NSExtensionServiceFinderPreviewIconName</key>
<string>YourCustomIcon</string>
```
Add your icon asset to the extension's asset catalog.

### Modifying Activation Rules
Edit the `NSExtensionActivationRule` in Info.plist:
- Change `NSExtensionActivationSupportsFileWithMaxCount` to limit file count
- Add `NSExtensionActivationSupportsImageWithMaxCount` for image files
- Modify type conformance for specific file types only

### Custom URL Scheme
To use a custom URL scheme (e.g., `notepadpp://open?file=...`):
1. Add URL scheme support to main app's Info.plist
2. Implement `-application:openURL:` in AppDelegate
3. Modify `openFileInNotepadPlusPlus:` to construct and open custom URLs

## Future Enhancements

Possible improvements for future versions:
- [ ] Add preview functionality before opening
- [ ] Support for folders (open all text files in folder)
- [ ] Quick peek at file contents
- [ ] Recently opened files list
- [ ] Integration with macOS Shortcuts app
- [ ] Configurable file type filters
- [ ] Option to open in new window or existing window

## Contributing

Contributions are welcome! When submitting changes:
1. Test on multiple macOS versions (10.15+)
2. Ensure extension builds without warnings
3. Update documentation for new features
4. Follow existing code style (Objective-C++ conventions)

## License

Copyright © 2024 Notepad++. All rights reserved.

This extension is part of the Notepad++ for macOS project and follows the same license as the main application.

## Support

For issues and questions:
- GitHub Issues: https://github.com/notepad-plus-plus/notepad-plus-plus-mac
- Documentation: See macOS_README.md in the main repository

## See Also

- [macOS Port Plan](../../macOS_PORT_PLAN.md) - Overall macOS porting strategy
- [macOS Architecture](../../macOS_ARCHITECTURE.md) - Technical architecture details
- [macOS Shell Integration](../../macOS_SHELL_INTEGRATION.md) - Command-line integration
