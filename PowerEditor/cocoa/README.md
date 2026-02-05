# Notepad++ macOS Implementation

This directory contains the macOS-specific implementation of Notepad++.

## Directory Structure

```
PowerEditor/cocoa/
├── AppKit/              # Main application classes
│   ├── AppDelegate.h/mm          # Application lifecycle and services
│   ├── MainWindowController.h/mm # Main window management
│   ├── DocumentController.h/mm   # Multi-document management
│   └── Document.h/mm             # Document model
│
├── Platform/            # Platform abstraction layer
│   ├── FileManager.h/mm          # File operations for macOS
│   └── ConfigManager.h/mm        # Configuration management
│
├── Controls/            # AppKit control wrappers (TODO)
│   ├── TabBarController.h/mm     # Tab bar for documents
│   ├── StatusBarController.h/mm  # Status bar
│   └── ...
│
├── Panels/              # Docking panels (TODO)
│   ├── FunctionListPanel.h/mm    # Function list
│   ├── FileBrowserPanel.h/mm     # File browser
│   └── ...
│
├── Resources/           # Application resources
│   ├── Info.plist               # Bundle information
│   ├── Assets.xcassets/         # Icons and images
│   └── ...
│
└── main.m               # Application entry point
```

## Current Implementation Status

### ✅ Phase 1 Complete (Foundation)
- [x] Project structure created
- [x] Info.plist with file associations and services
- [x] AppDelegate with application lifecycle
- [x] MainWindowController with basic UI
- [x] Document model with encoding detection
- [x] DocumentController for multi-document management
- [x] Platform abstraction layer (FileManager, ConfigManager)

### 🚧 Phase 2 In Progress (Core Features)
- [ ] ScintillaView integration
- [ ] File open/save functionality
- [ ] Basic menu system
- [ ] Toolbar implementation
- [ ] Status bar with document info
- [ ] Tab bar for multiple documents

### 📋 Phase 3 Planned (Advanced Features)
- [ ] Find/Replace dialog
- [ ] Syntax highlighting integration
- [x] Preferences window
- [ ] Split view functionality
- [ ] Session management
- [ ] Advanced panels (function list, file browser)

### 📋 Phase 4 Planned (Polish & Distribution)
- [ ] macOS HIG compliance
- [ ] Performance optimization
- [ ] Code signing and notarization
- [ ] Distribution package (.dmg)

## Building

### Prerequisites
- macOS 10.15 or later
- Xcode 13.0 or later
- Command Line Tools

### Build Steps

1. **Build Scintilla framework:**
```bash
cd scintilla/cocoa
xcodebuild -project Scintilla.xcodeproj -scheme Scintilla -configuration Release
```

2. **Build Lexilla framework:**
```bash
cd lexilla/src/Lexilla
xcodebuild -project Lexilla.xcodeproj -scheme Lexilla -configuration Release
```

3. **Create Xcode project for Notepad++:**
   - Use the provided project structure
   - Link Scintilla.framework and Lexilla.framework
   - Configure code signing
   - Build the application

## Architecture

The macOS implementation follows a layered architecture:

1. **macOS Application Layer**: Native AppKit UI components
2. **Platform Abstraction Layer**: Wraps macOS-specific APIs
3. **Core Logic Layer**: Cross-platform C++ code (minimal changes)
4. **ScintillaComponent Layer**: Thin wrapper around Scintilla
5. **Scintilla Cocoa Layer**: Existing mature implementation (no changes)

## Key Design Decisions

### Language: Objective-C++
- Allows direct integration with existing C++ code
- Full access to AppKit APIs
- No need to rewrite core logic

### UI Framework: Native AppKit
- Native macOS look and feel
- Best performance
- Follows macOS Human Interface Guidelines

### Configuration: Hybrid Approach
- NSUserDefaults (plist) for UI state
- XML files for language definitions and styles (compatibility)

### File Associations
- Defined in Info.plist
- Supports 100+ file types
- macOS Services for "Open in Notepad++"

## Implementation Guidelines

1. **Use Objective-C++** (.mm files) for classes that interface with AppKit
2. **Keep platform-specific code isolated** in the Platform/ directory
3. **Minimize changes to existing C++ core** 
4. **Follow macOS conventions**:
   - Use Cmd instead of Ctrl
   - Follow standard keyboard shortcuts
   - Use standard AppKit controls

## Testing

### Manual Testing Checklist
- [ ] Launch application
- [ ] Create new document
- [ ] Open existing file
- [ ] Edit and save
- [ ] Multiple documents in tabs
- [ ] File associations work
- [ ] Services menu appears

### Automated Testing
- Unit tests using XCTest (TODO)
- Integration tests for file I/O (TODO)
- UI tests using XCUITest (TODO)

## Contributing

When adding new features:
1. Follow the existing architecture
2. Use the platform abstraction layer for OS-specific code
3. Document public interfaces
4. Add unit tests where appropriate
5. Ensure macOS HIG compliance

## Resources

- [macOS Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/macos)
- [AppKit Programming Guide](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/AppKit_Framework/)
- [Scintilla Documentation](https://www.scintilla.org/ScintillaDoc.html)
- [Notepad++ Source](https://github.com/notepad-plus-plus/notepad-plus-plus)

## License

Copyright © 2024 Notepad++. All rights reserved.
