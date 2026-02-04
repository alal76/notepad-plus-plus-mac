# Notepad++ macOS Architecture Diagrams

## System Architecture

```
┌────────────────────────────────────────────────────────────────┐
│                    macOS Application Layer                      │
│                                                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐        │
│  │  AppKit UI   │  │   Cocoa      │  │   System     │        │
│  │  Components  │  │  Services    │  │  Extensions  │        │
│  └──────────────┘  └──────────────┘  └──────────────┘        │
│         │                  │                  │                │
└─────────┼──────────────────┼──────────────────┼────────────────┘
          │                  │                  │
          ▼                  ▼                  ▼
┌────────────────────────────────────────────────────────────────┐
│              Platform Abstraction Layer (NEW)                   │
│                                                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐        │
│  │ FileManager  │  │ConfigManager │  │PluginLoader │        │
│  │   (macOS)    │  │   (macOS)    │  │   (macOS)    │        │
│  └──────────────┘  └──────────────┘  └──────────────┘        │
│         │                  │                  │                │
└─────────┼──────────────────┼──────────────────┼────────────────┘
          │                  │                  │
          ▼                  ▼                  ▼
┌────────────────────────────────────────────────────────────────┐
│           Notepad++ Core Logic (Cross-Platform C++)            │
│                                                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐        │
│  │    Buffer    │  │  Parameters  │  │   Encoding   │        │
│  │  Management  │  │    Config    │  │   Detection  │        │
│  └──────────────┘  └──────────────┘  └──────────────┘        │
│         │                  │                  │                │
└─────────┼──────────────────┼──────────────────┼────────────────┘
          │                  │                  │
          ▼                  ▼                  ▼
┌────────────────────────────────────────────────────────────────┐
│              ScintillaComponent (Thin Wrapper)                  │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │  ScintillaEditView (minimal changes for macOS)          │  │
│  └─────────────────────────────────────────────────────────┘  │
│         │                                                       │
└─────────┼───────────────────────────────────────────────────────┘
          │
          ▼
┌────────────────────────────────────────────────────────────────┐
│         Scintilla Cocoa (✅ Complete, No Changes Needed)       │
│                                                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐        │
│  │ScintillaCocoa│  │  PlatCocoa   │  │ScintillaView │        │
│  │              │  │              │  │              │        │
│  └──────────────┘  └──────────────┘  └──────────────┘        │
│         │                  │                  │                │
└─────────┼──────────────────┼──────────────────┼────────────────┘
          │                  │                  │
          ▼                  ▼                  ▼
┌────────────────────────────────────────────────────────────────┐
│                    Lexilla (Syntax Highlighting)                │
│                 ✅ Has Xcode Project, Ready to Use              │
└────────────────────────────────────────────────────────────────┘
```

---

## Windows vs macOS Component Mapping

```
WINDOWS                             macOS
─────────────────────────           ─────────────────────────

Window Management
├── HWND                       →    NSWindow*, NSView*
├── CreateWindow               →    [[NSWindow alloc] init...]
├── GetWindowLong              →    NSWindow properties
└── InvalidateRect             →    [view setNeedsDisplay:YES]

UI Controls (WinControls/)
├── TabBar                     →    NSTabView / NSTabbedWindow
├── ToolBar                    →    NSToolbar
├── StatusBar                  →    NSTextField (in bottom view)
├── ListView                   →    NSTableView
├── TreeView                   →    NSOutlineView
├── SplitterContainer          →    NSSplitView
├── DockingWnd                 →    NSSplitView + NSPanel
├── ColourPicker               →    NSColorPanel
└── StaticDialog               →    NSViewController + NSPanel

File Operations
├── CreateFile                 →    NSFileHandle, fopen
├── FindFirstFile              →    NSFileManager enumerator
├── ReadDirectoryChanges       →    FSEvents
└── GetModuleFileName          →    [[NSBundle mainBundle] path]

Configuration
├── Registry (HKEY_*)          →    NSUserDefaults + plist
├── RegOpenKey                 →    [[NSUserDefaults alloc] init]
└── RegSetValue                →    [defaults setObject:forKey:]

Plugins
├── LoadLibrary (DLL)          →    dlopen() / NSBundle (dylib)
├── GetProcAddress             →    dlsym() / [bundle load]
└── DLL exports                →    C interface or Obj-C protocol

System Integration
├── Shell Extension (DLL)      →    Finder Sync Extension
├── Registry Shell Keys        →    Info.plist + Extensions
└── Context Menu               →    Quick Action / Services

Paths
├── %AppData%                  →    ~/Library/Application Support/
├── Registry settings          →    ~/Library/Preferences/
└── Program Files              →    /Applications/
```

---

## Shell Integration Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    User Actions in Finder                    │
└─────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
┌───────────────┐    ┌───────────────┐    ┌───────────────┐
│  "Open With"  │    │   Services    │    │ Quick Action  │
│   (Default)   │    │    Menu       │    │  / Context    │
│               │    │               │    │     Menu      │
└───────────────┘    └───────────────┘    └───────────────┘
        │                     │                     │
        ▼                     ▼                     ▼
