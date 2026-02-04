# Notepad++ macOS Port - TODO Checklist

This document provides an actionable checklist for porting Notepad++ to macOS. Items are organized by priority and phase.

## Legend
- 🔴 **Critical** - Must have for MVP
- 🟡 **High Priority** - Needed for feature complete version
- 🟢 **Medium Priority** - Important but not blocking
- ⚪ **Low Priority** - Nice to have

---

## Phase 1: Minimal Viable Product (MVP)

### Project Setup
- [ ] 🔴 Create Xcode workspace for Notepad++ macOS
- [ ] 🔴 Set up application bundle structure
  - [ ] Create Info.plist with proper bundle identifier
  - [ ] Add application icon (convert from Windows .ico)
  - [ ] Configure document types (text files, code files)
  - [ ] Set up version info
  - [ ] **Configure file type associations (UTIs)**
  - [ ] **Add Services definitions**
- [ ] 🔴 Configure build system
  - [ ] Link Scintilla.framework (from scintilla/cocoa)
  - [ ] Link Lexilla.framework (from lexilla/src/Lexilla)
  - [ ] Set deployment target (macOS 10.15+)
  - [ ] Configure code signing
- [ ] 🔴 Create basic project structure
  ```
  PowerEditor/cocoa/
  ├── AppDelegate.h/mm
  ├── MainWindow.h/mm
  ├── DocumentController.h/mm
  ├── Platform/
  ├── Controls/
  └── Resources/
  ```

### Core Application
- [ ] 🔴 Implement NSApplicationDelegate
  - [ ] Application lifecycle (launch, terminate)
  - [ ] Handle "Open File" events
  - [ ] Menu bar setup
  - [ ] About window
- [ ] 🔴 Create main window controller
  - [ ] NSWindowController + NSWindow
  - [ ] Toolbar (basic)
  - [ ] Status bar (basic)
  - [ ] Content view for Scintilla
- [ ] 🔴 Integrate ScintillaView
  - [ ] Embed ScintillaView in main window
  - [ ] Configure initial settings
  - [ ] Connect keyboard shortcuts
  - [ ] Handle focus management

### File Operations
- [ ] 🔴 File I/O abstraction layer
  - [ ] FileManager class (wraps NSFileManager)
  - [ ] Encoding detection (port from Windows code)
  - [ ] Read file with encoding
  - [ ] Write file with encoding
  - [ ] Handle BOM markers
- [ ] 🔴 Open File functionality
  - [ ] NSOpenPanel integration
  - [ ] Support multiple file selection
  - [ ] Recent files menu
  - [ ] Drag & drop to window
- [ ] 🔴 Save File functionality
  - [ ] NSSavePanel integration
  - [ ] Save As dialog
  - [ ] Auto-save support
  - [ ] Dirty flag management
- [ ] 🔴 Recent files list
  - [ ] Store in NSUserDefaults
  - [ ] Menu integration
  - [ ] Clear recent files

### Essential Editing
- [ ] 🔴 Clipboard operations
  - [ ] Cut (Cmd+X)
  - [ ] Copy (Cmd+C)
  - [ ] Paste (Cmd+V)
  - [ ] Copy with formatting
- [ ] 🔴 Undo/Redo
  - [ ] Undo (Cmd+Z)
  - [ ] Redo (Cmd+Shift+Z)
  - [ ] Verify Scintilla undo stack works
- [ ] 🔴 Basic text operations
  - [ ] Select All (Cmd+A)
  - [ ] Delete selection
  - [ ] Duplicate line (Cmd+D)
- [ ] 🔴 Find functionality (basic)
  - [ ] Find dialog (NSPanel)
  - [ ] Find next/previous
  - [ ] Case sensitive toggle
  - [ ] Wrap around toggle

### Menu System
- [ ] 🔴 File menu
  - [ ] New (Cmd+N)
  - [ ] Open (Cmd+O)
  - [ ] Save (Cmd+S)
  - [ ] Save As (Cmd+Shift+S)
  - [ ] Close (Cmd+W)
  - [ ] Quit (Cmd+Q)
- [ ] 🔴 Edit menu
  - [ ] Undo/Redo
  - [ ] Cut/Copy/Paste
  - [ ] Select All
  - [ ] Find/Replace
- [ ] 🔴 View menu
  - [ ] Show/Hide Toolbar
  - [ ] Show/Hide Status Bar
  - [ ] Zoom In/Out (Cmd++/Cmd+-)

