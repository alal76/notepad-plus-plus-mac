# Notepad++ macOS Port - Comprehensive Plan

## Executive Summary

This document outlines the complete plan for porting Notepad++ to macOS. The analysis shows that while **Scintilla (the editor core) already has a mature Cocoa implementation**, the main Notepad++ application is heavily Windows-dependent with ~30 custom Windows controls and extensive Win32 API usage.

**Estimated Effort**: 10-16 weeks with 2-4 developers
**Feasibility**: High - Thanks to existing Scintilla Cocoa backend
**Main Challenge**: UI layer migration (30+ WinControls to AppKit)

---

## Current State Analysis

### ✅ What Already Works (Scintilla Cocoa)

The `scintilla/cocoa/` directory contains a **complete, mature Cocoa implementation**:

- **Core Editor**: ScintillaCocoa.mm (850+ lines)
- **Platform Layer**: PlatCocoa.h/mm (2400+ lines) 
- **View Integration**: ScintillaView.h/mm
- **Text Rendering**: QuartzTextLayout.h (Quartz 2D)
- **Features**:
  - ✅ Full text editing
  - ✅ Syntax highlighting
  - ✅ Code folding
  - ✅ Clipboard operations
  - ✅ Drag & drop
  - ✅ Auto-completion
  - ✅ Context menus
  - ✅ Keyboard handling

**Build System**: Xcode projects exist for Scintilla framework
- `scintilla/cocoa/Scintilla/Scintilla.xcodeproj`
- `lexilla/src/Lexilla/Lexilla.xcodeproj`

### ❌ What Needs Porting (Notepad++ Application Layer)

#### 1. **Window Management & UI Controls** (HIGH EFFORT)

**Location**: `PowerEditor/src/WinControls/`

30+ custom Windows controls need AppKit equivalents:

| Windows Control | macOS Equivalent | Complexity | Priority |
|----------------|------------------|------------|----------|
| TabBar | NSTabView/NSTabbedWindow | Medium | Critical |
| ToolBar | NSToolbar | Low | Critical |
| StatusBar | NSTextField in bottom view | Low | Critical |
| ListView | NSTableView | Medium | High |
| TreeView | NSOutlineView | Medium | High |
| SplitterContainer | NSSplitView | Low | Critical |
| DockingWnd | NSSplitView + floating panels | High | High |
| StaticDialog | NSPanel/NSViewController | Medium | High |
| ColourPicker | NSColorPanel | Low | Medium |
| AboutDlg | Standard About window | Low | Medium |
| OpenSaveFileDialog | NSSavePanel/NSOpenPanel | Low | Critical |
| Grid | NSTableView with grid | Medium | Medium |
| ContextMenu | NSMenu | Low | High |
| Preference | NSPreferencePane style | High | High |
| TaskList | NSTableView | Medium | Medium |
| AnsiCharPanel | Custom NSView | Medium | Low |
| ClipboardHistory | Custom panel | Medium | Low |
| DocumentMap | Custom NSView with minimap | High | Low |
| FunctionList | NSOutlineView | Medium | Medium |
| ProjectPanel | NSOutlineView | Medium | Low |
| FileBrowser | NSBrowser/NSOutlineView | High | Medium |
| VerticalFileSwitcher | NSTableView | Medium | Low |
| PluginsAdmin | Custom UI | High | Low |

#### 2. **Windows API Dependencies** (HIGH EFFORT)

**Critical APIs to Replace**:

```cpp
// Window Management
HWND → NSWindow*, NSView*
CreateWindow → [[NSWindow alloc] init...]
GetWindowLong/SetWindowLong → NSWindow properties
InvalidateRect → [view setNeedsDisplay:YES]

// File I/O
CreateFile → NSFileHandle, fopen
FindFirstFile/FindNextFile → NSFileManager enumerator
ReadDirectoryChangesW → FSEvents or DispatchSourceFileSystemObject

// Registry
RegOpenKey/RegCreateKey → NSUserDefaults, plist files
Registry paths → ~/Library/Preferences/

// DLL/Plugin System
LoadLibrary → dlopen() or NSBundle
GetProcAddress → dlsym() or NSBundle methods
DLL inspection → otool, Mach-O parsing

// Paths
GetModuleFileName → [[NSBundle mainBundle] executablePath]
SHGetFolderPath → NSSearchPathForDirectoriesInDomains
```