┌───────────────┐    ┌───────────────┐    ┌───────────────┐
│  Info.plist   │    │  AppDelegate  │    │  Extension    │
│  File Type    │    │   Service     │    │   Handler     │
│ Associations  │    │   Methods     │    │   (appex)     │
└───────────────┘    └───────────────┘    └───────────────┘
        │                     │                     │
        └─────────────────────┼─────────────────────┘
                              │
                              ▼
                    ┌───────────────────┐
                    │  Launch Notepad++ │
                    │    with file(s)   │
                    └───────────────────┘
                              │
                              ▼
                    ┌───────────────────┐
                    │ Open in ScintillaView │
                    └───────────────────┘
```

---

## File Type Association Flow

```
User Action: Right-click .txt file
              │
              ▼
      ┌───────────────┐
      │ Finder Reads  │
      │  Info.plist   │
      └───────────────┘
              │
              ▼
  ┌─────────────────────────┐
  │ CFBundleDocumentTypes   │
  │ lists supported types   │
  └─────────────────────────┘
              │
              ▼
  ┌─────────────────────────┐
  │ "Open with" shows       │
  │ Notepad++ as option     │
  └─────────────────────────┘
              │
              ▼ (user selects Notepad++)
  ┌─────────────────────────┐
  │ LaunchServices opens    │
  │ Notepad++.app with file │
  └─────────────────────────┘
              │
              ▼
  ┌─────────────────────────┐
  │ AppDelegate receives    │
  │ application:openFiles:  │
  └─────────────────────────┘
              │
              ▼
  ┌─────────────────────────┐
  │ Opens in ScintillaView  │
  └─────────────────────────┘
```

---

## Extension Architecture

```
Notepad++.app/
├── Contents/
    ├── MacOS/
    │   └── Notepad++                     ← Main executable
    │
    ├── Frameworks/
    │   ├── Scintilla.framework           ← Editor core
    │   └── Lexilla.framework             ← Syntax highlighting
    │
    ├── PlugIns/
    │   ├── NotepadQuickAction.appex      ← Quick Action extension
    │   │   ├── Contents/
    │   │       ├── MacOS/
    │   │       │   └── NotepadQuickAction
    │   │       └── Info.plist
    │   │
    │   └── NotepadFinderSync.appex       ← Finder Sync extension
    │       ├── Contents/
    │           ├── MacOS/
    │           │   └── NotepadFinderSync
    │           └── Info.plist
    │
    └── Resources/
        ├── Info.plist                    ← File associations, Services
        ├── Assets.xcassets/
        ├── langs.xml                     ← Language definitions
        ├── stylers.xml                   ← Syntax styles
        └── shortcuts.xml                 ← Keyboard shortcuts

Extensions Communication:
┌─────────────────┐         Apple Events        ┌──────────────┐
│ Quick Action    │ ───────────────────────────> │  Main App    │
│    .appex       │ <─────────────────────────── │              │
└─────────────────┘         File URLs           └──────────────┘
                                │
                                │ XPC
                                │
┌─────────────────┐             ▼                ┌──────────────┐
│ Finder Sync     │ ───────────────────────────> │  Main App    │
│    .appex       │                               │              │
└─────────────────┘                               └──────────────┘
```

---

## Multi-Document Architecture

```
┌──────────────────────────────────────────────────────────┐
│                   Main Window (NSWindow)                  │
│                                                           │
│  ┌────────────────────────────────────────────────────┐  │
│  │              Toolbar (NSToolbar)                    │  │
│  └────────────────────────────────────────────────────┘  │
│                                                           │
│  ┌────────────────────────────────────────────────────┐  │
│  │          Tab Bar (NSTabView)                       │  │
│  │  ┌────┐ ┌────┐ ┌────┐ ┌────┐                     │  │
│  │  │Tab1│ │Tab2│ │Tab3│ │ +  │                     │  │
│  │  └────┘ └────┘ └────┘ └────┘                     │  │
│  └────────────────────────────────────────────────────┘  │
│                                                           │
│  ┌────────────────────────────────────────────────────┐  │
│  │         Content Area (NSSplitView)                 │  │
│  │                                                     │  │
│  │  ┌─────────────────────┬──────────────────────┐   │  │
│  │  │  ScintillaView 1    │  ScintillaView 2     │   │  │
│  │  │  (Primary pane)     │  (Split pane)        │   │  │
│  │  │                     │  (optional)          │   │  │
│  │  │                     │                      │   │  │
│  │  │   [Editor content]  │  [Editor content]    │   │  │
│  │  │                     │                      │   │  │
│  │  └─────────────────────┴──────────────────────┘   │  │
│  └────────────────────────────────────────────────────┘  │
│                                                           │
│  ┌────────────────────────────────────────────────────┐  │
│  │         Status Bar (NSTextField)                    │  │
│  │  Line: 42 | Col: 10 | UTF-8 | LF | JavaScript     │  │
│  └────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────┘

Each Tab Contains:
├── Document Model (C++)
│   ├── Buffer*
│   ├── Encoding info
│   └── File path
│
└── ScintillaView (Cocoa)
    ├── Text content
    ├── Lexer state
    └── View state