### Preferences (Basic)
- [ ] 🔴 Create ConfigManager
  - [ ] Read/write NSUserDefaults
  - [ ] Load XML configs (langs.xml, stylers.xml)
  - [ ] Path: ~/Library/Application Support/Notepad++/
- [ ] 🔴 Basic preferences window
  - [ ] Font selection
  - [ ] Tab settings (size, spaces vs tabs)
  - [ ] Show line numbers
  - [ ] Word wrap

### Shell Integration (Phase 1)
- [ ] 🔴 **File Type Associations (Info.plist)**
  - [ ] Define CFBundleDocumentTypes for all supported extensions
  - [ ] Add UTExportedTypeDeclarations for custom types
  - [ ] Test "Open with" menu shows Notepad++
  - [ ] Support 100+ extensions from Windows version
- [ ] 🔴 **macOS Services**
  - [ ] Implement "Open in Notepad++" service
  - [ ] Implement "Open Selection in Notepad++" service
  - [ ] Add service handlers to AppDelegate
  - [ ] Test from Finder and other apps

### Testing & Validation
- [ ] 🔴 Test basic workflow
  - [ ] Launch application
  - [ ] Open .txt file
  - [ ] Edit and save
  - [ ] Close and reopen
  - [ ] Verify encoding preservation
- [ ] 🔴 Test keyboard shortcuts
  - [ ] All Cmd-based shortcuts work
  - [ ] Text navigation (arrow keys, page up/down)
  - [ ] Selection shortcuts
- [ ] 🔴 Test file formats
  - [ ] UTF-8, UTF-16, ASCII
  - [ ] Unix (LF), Windows (CRLF), Mac (CR)
  - [ ] Large files (1MB+)

**Phase 1 Success Criteria**: Can open, edit, save text files with basic editing features.

---

## Phase 2: Multi-Document & Core UI

### Tab Bar / Multi-Document
- [ ] 🔴 Tab bar implementation
  - [ ] NSTabView or custom tab view
  - [ ] Create tab for each document
  - [ ] Switch between tabs (Cmd+1-9, Cmd+[/])
  - [ ] Close tab (Cmd+W)
  - [ ] Tab context menu (close, close others, close all)
- [ ] 🔴 Document management
  - [ ] DocumentController class
  - [ ] Track multiple documents
  - [ ] Switch active document
  - [ ] Save all documents
  - [ ] Close all tabs prompt
- [ ] 🟡 Tab features
  - [ ] Drag & drop reordering
  - [ ] Color indicator (modified, read-only)
  - [ ] Double-click to close
  - [ ] Right-click menu

### Split View
- [ ] 🔴 Split view implementation
  - [ ] NSSplitView horizontal/vertical
  - [ ] Split current document
  - [ ] Clone document to split
  - [ ] Close split
- [ ] 🟡 Synchronized scrolling
  - [ ] Option to sync scroll position
  - [ ] Line alignment

### Advanced Search
- [ ] 🔴 Enhanced Find dialog
  - [ ] Find/Replace modes
  - [ ] Regular expression toggle
  - [ ] Match case / whole word
  - [ ] Search direction
  - [ ] Incremental search
- [ ] 🟡 Find in Files
  - [ ] Directory picker
  - [ ] File filter (*.cpp, *.h, etc.)
  - [ ] Results panel (NSTableView)
  - [ ] Double-click to open result
- [ ] 🟡 Bookmarks
  - [ ] Toggle bookmark (Cmd+F2)
  - [ ] Next/previous bookmark
  - [ ] Clear all bookmarks
  - [ ] Bookmark margin indicator
- [ ] 🟡 Mark all
  - [ ] Mark all matches
  - [ ] Clear marks
  - [ ] Style configuration

### Status Bar (Enhanced)
- [ ] 🔴 Status bar components
  - [ ] Line:Column position
  - [ ] Selection length
  - [ ] Document length
  - [ ] Encoding indicator/selector
  - [ ] EOL format indicator/selector
  - [ ] Language/syntax selector
  - [ ] Typing mode (Insert/Overwrite)

### Toolbar (Enhanced)  
- [ ] 🔴 NSToolbar with items
  - [ ] New, Open, Save
  - [ ] Cut, Copy, Paste
  - [ ] Undo, Redo
  - [ ] Find
- [ ] 🟡 Toolbar customization
  - [ ] Right-click "Customize Toolbar"
  - [ ] Drag items to add/remove
  - [ ] Save configuration

