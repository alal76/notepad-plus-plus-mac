# Installing Notepad++ on macOS

This guide will help you install Notepad++ on your macOS system.

## One-Command Quick Install ⚡ (Recommended)

The fastest way to install Notepad++ is with a single command:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/alal76/notepad-plus-plus-mac/main/quick-install.sh)
```

This command will automatically:
1. ✅ Check your system requirements (macOS 11.0+)
2. ✅ Install Xcode Command Line Tools (if needed)
3. ✅ Clone the repository to a temporary directory
4. ✅ Build Scintilla and Lexilla frameworks
5. ✅ Build the Notepad++ application
6. ✅ Create a DMG package (for backup/distribution)
7. ✅ Install to your Applications folder
8. ✅ Set up file associations
9. ✅ Clean up temporary files

**Total time:** 5-10 minutes depending on your Mac's speed.

**What you need:**
- macOS 11.0 (Big Sur) or later
- Internet connection
- ~5 GB of free disk space (temporary, only ~50 MB after cleanup)

Just run the command, follow the prompts, and you're done! 🎉

---

## Alternative Installation Methods

If you prefer more control over the installation process, you can use one of these methods:

## Quick Install (Using the Install Script)

The easiest way to install Notepad++ on macOS (after the one-command method above) is to use the provided installation script:

```bash
# Clone the repository
git clone https://github.com/alal76/notepad-plus-plus-mac.git
cd notepad-plus-plus-mac

# Run the installation script
./install.sh
```

The script will:
1. Check system requirements
2. Install Xcode Command Line Tools (if needed)
3. Build Scintilla and Lexilla frameworks
4. Build the Notepad++ application
5. Install it to your Applications folder
6. Set up file associations (optional)

## System Requirements

### Minimum Requirements

- **Operating System**: macOS 11.0 (Big Sur) or later
- **Architecture**: Intel (x86_64) or Apple Silicon (arm64)
- **RAM**: 512 MB minimum, 1 GB recommended
- **Disk Space**: 
  - 50 MB for the application
  - 5 GB for development tools (Xcode Command Line Tools)
- **Xcode**: Command Line Tools 13.0 or later

### Recommended

- **Operating System**: macOS 12.0 (Monterey) or later
- **RAM**: 2 GB or more
- **Xcode**: Latest version from the Mac App Store

## Installation Methods

### Method 0: One-Command Quick Install (Fastest) ⚡

Already covered at the top of this document! Just run:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/alal76/notepad-plus-plus-mac/main/quick-install.sh)
```

If you want to download the script first and review it:

```bash
# Download the script
curl -fsSL https://raw.githubusercontent.com/alal76/notepad-plus-plus-mac/main/quick-install.sh -o quick-install.sh

# Review the script (optional)
less quick-install.sh

# Run it
bash quick-install.sh
```

---

### Method 1: Using the Install Script (After Cloning)

1. **Clone the repository:**
   ```bash
   git clone https://github.com/alal76/notepad-plus-plus-mac.git
   cd notepad-plus-plus-mac
   ```

2. **Make the script executable:**
   ```bash
   chmod +x install.sh
   ```

3. **Run the installation:**
   ```bash
   ./install.sh
   ```

4. **Follow the prompts:**
   - The script will guide you through the installation
   - It will ask for your password to install to Applications
   - It will offer to set up file associations

5. **Launch Notepad++:**
   ```bash
   open /Applications/Notepad++.app
   ```
   Or find it in your Applications folder.

### Method 2: Manual Build and Install

If you prefer to build and install manually:

1. **Install Xcode Command Line Tools:**
   ```bash
   xcode-select --install
   ```

2. **Clone the repository:**
   ```bash
   git clone https://github.com/alal76/notepad-plus-plus-mac.git
   cd notepad-plus-plus-mac
   ```

3. **Build the application:**
   ```bash
   cd PowerEditor/cocoa/scripts
   ./build.sh
   ```

4. **Copy to Applications:**
   ```bash
   cp -R ../build/Release/Notepad++.app /Applications/
   ```

5. **Launch:**
   ```bash
   open /Applications/Notepad++.app
   ```

### Method 3: Using Xcode

For developers who want to work with the source:

1. **Install Xcode** from the Mac App Store

2. **Clone the repository:**
   ```bash
   git clone https://github.com/alal76/notepad-plus-plus-mac.git
   cd notepad-plus-plus-mac
   ```

3. **Build Scintilla framework:**
   ```bash
   cd scintilla/cocoa
   open Scintilla/Scintilla.xcodeproj
   ```
   Build the Scintilla scheme in Xcode.

4. **Build Lexilla framework:**
   ```bash
   cd ../../lexilla/src/Lexilla
   open Lexilla.xcodeproj
   ```
   Build the Lexilla scheme in Xcode.

5. **Open the main project:**
   ```bash
   cd ../../../PowerEditor/cocoa
   open NotepadPlusPlus.xcodeproj
   ```