```

---

## Plugin System Architecture

```
Plugin Discovery & Loading:

~/Library/Application Support/Notepad++/plugins/
├── PluginA.dylib
├── PluginB.dylib
└── PluginC.bundle/

                     │
                     ▼
          ┌──────────────────┐
          │  PluginLoader    │
          │   (Singleton)    │
          └──────────────────┘
                     │
        ┌────────────┼────────────┐
        │            │            │
        ▼            ▼            ▼
   ┌────────┐  ┌────────┐  ┌────────┐
   │ Plugin │  │ Plugin │  │ Plugin │
   │   A    │  │   B    │  │   C    │
   └────────┘  └────────┘  └────────┘
        │            │            │
        └────────────┼────────────┘
                     │
                     ▼
          ┌──────────────────┐
          │  Plugin API      │
          │  (Adapter Layer) │
          └──────────────────┘
                     │
        ┌────────────┼────────────┐
        │            │            │
        ▼            ▼            ▼
   ┌─────────┐ ┌─────────┐ ┌─────────┐
   │Scintilla│ │Document │ │  Menu   │
   │   API   │ │   API   │ │   API   │
   └─────────┘ └─────────┘ └─────────┘

Plugin Interface (dylib):
extern "C" {
    void    pluginInit();
    wchar_t* getName();
    void    beNotified(SCNotification* notif);
    void    setMenu(NSMenu* menu);
}
```

---

## Configuration Storage

```
Windows                          macOS
────────────────────            ──────────────────────────

Registry:                       NSUserDefaults (plist):
HKEY_CURRENT_USER/         →    ~/Library/Preferences/
  Software/                     org.notepad-plus-plus.plist
    Notepad++/                  ├── WindowFrame
      Settings                  ├── RecentFiles
                                ├── FontName
                                └── ...

Config Files:                   Config Files:
%AppData%/Notepad++/       →    ~/Library/Application Support/
  config.xml                    Notepad++/
  langs.xml                     ├── config.xml
  stylers.xml                   ├── langs.xml
  shortcuts.xml                 ├── stylers.xml
  session.xml                   ├── shortcuts.xml
  plugins/                      ├── session.xml
                                └── plugins/
```

---

## Data Flow: Opening a File

```
1. User Action
   │
   ├─→ Menu: File > Open
   ├─→ Drag & Drop
   ├─→ Recent Files
   ├─→ Double-click in Finder
   └─→ Context Menu (Quick Action)
           │
           ▼
2. AppDelegate receives event
   - (void)application:openFiles:
           │
           ▼
3. FileManager (Platform Layer)
   - Check file exists
   - Check read permissions
   - Detect encoding
           │
           ▼
4. Read file content
   - Use NSFileHandle or fopen
   - Read as NSData
   - Convert to string with encoding
           │
           ▼
5. Create/Update Document
   - Buffer* (C++ core)
   - Set encoding info
   - Set file path
           │
           ▼
6. Update UI
   - Create tab (if new)
   - Get ScintillaView
   - Set text content
           │
           ▼
7. Configure Editor
   - Detect language (from extension)
   - Load Lexer (Lexilla)
   - Apply styles (stylers.xml)
   - Set syntax highlighting
           │
           ▼
8. Update Window
   - Set window title (filename)
   - Update recent files menu
   - Update status bar
   - Update tab title
           │
           ▼
9. File ready for editing ✅
```

---

## Key Technologies

```
┌────────────────────────────────────────────────────────┐
│                  Technology Stack                       │
├────────────────────────────────────────────────────────┤
│ Language:        Objective-C++ (.mm files)             │
│ UI Framework:    AppKit                                │
│ Editor Core:     Scintilla Cocoa                       │
│ Build System:    Xcode                                 │
│ Min. OS:         macOS 10.15 (Catalina)                │
│ Target:          Universal (Intel + Apple Silicon)     │
│ Code Signing:    Developer ID / Mac App Store          │
│ Distribution:    .dmg, Homebrew, (optional) MAS        │
└────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────┐
│              External Dependencies                      │
├────────────────────────────────────────────────────────┤
│ Scintilla:       ✅ Included (scintilla/cocoa/)        │
│ Lexilla:         ✅ Included (lexilla/)                │
│ Boost.Regex:     ✅ Included (boostregex/)             │
│ pugixml:         ✅ Included (PowerEditor/src/)        │
│ uchardet:        ✅ Included (PowerEditor/src/)        │
│ Sparkle:         ⬜ Optional (auto-update)             │
└────────────────────────────────────────────────────────┘
```

---

## Summary

This architecture design shows:

1. **Clear separation** between platform-specific and cross-platform code
2. **Minimal changes** to existing Notepad++ C++ core
3. **Full leverage** of mature Scintilla Cocoa implementation
4. **Native macOS integration** via standard system APIs
5. **Security-first** approach with sandboxing and code signing
6. **Extensibility** through plugin system

The design follows macOS best practices while maintaining compatibility with Notepad++'s existing architecture.