### Language & Syntax
- [ ] 🔴 Language support
  - [ ] Load langs.xml
  - [ ] Parse language definitions
  - [ ] Apply to Lexilla
  - [ ] Language menu in status bar
- [ ] 🔴 Syntax highlighting
  - [ ] Load stylers.xml
  - [ ] Apply styles via Scintilla
  - [ ] Theme support (light/dark)
  - [ ] Custom color configuration
- [ ] 🟡 Auto-completion (basic)
  - [ ] Word completion
  - [ ] Function completion (if available)
  - [ ] Trigger on Ctrl+Space

### Session Management
- [ ] 🟡 Save session on quit
  - [ ] Remember open files
  - [ ] Remember cursor positions
  - [ ] Remember window position/size
- [ ] 🟡 Restore session on launch
  - [ ] Reopen files
  - [ ] Restore tabs
  - [ ] Restore cursor positions

### Testing & Validation
- [ ] 🔴 Test multi-document workflow
  - [ ] Open 10+ files
  - [ ] Switch between tabs
  - [ ] Save all
  - [ ] Close all
- [ ] 🔴 Test split view
  - [ ] Split horizontally/vertically
  - [ ] Edit in both panes
  - [ ] Synchronized scrolling
- [ ] 🟡 Test search functionality
  - [ ] Regular expressions
  - [ ] Find in Files
  - [ ] Bookmarks

**Phase 2 Success Criteria**: Multi-tab editor with full search/replace and split view.

---

## Phase 3: Advanced Features & System Integration

### Advanced Panels (Docking)
- [ ] 🟡 Docking system infrastructure
  - [ ] NSSplitView-based docking
  - [ ] Floating panels (NSPanel)
  - [ ] Show/hide panels
  - [ ] Remember panel states
- [ ] 🟡 Function List panel
  - [ ] Parse functions via ctags or regex
  - [ ] NSOutlineView display
  - [ ] Jump to function on click
  - [ ] Update on file change
- [ ] 🟡 Document Map (minimap)
  - [ ] Render miniature view of document
  - [ ] Scroll synchronization
  - [ ] Click to jump
  - [ ] Visible area indicator
- [ ] 🟡 Folder as Workspace
  - [ ] NSOutlineView file tree
  - [ ] Open folder dialog
  - [ ] Watch for file changes (FSEvents)
  - [ ] Open file on double-click
- [ ] 🟢 Clipboard History
  - [ ] Track clipboard history
  - [ ] Panel to view history
  - [ ] Paste from history
- [ ] ⚪ Document Snapshot
  - [ ] Before/after comparison view
  - [ ] Diff highlighting

### Advanced Preferences
- [ ] 🟡 Multi-page preferences window
  - [ ] NSTabView with categories
  - [ ] General settings
  - [ ] Editing settings
  - [ ] New Document settings
  - [ ] File Association
  - [ ] Language settings
  - [ ] Highlighting settings
  - [ ] Backup settings
  - [ ] Auto-completion settings
  - [ ] Multi-Instance settings
- [ ] 🟡 Style Configurator
  - [ ] Select language
  - [ ] Configure colors for each element
  - [ ] Font selection per element
  - [ ] Save custom themes
  - [ ] Import/export themes
- [ ] 🟡 Shortcut Mapper
  - [ ] NSTableView with all commands
  - [ ] Modify shortcuts
  - [ ] Detect conflicts
  - [ ] Save to shortcuts.xml
  - [ ] Reset to defaults

### Plugin System
- [ ] 🟡 Plugin infrastructure
  - [ ] PluginLoader class
  - [ ] Load .dylib from ~/Library/.../plugins/
  - [ ] Verify code signature
  - [ ] Plugin initialization
  - [ ] Plugin unloading
- [ ] 🟡 Plugin API adapter
  - [ ] Translate Windows messages to macOS
  - [ ] Fake HWND implementation
  - [ ] Scintilla access for plugins
  - [ ] Plugin menu integration
- [ ] 🟡 Plugin Manager UI
  - [ ] List installed plugins
  - [ ] Enable/disable plugins
  - [ ] Install new plugins (manual)
  - [ ] Update plugins (future)
- [ ] 🟢 Plugin Admin (download)
  - [ ] Download plugin list from server
  - [ ] Browse available plugins
  - [ ] Install with one click
  - [ ] Update notifications

