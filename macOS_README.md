# Notepad++ for macOS - Project Documentation

This repository contains planning documentation for porting Notepad++ to macOS. The analysis shows this is a **feasible project** thanks to the existing mature Scintilla Cocoa implementation.

## 📚 Documentation Overview

### 1. [macOS Port Plan](macOS_PORT_PLAN.md) - **START HERE**
**Comprehensive technical plan covering the entire port**

- Executive summary and feasibility assessment
- Current state analysis (what works, what needs porting)
- Detailed Windows API dependencies
- 4-phase implementation roadmap
- Architecture recommendations
- Technical decisions and rationale
- Risk mitigation strategies
- Success criteria

**Key Finding**: Estimated 12-16 weeks with 2-4 developers

---

### 2. [TODO Checklist](macOS_TODO.md)
**Actionable task list organized by phase and priority**

Four phases with detailed checklists:
- **Phase 1**: Minimal Viable Product (MVP)
- **Phase 2**: Multi-Document & Core UI  
- **Phase 3**: Advanced Features & System Integration
- **Phase 4**: Polish & Production Ready

Each task marked by priority:
- 🔴 Critical - Must have for MVP
- 🟡 High Priority - Feature complete
- 🟢 Medium Priority - Important but not blocking
- ⚪ Low Priority - Nice to have

---

### 3. [Quick Start Guide](macOS_QUICKSTART.md)
**Get started in 5 minutes**

- Prerequisites and setup
- Building Scintilla framework
- Building Lexilla framework
- Creating your first macOS Notepad++ window
- Step-by-step Phase 1 implementation
- Code examples and snippets
- Common challenges and solutions
- Testing checklist

**Perfect for developers new to the project**

---

### 4. [Shell Integration Design](macOS_SHELL_INTEGRATION.md) ⭐ NEW
**macOS equivalents for Windows registry shell integrations**

Comprehensive design for system integration:
- **File Type Associations** - Info.plist configuration
- **macOS Services** - "Open in Notepad++" in Services menu
- **Quick Action Extension** - Finder toolbar integration
- **Finder Sync Extension** - Context menu (like Windows NppShell.dll)

Includes:
- Complete implementation examples
- Code samples (Objective-C++)
- Security considerations (entitlements, code signing)
- User experience flows
- Testing checklists
- Comparison with Windows implementation

---

## 🎯 Project Status

### ✅ Completed
- [x] Repository analysis
- [x] Windows dependency mapping
- [x] Scintilla Cocoa verification (mature, complete)
- [x] Architecture design
- [x] Implementation plan
- [x] Shell integration design
- [x] Developer documentation

### 🚧 Not Started
- [ ] Xcode project creation
- [ ] Code implementation
- [ ] UI controls porting
- [ ] Plugin system
- [ ] Testing
- [ ] Distribution

---

## 🔑 Key Findings

### ✅ What Makes This Feasible

1. **Scintilla Already Has Cocoa Support**
   - Complete implementation in `scintilla/cocoa/`
   - 850+ lines of battle-tested code
   - Includes: text rendering, syntax highlighting, auto-completion
   - Build systems ready (Xcode projects exist)

2. **Modular Architecture**
   - Editor component (Scintilla) separate from UI
   - 30+ WinControls isolated in `PowerEditor/src/WinControls/`
   - Configuration in XML (not registry-dependent)

3. **Cross-Platform Libraries**
   - Boost.Regex (not Win32 regex)
   - pugixml, TinyXML (cross-platform)
   - uchardet for encoding detection

### ⚠️ Main Challenges

1. **30+ Windows Controls Need Replacement**
   - TabBar, ToolBar, TreeView, ListView, etc.
   - Each needs AppKit equivalent
   - Estimated: 4-6 weeks of work

2. **Plugin System Incompatibility**
   - Windows DLL → macOS dylib/bundle
   - HWND-based messaging → macOS notifications
   - Requires complete rewrite

3. **Different System Integration**
   - Registry → Info.plist + NSUserDefaults
   - NppShell.dll → Finder extensions
   - Windows APIs → Foundation/AppKit

---

## 📊 Effort Estimate

| Phase | Duration | Tasks |
|-------|----------|-------|
| Phase 1: MVP | 3-4 weeks | Basic editor, file ops |
| Phase 2: Core UI | 4-5 weeks | Multi-tab, search, split view |
| Phase 3: Advanced | 3-4 weeks | Plugins, panels, integration |
| Phase 4: Polish | 2-3 weeks | HIG compliance, performance |
| **Total** | **12-16 weeks** | **Production-ready app** |