#### 3. **Configuration & Storage** (MEDIUM EFFORT)

Current: Windows Registry + XML files in `%AppData%`

**macOS Approach**:
```
~/Library/Preferences/org.notepad-plus-plus.plist  # User preferences
~/Library/Application Support/Notepad++/           # Config files
  ├── config.xml
  ├── langs.xml
  ├── stylers.xml
  ├── shortcuts.xml
  ├── session.xml
  └── plugins/
```

#### 4. **Plugin System** (HIGH EFFORT)

**Current**: Windows DLL-based
- Plugin interface: HWND-based messaging
- Loading: LoadLibrary/GetProcAddress
- Signature verification: Windows PE format

**Required macOS Plugin System**:
```
Option 1: Dynamic Libraries (.dylib)
  - Use dlopen/dlsym
  - Mach-O code signing verification
  - Load from ~/Library/Application Support/Notepad++/plugins/

Option 2: Plugin Bundles (.bundle)
  - NSBundle-based loading
  - Better sandboxing support
  - More "Mac-like"
  
Option 3: App Extensions (Modern)
  - System-integrated
  - Best security
  - Most work to implement
```

**Recommendation**: Start with .dylib for compatibility, migrate to bundles later.

#### 5. **System Integration** (MEDIUM EFFORT)

| Feature | Windows | macOS Implementation |
|---------|---------|---------------------|
| File associations | Registry | Info.plist CFBundleDocumentTypes |
| Context menu | Shell extension DLL | macOS Service or Finder extension |
| Auto-update | WinSparkle | Sparkle framework |
| Installer | NSIS | .dmg + optionally Homebrew |
| Codesigning | Authenticode | Apple Developer ID |

---

## Phased Implementation Plan

### **Phase 1: Minimal Viable Product (3-4 weeks)**

**Goal**: Get basic editor working on macOS

#### Tasks:
- [x] Analyze codebase and create plan
- [ ] Create Xcode project structure
  - [ ] Set up application bundle (Info.plist, icons)
  - [ ] Configure code signing
  - [ ] Link Scintilla.framework and Lexilla.framework
- [ ] Create main application structure
  - [ ] Implement NSApplicationDelegate
  - [ ] Create main window (NSWindow + NSWindowController)
  - [ ] Integrate ScintillaView
  - [ ] Basic menu bar (File, Edit, View)
- [ ] File operations
  - [ ] Open file (NSOpenPanel)
  - [ ] Save file (NSSavePanel)
  - [ ] File I/O with encoding detection
  - [ ] Recent files list (NSDocumentController)
- [ ] Essential editing features
  - [ ] Cut/Copy/Paste
  - [ ] Undo/Redo
  - [ ] Find/Replace (basic)
  - [ ] Preferences (minimal)

**Deliverable**: Single-window editor that can open/edit/save files

### **Phase 2: Core UI & Multi-document (4-5 weeks)**

**Goal**: Multi-tab editing with essential UI

#### Tasks:
- [ ] Tab bar implementation
  - [ ] NSTabView or custom tab bar
  - [ ] Document switching
  - [ ] Tab context menus
  - [ ] Drag & drop reordering
- [ ] Split view
  - [ ] Horizontal/vertical split (NSSplitView)
  - [ ] Clone document to split
  - [ ] Synchronized scrolling option
- [ ] Search & Replace
  - [ ] Find dialog (NSPanel)
  - [ ] Replace functionality
  - [ ] Find in files (basic)
  - [ ] Regular expression support
- [ ] Status bar
  - [ ] Line/column display
  - [ ] Encoding selector
  - [ ] EOL format selector
  - [ ] Language selector
- [ ] Toolbar
  - [ ] NSToolbar with standard items
  - [ ] Customization support
- [ ] Language & syntax
  - [ ] Load language definitions (langs.xml)
  - [ ] Syntax highlighting via Lexilla
  - [ ] Auto-completion (basic)

**Deliverable**: Functional multi-tab editor with search/replace

### **Phase 3: Advanced Features & System Integration (3-4 weeks)**

**Goal**: Feature parity with core Notepad++ functionality

#### Tasks:
- [ ] Advanced panels
  - [ ] Document map (minimap view)
  - [ ] Function list (NSOutlineView)
  - [ ] Folder as Workspace (NSOutlineView)
  - [ ] Docking system (floating panels + NSSplitView)
