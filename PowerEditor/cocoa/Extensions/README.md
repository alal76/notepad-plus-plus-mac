# macOS Extensions for Notepad++

This directory contains macOS system extensions that enhance Notepad++ integration with the operating system.

## Available Extensions

### Quick Action Extension ✅ COMPLETE
**Location**: `QuickAction/`

A macOS Quick Action extension that enables users to open files, text selections, and web content in Notepad++ directly from:
- Finder's context menu (right-click)
- Finder's toolbar
- Touch Bar (MacBook Pro)
- Any application via Services menu

**Status**: Implementation complete, ready for Xcode integration  
**Compatibility**: macOS 10.15+ (Catalina and later)  
**Documentation**: See [QuickAction/README.md](QuickAction/README.md)

**Quick Start**:
1. Follow [QuickAction/BUILD_CONFIGURATION.md](QuickAction/BUILD_CONFIGURATION.md) to integrate with Xcode
2. Or use [QuickAction/INTEGRATION_GUIDE.md](QuickAction/INTEGRATION_GUIDE.md) for CMake/Makefile builds
3. Build and embed in main app bundle
4. Test in System Preferences → Extensions → Finder

---

## Planned Extensions

### Finder Sync Extension 🚧 PLANNED
**Status**: Not yet implemented  
**Purpose**: Enhanced context menu integration similar to Windows NppShell.dll

Would provide:
- Custom context menu items in Finder
- Badge overlays on files/folders
- File state monitoring
- More control over menu appearance

See [macOS_TODO.md](../../macOS_TODO.md) for implementation checklist.

### Share Extension 💡 FUTURE
**Status**: Idea phase  
**Purpose**: Share files/text to Notepad++ from other apps

Would enable:
- Share from Safari, Mail, Photos, etc.
- "Open in Notepad++" share option
- Text/file sharing from iOS via Handoff

---

## Extension Architecture

All macOS extensions follow Apple's extension architecture:

```
Notepad++.app/
└── Contents/
    ├── MacOS/
    │   └── Notepad++                    # Main application
    ├── PlugIns/
    │   ├── QuickAction.appex/          # Quick Action Extension
    │   ├── FinderSync.appex/           # (Future) Finder Sync
    │   └── ShareExtension.appex/       # (Future) Share Extension
    └── Info.plist                       # Main app configuration
```

### Security Model

All extensions must:
- Run in App Sandbox
- Declare required entitlements
- Be code signed (same identity as main app)
- Follow principle of least privilege

### Communication

Extensions communicate with the main app via:
1. **NSWorkspace** - Launch app with files/URLs (Quick Action)
2. **XPC Services** - Inter-process communication (Finder Sync)
3. **URL Schemes** - Custom URL handlers (optional)
4. **Shared Containers** - Shared preferences/data (if needed)

---

## Development Guidelines

### Adding a New Extension

1. **Create extension directory** under `Extensions/`
2. **Implement required files**:
   - `Info.plist` with proper NSExtension configuration
   - View controller or principal class
   - Entitlements file
   - Resources (icons, localizations)
3. **Document thoroughly**:
   - README.md with user documentation
   - BUILD_CONFIGURATION.md with build instructions
   - Code comments
4. **Test extensively**:
   - Multiple macOS versions
   - Different user scenarios
   - Error conditions
   - Performance impact

### Best Practices

- **Minimal UI**: Extensions should be lightweight
- **Fast Launch**: Keep initialization quick
- **Error Handling**: Always handle failures gracefully
- **User Feedback**: Provide clear messages for errors
- **Testing**: Test on oldest supported macOS version (10.15)
- **Documentation**: Keep docs in sync with code

### Code Style

- Use Objective-C++ (.mm files) for Cocoa integration
- Follow Apple's Cocoa naming conventions
- Add comments for non-obvious logic
- Handle memory management properly (ARC)
- Use modern APIs when available

---

## Testing Extensions

### Manual Testing

1. **Build and Install**:
   ```bash
   xcodebuild -scheme Notepad++ -configuration Release
   cp -R build/Release/Notepad++.app /Applications/
   ```

2. **Register Extensions**:
   ```bash
   pluginkit -a /Applications/Notepad++.app
   pluginkit -m -v | grep notepad
   ```

3. **Test Functionality**:
   - Verify in System Preferences → Extensions
   - Test all entry points (Finder, Touch Bar, etc.)
   - Test error conditions
   - Check Console.app for errors

### Automated Testing

Currently manual testing only. Future: Add XCTest unit tests for extension logic.

---

## Troubleshooting

### Extension Not Appearing

1. Check extension is embedded in app bundle:
   ```bash
   ls -la /Applications/Notepad++.app/Contents/PlugIns/
   ```

2. Force re-registration:
   ```bash
   pluginkit -r /Applications/Notepad++.app
   ```

3. Check system logs:
   ```bash
   log stream --predicate 'subsystem == "com.apple.NSExtension"'
   ```

### Extension Crashes

1. Check Console.app for crash logs
2. Look for "NotepadQuickAction" or extension name
3. Build with debug symbols for stack traces
4. Test on different macOS versions

### Code Signing Issues

1. Verify both app and extensions are signed:
   ```bash
   codesign -vvv --deep /Applications/Notepad++.app
   ```

2. Check entitlements:
   ```bash
   codesign -d --entitlements - /Applications/Notepad++.app/Contents/PlugIns/QuickAction.appex
   ```

---

## Contributing

When contributing extensions:

1. Follow existing patterns in QuickAction/
2. Provide complete documentation
3. Test on multiple macOS versions
4. Include build configurations for Xcode, CMake, and Makefile
5. Update this README.md
6. Update macOS_TODO.md

---

## Resources

- [Apple Extension Programming Guide](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/)
- [App Extension Best Practices](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/ExtensionCreation.html)
- [NSExtension Documentation](https://developer.apple.com/documentation/foundation/nsextension)
- [Finder Sync Extensions](https://developer.apple.com/documentation/findersync)
- [Share Extensions](https://developer.apple.com/documentation/uikit/share_extensions)

---

## License

All extensions are part of the Notepad++ for macOS project and follow the same license as the main application.

Copyright © 2024 Notepad++. All rights reserved.