*Assumes 2-3 developers working in parallel*

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────┐
│   Notepad++ macOS Application (AppKit)     │
│   PowerEditor/cocoa/                        │
├─────────────────────────────────────────────┤
│   Platform Abstraction Layer (NEW)         │
│   - File I/O, Config, Plugins              │
├─────────────────────────────────────────────┤
│   Notepad++ Core (C++ - Reuse)             │
│   PowerEditor/src/                          │
├─────────────────────────────────────────────┤
│   ScintillaComponent (Minor changes)        │
├─────────────────────────────────────────────┤
│   Scintilla Cocoa (No changes needed) ✅   │
│   scintilla/cocoa/                          │
└─────────────────────────────────────────────┘
```

---

## 🚀 Getting Started

### For Project Managers
1. Read [macOS_PORT_PLAN.md](macOS_PORT_PLAN.md) - Full strategic overview
2. Review [macOS_TODO.md](macOS_TODO.md) - Task breakdown
3. Assess resources and timeline

### For Developers
1. Read [macOS_QUICKSTART.md](macOS_QUICKSTART.md) - Hands-on guide
2. Build Scintilla framework (5 minutes)
3. Create first prototype (1-2 days)
4. Refer to [macOS_TODO.md](macOS_TODO.md) for task list

### For Contributors
1. Familiarize with all documentation
2. Choose a component to port (see TODO)
3. Follow AppKit best practices
4. Submit PRs with tests

---

## 📋 Requirements

### Development Environment
- macOS 11.0+ (Big Sur or later)
- Xcode 13.0+ (latest recommended)
- Command Line Tools
- Apple Developer Program (for distribution)

### Target Platform
- **Deployment Target**: macOS 10.15 (Catalina)
- **Tested on**: macOS 11, 12, 13, 14
- **Architecture**: Universal (Intel + Apple Silicon)

---

## 🔒 Security & Distribution

### Code Signing
- Developer ID Application certificate required
- Sign all executables, frameworks, and extensions
- Enable Hardened Runtime

### Notarization
- Required for distribution outside Mac App Store
- All components must pass notarization
- Automated via Xcode Cloud or CI/CD

### Sandboxing (Optional)
- Main app can be non-sandboxed for full file access
- Extensions must be sandboxed (required by system)
- Appropriate entitlements configured

---

## 🎨 macOS Integration Features

### File Associations
- 100+ file extensions supported (via Info.plist)
- Appears in "Open with" menu
- Can be set as default editor

### Context Menu Integration
Choose from multiple options:
1. **macOS Services** - Easiest to implement
2. **Quick Action** - Best UX (macOS 10.14+)
3. **Finder Sync** - Most Windows-like (requires user approval)

See [macOS_SHELL_INTEGRATION.md](macOS_SHELL_INTEGRATION.md) for details.

### Other Features
- Auto-update (Sparkle framework)
- Dark Mode support
- Accessibility (VoiceOver)
- Touch Bar (optional)
- Spotlight integration (optional)

---

## 📖 Related Resources

### Scintilla
- [Scintilla Documentation](https://www.scintilla.org/ScintillaDoc.html)
- [Scintilla Cocoa Usage](https://www.scintilla.org/ScintillaUsage.html)
- Existing code: `scintilla/cocoa/`

### macOS Development
- [AppKit Documentation](https://developer.apple.com/documentation/appkit)
- [macOS Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/macos)
- [Code Signing Guide](https://developer.apple.com/support/code-signing/)

### Notepad++
- [Notepad++ Official Site](https://notepad-plus-plus.org/)
- [Original Repository](https://github.com/notepad-plus-plus/notepad-plus-plus)
- [Community Forum](https://community.notepad-plus-plus.org/)

---

## 🤝 Contributing

Contributions welcome! Areas needing help:

1. **UI Controls** - Port WinControls to AppKit
2. **File I/O** - Platform abstraction layer
3. **Testing** - Unit tests, integration tests
4. **Documentation** - User guide, plugin dev guide
5. **Localization** - Translation support

Please follow:
- macOS Human Interface Guidelines
- Existing Notepad++ coding style
- Include tests with changes
- Update documentation

---

## 📝 License

Notepad++ is licensed under the GPL License. This documentation and any code created for the macOS port will follow the same license.

See [LICENSE](LICENSE) for details.

---

## 💬 Questions?

- Review the [macOS_PORT_PLAN.md](macOS_PORT_PLAN.md) for technical details
- Check [macOS_QUICKSTART.md](macOS_QUICKSTART.md) for implementation guidance
- See [macOS_TODO.md](macOS_TODO.md) for specific tasks
- Review [macOS_SHELL_INTEGRATION.md](macOS_SHELL_INTEGRATION.md) for system integration

---

## 🎯 Next Steps

1. **Review all documentation** (estimated: 2-3 hours)
2. **Set up development environment** (estimated: 30 minutes)
3. **Build Scintilla framework** (estimated: 5 minutes)
4. **Create proof of concept** (estimated: 1-2 days)
5. **Begin Phase 1 implementation** (estimated: 3-4 weeks)

The journey to bring Notepad++ to macOS starts here! 🚀

---

**Last Updated**: 2026-02-04  
**Version**: 1.0  
**Status**: Planning Complete, Implementation Pending