- [ ] Advanced search
  - [ ] Find in Files with results panel
  - [ ] Bookmark system
  - [ ] Incremental search
  - [ ] Mark all functionality
- [ ] Preferences system
  - [ ] Multi-page preferences window
  - [ ] Style configurator
  - [ ] Shortcut mapper
  - [ ] Persistence to ~/Library/Preferences
- [ ] Plugin system (basic)
  - [ ] Plugin loader (.dylib)
  - [ ] Plugin interface adapter (HWND → macOS)
  - [ ] Plugin menu
  - [ ] Message routing
- [ ] Printing
  - [ ] NSPrintOperation integration
  - [ ] Print preview
  - [ ] Page setup
- [ ] Auto-update
  - [ ] Integrate Sparkle framework
  - [ ] Update checking
  - [ ] Release notes display

**Deliverable**: Feature-complete editor with plugin support

### **Phase 4: Polish & Compliance (2-3 weeks)**

**Goal**: macOS Human Interface Guidelines compliance

#### Tasks:
- [ ] macOS HIG compliance
  - [ ] Review all UI for consistency
  - [ ] Keyboard shortcuts (Cmd not Ctrl)
  - [ ] Touch Bar support (optional)
  - [ ] Dark mode testing
  - [ ] Accessibility (VoiceOver)
- [ ] Performance optimization
  - [ ] Large file handling
  - [ ] Startup time optimization
  - [ ] Memory profiling
- [ ] Localization
  - [ ] Extract strings to .strings files
  - [ ] Support for existing translations
- [ ] Documentation
  - [ ] User guide updates for macOS
  - [ ] Plugin development guide (macOS)
  - [ ] Build instructions
- [ ] Distribution
  - [ ] Notarization
  - [ ] Create .dmg installer
  - [ ] Homebrew formula (optional)
  - [ ] Mac App Store preparation (optional)

**Deliverable**: Production-ready macOS application

---

## Technical Architecture

### Recommended Layer Structure

```
┌─────────────────────────────────────────────────┐
│         Notepad++ macOS Application             │
│  (Objective-C++/Swift with AppKit)              │
├─────────────────────────────────────────────────┤
│        Platform Abstraction Layer               │
│  - Window Manager (NSWindow ↔ HWND)            │
│  - File I/O (NSFileManager ↔ Win32)            │
│  - Config (plist ↔ Registry)                   │
│  - Plugin Loader (NSBundle ↔ DLL)              │
├─────────────────────────────────────────────────┤
│         Notepad++ Core Logic                    │
│  (Most C++ code - minimal changes)              │
│  - Buffer management                            │
│  - Encoding detection                           │
│  - Command routing                              │
├─────────────────────────────────────────────────┤
│          ScintillaComponent                     │
│  (Thin wrapper - minor changes)                 │
├─────────────────────────────────────────────────┤
│      Scintilla Cocoa (No changes)               │
│  ✅ Already complete                            │
└─────────────────────────────────────────────────┘
```

### Code Organization

```
notepad-plus-plus-mac/
├── PowerEditor/
│   ├── src/                    # Core logic (cross-platform)
│   ├── cocoa/                  # NEW: macOS-specific code
│   │   ├── AppDelegate.h/mm
│   │   ├── MainWindow.h/mm
│   │   ├── DocumentController.h/mm
│   │   ├── Controls/           # AppKit control wrappers
│   │   │   ├── TabBarController.h/mm
│   │   │   ├── StatusBar.h/mm
│   │   │   └── ...
│   │   ├── Panels/             # Docking panels
│   │   │   ├── FunctionListPanel.h/mm
│   │   │   ├── FileBrowserPanel.h/mm
│   │   │   └── ...
│   │   ├── Platform/           # Platform abstraction
│   │   │   ├── FileManager.h/mm
│   │   │   ├── ConfigManager.h/mm
│   │   │   ├── PluginLoader.h/mm
│   │   │   └── ...
│   │   └── Resources/
│   │       ├── Info.plist
│   │       ├── Assets.xcassets/
│   │       └── Base.lproj/
│   └── xcodeproj/              # NEW: Xcode project
│       └── NotepadPlusPlus.xcodeproj/
├── scintilla/
│   └── cocoa/                  # ✅ Already complete
└── lexilla/
    └── src/
        └── Lexilla/            # ✅ Already has .xcodeproj
```

