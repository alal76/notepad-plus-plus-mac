# Notepad++ for macOS

[![Original Repository](https://img.shields.io/badge/Original-notepad--plus--plus-blue)](https://github.com/notepad-plus-plus/notepad-plus-plus)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)

## About This Port

This is a **macOS port** of the legendary [Notepad++](https://notepad-plus-plus.org/) text editor, originally created by Don HO and the Notepad++ community. This port brings the powerful features of Notepad++ to macOS users while maintaining full compatibility with the original Windows version's core functionality.

**Original Notepad++** is a free (free as in both "free speech" and "free beer") source code editor and Notepad replacement that supports several programming languages and natural languages. Originally designed for the MS Windows environment, its use is governed by [GPL License](LICENSE).

### Attribution

- **Original Author**: Don HO (don.h@free.fr)
- **Original Project**: [notepad-plus-plus/notepad-plus-plus](https://github.com/notepad-plus-plus/notepad-plus-plus)
- **Official Site**: [notepad-plus-plus.org](https://notepad-plus-plus.org/)
- **License**: GNU General Public License v3.0 (see [LICENSE](LICENSE))
- **macOS Port**: This repository contains the macOS-specific implementation

All credits for the original Notepad++ design, features, and implementation belong to Don HO and the Notepad++ community. This macOS port is built upon their excellent work.

## What's Different in the macOS Port?

This macOS port provides:

- ✅ **Native macOS Experience**: Built with AppKit for native look and feel
- ✅ **Scintilla Editor**: Powered by the mature Scintilla Cocoa implementation
- ✅ **Syntax Highlighting**: Support for 100+ programming languages via Lexilla
- ✅ **File Associations**: Open files from Finder with Notepad++
- ✅ **macOS Services**: Right-click to "Open in Notepad++"
- ✅ **Universal Binary**: Supports both Intel and Apple Silicon Macs
- ⚠️ **Plugin System**: Under development (Windows plugins are not compatible)

## Quick Start

### One-Command Installation ⚡

Install Notepad++ with a single command (recommended):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/alal76/notepad-plus-plus-mac/main/quick-install.sh)
```

This command will automatically:
- ✅ Check system requirements
- ✅ Clone the repository
- ✅ Build all components (Scintilla, Lexilla, Notepad++)
- ✅ Create a DMG package
- ✅ Install to /Applications
- ✅ Set up file associations

**No manual steps required!** Just run the command and follow the prompts.

### Alternative: Manual Installation

If you prefer to clone first and then install:

```bash
# Clone the repository
git clone https://github.com/alal76/notepad-plus-plus-mac.git
cd notepad-plus-plus-mac

# Run the installation script
./install.sh
```

For detailed installation instructions, see [INSTALL_MACOS.md](INSTALL_MACOS.md).

### System Requirements

- **macOS**: 11.0 (Big Sur) or later
- **Architecture**: Intel (x86_64) or Apple Silicon (arm64)
- **Xcode**: 13.0 or later (for building from source)
- **Disk Space**: ~50 MB for the application

## Supported OS

This macOS port supports:
- macOS 14 Sonoma
- macOS 13 Ventura
- macOS 12 Monterey
- macOS 11 Big Sur

For the original Windows version, all Windows systems still supported by Microsoft are supported by Notepad++. See the [original repository](https://github.com/notepad-plus-plus/notepad-plus-plus) for Windows-specific information.
## Build Notepad++ for macOS

Please follow the [BUILD.md](BUILD.md) guide to build Notepad++ from source on macOS.

Quick build:
```bash
cd PowerEditor/cocoa/scripts
./build.sh
```

## Original Windows Version

For building the Windows version of Notepad++, please refer to the [original repository](https://github.com/notepad-plus-plus/notepad-plus-plus).


## Contribution

Contributions to the macOS port are welcome! Please be mindful of:

- The original [Notepad++ Contribution Rules](CONTRIBUTING.md)
- macOS Human Interface Guidelines
- Platform-specific considerations for macOS

### Contributing to This macOS Port

We welcome contributions in the following areas:

1. **macOS UI/UX**: AppKit controls, native dialogs, and system integration
2. **Platform Abstraction**: File I/O, configuration management
3. **Testing**: Unit tests, integration tests, UI automation
4. **Documentation**: User guides, developer documentation
5. **Localization**: Translation support for macOS

### Contributing to Original Notepad++

For contributions to the Windows version, please visit the [original Notepad++ repository](https://github.com/notepad-plus-plus/notepad-plus-plus).

[Notepad++ Contributors](https://github.com/notepad-plus-plus/notepad-plus-plus/graphs/contributors)

## Documentation

- **[INSTALL_MACOS.md](INSTALL_MACOS.md)** - Installation instructions for macOS
- **[BUILD.md](BUILD.md)** - Build instructions for all platforms
- **[macOS_README.md](macOS_README.md)** - Detailed macOS port documentation
- **[macOS_QUICKSTART.md](macOS_QUICKSTART.md)** - Quick start guide for developers
- **[macOS_PORT_PLAN.md](macOS_PORT_PLAN.md)** - Technical porting plan and architecture

## License

This macOS port maintains the same GPL v3 license as the original Notepad++.

```
Copyright (C)2021 Don HO <don.h@free.fr>

This program is free software; you may redistribute and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; Version 3 with the clarifications and exceptions described below.
```

See [LICENSE](LICENSE) for the full license text.

## Links

- **macOS Port Repository**: [alal76/notepad-plus-plus-mac](https://github.com/alal76/notepad-plus-plus-mac)
- **Original Notepad++**: [notepad-plus-plus/notepad-plus-plus](https://github.com/notepad-plus-plus/notepad-plus-plus)
- **Official Website**: [notepad-plus-plus.org](https://notepad-plus-plus.org/)
- **Community Forum**: [community.notepad-plus-plus.org](https://community.notepad-plus-plus.org/)
- **Scintilla**: [scintilla.org](https://www.scintilla.org/)

---

**Note**: This is an independent macOS port. For the official Windows version and support, please visit the [original Notepad++ project](https://github.com/notepad-plus-plus/notepad-plus-plus).