### Printing
- [ ] 🟢 Print support
  - [ ] NSPrintOperation setup
  - [ ] Print current document
  - [ ] Print with syntax highlighting
  - [ ] Line numbers in print
- [ ] 🟢 Page Setup
  - [ ] Configure margins
  - [ ] Page orientation
  - [ ] Header/footer
- [ ] 🟢 Print Preview
  - [ ] Show preview window
  - [ ] Multiple pages
  - [ ] Zoom in/out

### Auto-Update
- [ ] 🟡 Sparkle framework integration
  - [ ] Add Sparkle to project
  - [ ] Configure appcast URL
  - [ ] Automatic update checking
  - [ ] Manual "Check for Updates"
- [ ] 🟡 Release notes
  - [ ] Display changelog
  - [ ] Markdown rendering
- [ ] 🟡 Delta updates
  - [ ] Binary diff updates (smaller downloads)

### macOS Integration
- [ ] 🟡 File associations
  - [ ] Register in Info.plist
  - [ ] Handle "Open With"
  - [ ] Set as default editor for types
- [ ] 🟡 **File Associations UI (Preferences Panel)**
  - [ ] FileAssociationsController class
  - [ ] Show list of supported extensions
  - [ ] Check if Notepad++ is default for each type
  - [ ] Button to open System Preferences with instructions
  - [ ] Visual indicators (✓ for registered, ✗ for not)
- [ ] 🟢 **Quick Action Extension (macOS 10.14+)**
  - [ ] Create Finder Extension target in Xcode
  - [ ] Implement QuickActionHandler
  - [ ] Handle single and multiple file selection
  - [ ] Launch main app with files
  - [ ] Test in Finder toolbar and context menu
- [ ] 🟢 **Finder Sync Extension (Advanced)**
  - [ ] Create Finder Sync Extension target
  - [ ] Implement FinderSync class
  - [ ] Add "Open in Notepad++" menu item
  - [ ] Add "Open in New Window" menu item
  - [ ] Handle file/folder monitoring
  - [ ] Test context menu integration
- [ ] 🟢 macOS Services (already in Phase 1)
  - [ ] Verify "Open in Notepad++" service works
  - [ ] Verify "Open Selection in Notepad++" works
  - [ ] Test from multiple apps (Finder, Safari, Mail)
- [ ] 🟢 Finder integration documentation
  - [ ] User guide for enabling extensions
  - [ ] Screenshots of setup process
  - [ ] Troubleshooting guide
- [ ] ⚪ Spotlight indexing
  - [ ] Metadata importer
  - [ ] Index code files

### Testing & Validation
- [ ] 🟡 Test plugin system
  - [ ] Load sample plugin
  - [ ] Call plugin functions
  - [ ] Plugin menu appears
- [ ] 🟡 Test preferences
  - [ ] Change settings
  - [ ] Restart app
  - [ ] Verify persistence
- [ ] 🟢 Test printing
  - [ ] Print with syntax highlighting
  - [ ] Print to PDF
  - [ ] Page breaks correct
- [ ] 🟡 **Test shell integration**
  - [ ] File associations appear in "Open with"
  - [ ] Double-click registered file opens in Notepad++
  - [ ] Services menu shows "Open in Notepad++"
  - [ ] Quick Action works from Finder
  - [ ] Finder Sync context menu appears
  - [ ] Test with 10+ different file types
  - [ ] Test with multiple file selection
  - [ ] Test "Open in New Window"

**Phase 3 Success Criteria**: Feature-complete with plugin support and advanced panels.

---

## Phase 4: Polish & Production Ready

### macOS Human Interface Guidelines (HIG)
- [ ] 🟡 UI review for HIG compliance
  - [ ] All controls use standard AppKit
  - [ ] Keyboard shortcuts follow macOS conventions (Cmd not Ctrl)
  - [ ] Menu structure matches macOS apps
  - [ ] Toolbar icons follow SF Symbols style
  - [ ] Alert dialogs use NSAlert
- [ ] 🟡 Keyboard shortcuts audit
  - [ ] Cmd+Q to quit (not Alt+F4)
  - [ ] Cmd+, for preferences
  - [ ] Cmd+H to hide window
  - [ ] Cmd+M to minimize
  - [ ] Standard text navigation (Option+Arrow, Cmd+Arrow)
- [ ] 🟢 Touch Bar support (optional)
  - [ ] Common actions in Touch Bar
  - [ ] Esc to close dialogs
  - [ ] Text formatting buttons