---

## Build System

### Xcode Project Setup

**Minimum Requirements**:
- macOS 11.0+ (Big Sur)
- Xcode 13.0+
- Deployment Target: macOS 10.15 (Catalina)

**Dependencies**:
```
Frameworks:
- Scintilla.framework (build from scintilla/cocoa/)
- Lexilla.framework (build from lexilla/src/Lexilla/)
- AppKit.framework
- Foundation.framework
- CoreFoundation.framework

Optional:
- Sparkle.framework (auto-update)
```

**Build Configuration**:
```yaml
Target: Notepad++
Type: Application
Language: Objective-C++
C++ Standard: C++20
Bundle Identifier: org.notepad-plus-plus
Code Signing: Development Team / Developer ID

Build Phases:
1. Compile Scintilla.framework
2. Compile Lexilla.framework  
3. Compile Notepad++ sources
4. Copy frameworks to app bundle
5. Copy resources (configs, themes, etc.)
6. Code sign
```

### Alternative: CMake (Future)

```cmake
# macOS-specific additions to CMakeLists.txt
if(APPLE)
    set(CMAKE_OSX_DEPLOYMENT_TARGET "10.15")
    
    find_library(APPKIT AppKit)
    find_library(FOUNDATION Foundation)
    
    add_executable(Notepad++ MACOSX_BUNDLE
        ${COMMON_SOURCES}
        ${MACOS_SOURCES}
    )
    
    target_link_libraries(Notepad++
        Scintilla
        Lexilla
        ${APPKIT}
        ${FOUNDATION}
    )
    
    set_target_properties(Notepad++ PROPERTIES
        MACOSX_BUNDLE_INFO_PLIST "${CMAKE_SOURCE_DIR}/Info.plist.in"
        MACOSX_BUNDLE_BUNDLE_NAME "Notepad++"
        MACOSX_BUNDLE_GUI_IDENTIFIER "org.notepad-plus-plus"
    )
endif()
```

---

## Testing Strategy

### Unit Tests
- [ ] Core logic tests (encoding, buffer management)
- [ ] File I/O abstraction tests
- [ ] Configuration persistence tests
- [ ] XCTest framework integration

### Integration Tests  
- [ ] Scintilla integration
- [ ] Multi-document management
- [ ] Plugin loading
- [ ] Search/replace functionality

### Manual Testing Checklist
- [ ] Open/save various file types
- [ ] Syntax highlighting for major languages
- [ ] Large file handling (100MB+)
- [ ] Multiple windows/tabs
- [ ] Split view operations
- [ ] Find/replace with regex
- [ ] Encoding conversions
- [ ] Dark mode switching
- [ ] Keyboard shortcuts
- [ ] Accessibility (VoiceOver)

---

## Plugin Compatibility

### Strategy

**Phase 1**: No plugin support (MVP)
**Phase 2**: Adapter layer for Windows plugins
**Phase 3**: Native macOS plugins

### Plugin Adapter Layer

Create compatibility layer:
```cpp
// PluginAdapterMacOS.h
class PluginAdapterMacOS {
public:
    // Translate Windows messages to macOS notifications
    void sendMessage(int msgId, WPARAM w, LPARAM l);
    
    // Emulate HWND for plugins
    HWND getFakeHWND();
    
    // Map plugin menu items to NSMenuItem
    void registerMenuItem(const char* name, PFUNCPLUGINCMD func);
};
```

Most popular plugins will need macOS-specific builds:
- NppExplorer → Use native file browser
- Compare → May work with adapter
- XML Tools → Should work (text processing)

---

## Key Technical Decisions

### 1. Language Choice

**Recommendation**: Objective-C++ (Obj-C++ = .mm files)

**Rationale**:
- ✅ Can directly include existing C++ code
- ✅ No need to rewrite core logic
- ✅ Full AppKit access
- ❌ Swift interop possible but adds complexity

**Example**:
```objc
// MainWindow.mm
#import "MainWindow.h"
#include "Notepad_plus.h"  // Existing C++ class

@implementation MainWindow {
    Notepad_plus* _nppCore;  // C++ instance
}

- (void)openFile:(NSString*)path {
    // Convert NSString to std::wstring
    std::wstring wpath = [path UTF8String];
    _nppCore->doOpen(wpath.c_str());
}
@end
```