6. **Build and run** the Notepad++ target in Xcode.

## Post-Installation

### Setting Up File Associations

To associate file types with Notepad++:

1. **Right-click any text file** in Finder
2. Select **"Get Info"** (or press ⌘I)
3. Under **"Open with:"**, select **Notepad++**
4. Click **"Change All..."** to apply to all files of this type

Supported file types:
- Plain text (`.txt`, `.log`, `.md`)
- Programming languages (`.c`, `.cpp`, `.h`, `.java`, `.py`, `.js`, `.html`, `.css`, `.xml`, etc.)
- Configuration files (`.conf`, `.ini`, `.json`, `.yaml`, etc.)
- Shell scripts (`.sh`, `.bash`, `.zsh`)
- And 100+ more file extensions

### Enabling macOS Services

Notepad++ provides macOS Services for quick access:

1. **Open System Settings** → **Keyboard** → **Keyboard Shortcuts** → **Services**
2. Look for **"Open in Notepad++"** under **Files and Folders**
3. Check the box to enable it

Now you can right-click files in Finder and select **Services** → **Open in Notepad++**.

### Adding to Dock

To keep Notepad++ in your Dock:

1. Open **Notepad++** from Applications
2. **Right-click** the Dock icon
3. Select **Options** → **Keep in Dock**

### Command Line Access (Optional)

To open files from Terminal:

1. Create an alias in your shell profile (`~/.zshrc` or `~/.bash_profile`):
   ```bash
   alias npp='open -a "Notepad++"'
   ```

2. Reload your shell:
   ```bash
   source ~/.zshrc
   ```

3. Use it:
   ```bash
   npp myfile.txt
   ```

## Updating

To update Notepad++ to the latest version:

```bash
cd notepad-plus-plus-mac
git pull origin main
./install.sh
```

Or rebuild manually using the build script.

## Uninstalling

To remove Notepad++ from your system:

```bash
# Remove the application
rm -rf /Applications/Notepad++.app

# Remove preferences (optional)
rm -rf ~/Library/Preferences/org.notepad-plus-plus.Notepad++.plist
rm -rf ~/Library/Application\ Support/Notepad++
```

## Troubleshooting

### Application Won't Open

**"Notepad++.app is damaged and can't be opened"**

This can happen if the app wasn't properly signed. Try:

```bash
sudo xattr -cr /Applications/Notepad++.app
```

### Build Failures

**"xcodebuild: command not found"**

Install Xcode Command Line Tools:
```bash
xcode-select --install
```

**"No developer directory found"**

Set the developer directory:
```bash
sudo xcode-select --switch /Library/Developer/CommandLineTools
```

Or if you have Xcode installed:
```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
```

**Framework build errors**

Make sure you're on a supported macOS version:
```bash
sw_vers
```

Clean and rebuild:
```bash
cd PowerEditor/cocoa/scripts
./build.sh clean
./build.sh
```

### Permission Errors

**"Operation not permitted"**

Grant Full Disk Access to Terminal:
1. Open **System Settings** → **Privacy & Security** → **Full Disk Access**
2. Add **Terminal** (or your terminal app)
3. Restart Terminal and try again

### Performance Issues

If the editor feels slow:

1. **Check Activity Monitor** for high CPU usage
2. **Disable unused plugins** (when plugin support is available)
3. **Reduce file size** for syntax highlighting (>10MB files may be slow)
4. **Update to latest version** for performance improvements

### File Associations Not Working

Reset Launch Services:
```bash
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user
killall Finder
```

Then re-associate files through Finder's "Get Info".

## Getting Help

- **Documentation**: Check [macOS_README.md](macOS_README.md) for detailed information
- **Build Issues**: See [BUILD.md](BUILD.md) for build instructions
- **Bugs**: Report issues on [GitHub Issues](https://github.com/alal76/notepad-plus-plus-mac/issues)
- **Original Notepad++**: Visit [notepad-plus-plus.org](https://notepad-plus-plus.org/)

## Known Limitations

Current macOS port limitations:

- **Plugins**: Windows plugins are not compatible (native macOS plugins coming soon)
- **Some advanced features**: Under development (see [macOS_TODO.md](macOS_TODO.md))
- **Visual theme**: macOS native look (Windows themes not applicable)

For Windows-specific features, please use the [original Windows version](https://github.com/notepad-plus-plus/notepad-plus-plus).

## Next Steps

After installation:

1. **Read the documentation**: [macOS_README.md](macOS_README.md)
2. **Learn the shortcuts**: Check the menu for keyboard shortcuts
3. **Customize**: Preferences → Settings (when available)
4. **Contribute**: See [CONTRIBUTING.md](CONTRIBUTING.md)

---

**Enjoy using Notepad++ on macOS!**

For the latest updates and information, visit:
- macOS Port: [github.com/alal76/notepad-plus-plus-mac](https://github.com/alal76/notepad-plus-plus-mac)
- Original Project: [notepad-plus-plus.org](https://notepad-plus-plus.org/)