- [ ] 🟡 Dark Mode support
  - [ ] Test all UI in Dark Mode
  - [ ] Use semantic colors (NSColor.textColor, etc.)
  - [ ] Custom theme adjustments
  - [ ] Icons with light/dark variants
- [ ] 🟡 Accessibility (VoiceOver)
  - [ ] All controls have accessibility labels
  - [ ] Tab order is logical
  - [ ] VoiceOver testing
  - [ ] Keyboard-only navigation works

### Performance Optimization
- [ ] 🟡 Startup time optimization
  - [ ] Profile app launch
  - [ ] Lazy load plugins
  - [ ] Defer non-critical initialization
  - [ ] Target: < 1 second cold start
- [ ] 🟡 Large file handling
  - [ ] Test with 100MB+ files
  - [ ] Streaming file loading
  - [ ] Efficient scrolling
  - [ ] Memory profiling
- [ ] 🟡 Memory optimization
  - [ ] Profile with Instruments
  - [ ] Fix memory leaks
  - [ ] Optimize document caching
  - [ ] Target: < 100MB for typical use
- [ ] 🟢 Rendering optimization
  - [ ] Profile drawing with Instruments
  - [ ] Optimize Scintilla rendering
  - [ ] Reduce overdraw
  - [ ] Target: 60 FPS scrolling

### Localization
- [ ] 🟢 Extract strings to .strings files
  - [ ] Use NSLocalizedString everywhere
  - [ ] Create Base.lproj/Localizable.strings
  - [ ] Extract from XIB files
- [ ] 🟢 Support existing translations
  - [ ] Port translations from Windows version
  - [ ] Create language packs
  - [ ] Test RTL languages (Hebrew, Arabic)
- [ ] 🟢 Localization testing
  - [ ] Test 3-4 major languages
  - [ ] Verify UI layout with long strings
  - [ ] Test date/time formats

### Documentation
- [ ] 🟡 User documentation
  - [ ] Getting Started guide for macOS
  - [ ] Update keyboard shortcuts
  - [ ] macOS-specific features
  - [ ] FAQ for macOS users
- [ ] 🟡 Developer documentation
  - [ ] Build instructions (Xcode)
  - [ ] Architecture overview
  - [ ] Plugin development guide (macOS)
  - [ ] Contributing guidelines
- [ ] 🟢 Help system
  - [ ] In-app help
  - [ ] Context-sensitive help (F1)
  - [ ] Link to online docs

### Code Quality
- [ ] 🟡 Code review
  - [ ] Review all macOS-specific code
  - [ ] Consistent coding style
  - [ ] Remove debug code
  - [ ] Clean up TODOs
- [ ] 🟡 Unit tests
  - [ ] XCTest framework setup
  - [ ] Test FileManager abstraction
  - [ ] Test ConfigManager
  - [ ] Test PluginLoader
  - [ ] Target: 60%+ coverage for new code
- [ ] 🟢 Static analysis
  - [ ] Run Clang Static Analyzer
  - [ ] Fix all warnings
  - [ ] Enable -Wall -Wextra
- [ ] 🟢 Memory testing
  - [ ] Run with Address Sanitizer
  - [ ] Run with Leak Sanitizer
  - [ ] Fix all issues

### Distribution & Release
- [ ] 🔴 Code signing
  - [ ] Apple Developer account
  - [ ] Developer ID Application certificate
  - [ ] Sign all executables and frameworks
  - [ ] **Sign all extensions (Quick Action, Finder Sync)**
  - [ ] Enable Hardened Runtime
- [ ] 🔴 Notarization
  - [ ] Submit to Apple for notarization
  - [ ] **Ensure all extensions pass notarization**
  - [ ] Staple notarization ticket
  - [ ] Verify with `spctl --assess`
- [ ] 🟡 Create .dmg installer
  - [ ] Custom background image
  - [ ] Applications folder symlink
  - [ ] Drag-to-install UX
  - [ ] **Include setup instructions for extensions**
  - [ ] EULA/License display
- [ ] 🟢 Homebrew formula
  - [ ] Create Cask for Homebrew
  - [ ] Submit to homebrew-cask
  - [ ] Test installation via brew
- [ ] ⚪ Mac App Store (optional)
  - [ ] App Sandbox entitlements
  - [ ] Remove unsupported features
  - [ ] Submit for review
  - [ ] Handle rejection feedback