### 2. UI Framework

**Recommendation**: Native AppKit

**Alternatives Considered**:
- ❌ Qt: Adds 100MB+ dependency, different look/feel
- ❌ Electron: Poor performance, huge size
- ❌ wxWidgets: Outdated macOS support
- ✅ SwiftUI: Only for new panels (mixed approach)

### 3. Plugin System

**Recommendation**: Start with .dylib + adapter, migrate to .bundle

**Implementation**:
```objc
// Phase 1: dylib with adapter
NSBundle* bundle = [NSBundle bundleWithPath:pluginPath];
PluginInterface* plugin = [bundle principalClass];

// Phase 2: Native macOS plugins
id<NotepadPlugin> plugin = [[bundle principalClass] alloc] init];
[plugin load:self.api];
```

### 4. Configuration

**Recommendation**: Hybrid (plist + XML)

```
User Defaults (plist): UI state, window positions
XML Files: Language definitions, styles, keymaps (maintain compatibility)
```

---

## Risk Mitigation

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| WinControls porting takes longer than estimated | High | High | Prioritize critical controls, use standard AppKit where possible |
| Plugin compatibility issues | High | Medium | Phase plugin support, provide migration guide |
| Performance regressions | Medium | Medium | Profile early, optimize critical paths |
| Scintilla Cocoa bugs | Low | High | Community is active, fork if needed |
| App Store restrictions | Medium | Low | Plan for both standalone and App Store builds |

---

## Success Criteria

### MVP (Phase 1)
- ✅ Opens and edits text files
- ✅ Syntax highlighting works
- ✅ Save/Save As functionality
- ✅ Basic find/replace
- ✅ Runs on macOS 10.15+

### Feature Complete (Phase 3)
- ✅ All core Notepad++ features working
- ✅ Multi-document interface
- ✅ Basic plugin support
- ✅ Preferences saved/loaded
- ✅ Auto-update mechanism

### Production Ready (Phase 4)
- ✅ macOS HIG compliant
- ✅ Notarized and code signed
- ✅ Accessible (VoiceOver tested)
- ✅ Installer package (.dmg)
- ✅ Documentation complete

---

## Resources Required

### Development Team
- 2-3 macOS developers (Objective-C++ experience)
- 1 UI/UX designer (macOS HIG knowledge)
- 1 QA engineer

### Infrastructure
- Apple Developer Program membership ($99/year)
- Code signing certificate
- Notarization setup
- CI/CD (GitHub Actions with macOS runner)

### Timeline
- Phase 1: 3-4 weeks
- Phase 2: 4-5 weeks  
- Phase 3: 3-4 weeks
- Phase 4: 2-3 weeks
- **Total: 12-16 weeks**

---

## Next Steps

### Immediate Actions (Week 1)

1. **Set up development environment**
   ```bash
   # Clone and explore
   cd scintilla/cocoa
   xcodebuild -project Scintilla.xcodeproj -scheme Scintilla build
   
   cd ../../lexilla/src/Lexilla
   xcodebuild -project Lexilla.xcodeproj -scheme Lexilla build
   ```

2. **Create initial Xcode project**
   - Application template
   - Configure bundle identifier
   - Add Info.plist
   - Import Scintilla/Lexilla frameworks

3. **Proof of concept**
   - Create main window
   - Embed ScintillaView
   - Open/save single file
   - Verify syntax highlighting

4. **Set up CI/CD**
   - GitHub Actions workflow for macOS
   - Automated builds
   - Unit test runner

### References
- [Scintilla Documentation](https://www.scintilla.org/ScintillaDoc.html)
- [AppKit Programming Guide](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/AppKit_Framework/)
- [macOS Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/macos)
- [Code Signing Guide](https://developer.apple.com/support/code-signing/)

---

## Conclusion

Porting Notepad++ to macOS is **feasible and well-scoped** due to:
1. ✅ Existing mature Scintilla Cocoa implementation
2. ✅ Modular architecture (editor separate from UI)
3. ✅ XML-based configuration (not registry-dependent)

**Main effort** is in replacing 30+ Windows controls with AppKit equivalents and adapting the plugin system.

**Recommended approach**: Phased implementation starting with MVP, progressively adding features while maintaining code quality and macOS native feel.

**Estimated delivery**: 12-16 weeks for production-ready application.