### CI/CD
- [ ] 🟡 GitHub Actions workflow
  - [ ] macOS runner
  - [ ] Build on push
  - [ ] Run tests
  - [ ] Create artifacts
- [ ] 🟡 Automated testing
  - [ ] Unit tests in CI
  - [ ] UI tests (XCUITest)
  - [ ] Code coverage reports
- [ ] 🟢 Release automation
  - [ ] Tag triggers release build
  - [ ] Automatic notarization
  - [ ] Upload to GitHub Releases
  - [ ] Generate release notes

### Final Testing
- [ ] 🔴 Smoke testing
  - [ ] Fresh install on clean Mac
  - [ ] Test all major features
  - [ ] No crashes or hangs
- [ ] 🔴 Compatibility testing
  - [ ] macOS 10.15 (Catalina)
  - [ ] macOS 11 (Big Sur)
  - [ ] macOS 12 (Monterey)
  - [ ] macOS 13 (Ventura)
  - [ ] macOS 14 (Sonoma)
- [ ] 🟡 Hardware testing
  - [ ] Intel Mac
  - [ ] Apple Silicon Mac (M1/M2/M3)
  - [ ] Different screen sizes/resolutions
  - [ ] Retina and non-Retina displays
- [ ] 🟡 Edge case testing
  - [ ] 1000+ open tabs
  - [ ] Very long lines (10,000+ chars)
  - [ ] Files with millions of lines
  - [ ] All supported encodings
  - [ ] Files with mixed line endings
- [ ] 🟢 Beta testing
  - [ ] Release beta to community
  - [ ] Collect feedback
  - [ ] Fix reported issues
  - [ ] Iterate based on feedback

**Phase 4 Success Criteria**: Production-ready, notarized, HIG-compliant application ready for distribution.

---

## Post-Launch (Ongoing)

### Community & Support
- [ ] ⚪ Forum/discussion board
- [ ] ⚪ Bug tracking (GitHub Issues)
- [ ] ⚪ Feature requests
- [ ] ⚪ Discord/Slack community

### Maintenance
- [ ] ⚪ Monitor crash reports
- [ ] ⚪ Regular updates (security, bug fixes)
- [ ] ⚪ macOS version compatibility
- [ ] ⚪ Xcode updates

### Future Enhancements
- [ ] ⚪ SwiftUI for modern panels
- [ ] ⚪ Metal rendering (performance)
- [ ] ⚪ Universal Control support
- [ ] ⚪ Continuity features (Handoff)
- [ ] ⚪ iCloud sync (optional)
- [ ] ⚪ iOS/iPadOS version (long-term)

---

## Priority Summary

### Must-Have (MVP) - 🔴
- Basic editor (open/edit/save)
- Single window with tabs
- Find/Replace
- Syntax highlighting
- Standard menus

### Feature Complete - 🟡  
- Multi-document interface
- Split view
- Advanced search
- Plugin support
- Preferences system
- Auto-update

### Production Ready - 🟡
- HIG compliance
- Performance optimization
- Code signing & notarization
- Documentation
- Distribution package

### Nice-to-Have - 🟢⚪
- Advanced panels
- Printing
- Localization
- Mac App Store
- Community features

---

## Estimated Time Breakdown

| Phase | Duration | Effort (person-weeks) |
|-------|----------|---------------------|
| Phase 1 (MVP) | 3-4 weeks | 6-8 weeks |
| Phase 2 (Core UI) | 4-5 weeks | 8-10 weeks |
| Phase 3 (Advanced) | 3-4 weeks | 6-8 weeks |
| Phase 4 (Polish) | 2-3 weeks | 4-6 weeks |
| **Total** | **12-16 weeks** | **24-32 weeks** |

*Assumes 2-3 developers working in parallel*

---

## Quick Start for Developers

To start working on this port:

1. **Build Scintilla framework**
   ```bash
   cd scintilla/cocoa
   xcodebuild -project Scintilla.xcodeproj -scheme Scintilla
   ```

2. **Build Lexilla framework**
   ```bash
   cd lexilla/src/Lexilla
   xcodebuild -project Lexilla.xcodeproj -scheme Lexilla
   ```

3. **Create Xcode project for Notepad++**
   - File > New > Project > macOS > App
   - Add Scintilla.framework and Lexilla.framework
   - Start implementing AppDelegate

4. **First milestone**: Open a text file in ScintillaView

See `macOS_PORT_PLAN.md` for detailed architecture and technical decisions.
