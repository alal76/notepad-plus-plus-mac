# macOS Port - Quick Start Guide

This guide helps developers quickly get started with porting Notepad++ to macOS.

## Prerequisites

### Required
- macOS 11.0+ (Big Sur or later)
- Xcode 13.0+ (latest recommended)
- Command Line Tools for Xcode
- Git

### Recommended
- Apple Developer Program membership (for code signing)
- Familiarity with:
  - Objective-C++ (.mm files)
  - AppKit framework
  - Cocoa design patterns
  - Scintilla editor component

## Quick Setup (5 minutes)

### 1. Clone and Explore

```bash
# Clone the repository
git clone https://github.com/alal76/notepad-plus-plus-mac.git
cd notepad-plus-plus-mac

# Explore the structure
ls -la
# PowerEditor/    - Main application code (Windows-specific)
# scintilla/      - Editor component (has macOS support!)
# lexilla/        - Syntax highlighting (has macOS support!)
```

### 2. Verify Scintilla Cocoa Support

```bash
# Check Scintilla Cocoa implementation
cd scintilla/cocoa
ls -la
# Should see: ScintillaCocoa.mm, ScintillaView.mm, PlatCocoa.mm, etc.

# Check Xcode project
ls -la Scintilla/
# Should see: Scintilla.xcodeproj/
```

### 3. Build Scintilla Framework

```bash
# From scintilla/cocoa directory
cd scintilla/cocoa

# Build the framework
xcodebuild -project Scintilla/Scintilla.xcodeproj \
           -scheme Scintilla \
           -configuration Release \
           build

# Check output
ls -la build/Release/
# Should see: Scintilla.framework/
```

### 4. Build Lexilla Framework

```bash
# Return to root
cd ../../

# Build Lexilla
cd lexilla/src/Lexilla
xcodebuild -project Lexilla.xcodeproj \
           -scheme Lexilla \
           -configuration Release \
           build

# Check output
ls -la build/Release/
# Should see: Lexilla.framework/
```

### 5. Test Scintilla (Optional)

```bash
# Build and run the test application
cd ../../scintilla/cocoa
xcodebuild -project ScintillaTest/ScintillaTest.xcodeproj \
           -scheme ScintillaTest \
           -configuration Release \
           build

# Run the test app
open build/Release/ScintillaTest.app
```

You should see a working text editor! This proves Scintilla works on macOS.

## Development Roadmap

### Phase 1: Create Minimal Editor (Week 1-2)

**Goal**: Get a basic single-window editor running

#### Step 1.1: Create Xcode Project

```bash
# Create directory for macOS-specific code
mkdir -p PowerEditor/cocoa
cd PowerEditor/cocoa

# Create Xcode project (via Xcode GUI):
# 1. Open Xcode
# 2. File > New > Project
# 3. macOS > App
# 4. Product Name: "Notepad++"
# 5. Organization Identifier: "org.notepad-plus-plus"
# 6. Interface: Storyboard (or SwiftUI if desired)
# 7. Language: Objective-C
# 8. Save in: PowerEditor/cocoa/
```

#### Step 1.2: Project Configuration

**Info.plist additions**:
```xml
<key>CFBundleName</key>
<string>Notepad++</string>
<key>CFBundleIdentifier</key>
<string>org.notepad-plus-plus</string>
<key>CFBundleVersion</key>
<string>1.0.0</string>
<key>LSMinimumSystemVersion</key>
<string>10.15</string>

<!-- Document types -->
<key>CFBundleDocumentTypes</key>
<array>
    <dict>
        <key>CFBundleTypeName</key>
        <string>Text Document</string>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>LSHandlerRank</key>
        <string>Default</string>
        <key>LSItemContentTypes</key>
        <array>
            <string>public.text</string>
            <string>public.plain-text</string>
            <string>public.source-code</string>
        </array>
    </dict>
</array>
```

**Build Settings**:
- Deployment Target: macOS 10.15
- C++ Language Dialect: C++20
- Enable Hardened Runtime: Yes (for notarization)

#### Step 1.3: Link Frameworks

In Xcode:
1. Select project in navigator
2. Select target > General > Frameworks, Libraries, and Embedded Content
3. Add:
   - `Scintilla.framework` (from scintilla/cocoa/build/Release/)
   - `Lexilla.framework` (from lexilla/src/Lexilla/build/Release/)
   - AppKit.framework
   - Foundation.framework

#### Step 1.4: Create Basic App Structure

**AppDelegate.h**:
```objc
#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (strong, nonatomic) NSWindow *mainWindow;

@end
```

**AppDelegate.mm** (note .mm extension for Objective-C++):
```objc
#import "AppDelegate.h"
#import <Scintilla/ScintillaView.h>

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    // Create main window
    NSRect frame = NSMakeRect(100, 100, 800, 600);
    self.mainWindow = [[NSWindow alloc] 
        initWithContentRect:frame
        styleMask:(NSWindowStyleMaskTitled | 
                   NSWindowStyleMaskClosable |
                   NSWindowStyleMaskMiniaturizable |
                   NSWindowStyleMaskResizable)
        backing:NSBackingStoreBuffered
        defer:NO];
    
    [self.mainWindow setTitle:@"Notepad++"];
    
    // Create ScintillaView
    ScintillaView *scintilla = [[ScintillaView alloc] 
                                initWithFrame:frame];
    
    // Configure basic settings
    [scintilla setGeneralProperty:SCI_SETLEXER 
                            value:SCLEX_CPP];
    [scintilla setGeneralProperty:SCI_STYLESETFONT
                            value:0
                           string:"Monaco"];
    
    // Set as window content
    [self.mainWindow setContentView:scintilla];
    
    // Show window
    [self.mainWindow makeKeyAndOrderFront:nil];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:
        (NSApplication *)sender {
    return YES;
}

@end
```

#### Step 1.5: Build and Run

```bash
# Build from command line
xcodebuild -project NotepadPlusPlus.xcodeproj \
           -scheme "Notepad++" \
           build

# Or: Product > Run in Xcode (Cmd+R)
```

**Success**: You should see a window with a working text editor!

### Phase 1 Continued: Add File Operations

#### Open File

**AppDelegate.mm additions**:
```objc
- (IBAction)openDocument:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setCanChooseFiles:YES];
    [panel setCanChooseDirectories:NO];
    [panel setAllowsMultipleSelection:NO];
    
    [panel beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSModalResponseOK) {
            NSURL *url = [[panel URLs] firstObject];
            [self openFileAtURL:url];
        }
    }];
}

- (void)openFileAtURL:(NSURL *)url {
    NSError *error = nil;
    NSString *content = [NSString stringWithContentsOfURL:url
                                                 encoding:NSUTF8StringEncoding
                                                    error:&error];
    
    if (error) {
        NSLog(@"Error opening file: %@", error);
        return;
    }
    
    // Get ScintillaView
    ScintillaView *scintilla = (ScintillaView *)[self.mainWindow contentView];
    
    // Set content
    [scintilla setGeneralProperty:SCI_SETTEXT
                            value:0
                           string:[content UTF8String]];
    
    // Update window title
    [self.mainWindow setTitle:[url lastPathComponent]];
}
```

#### Save File

```objc
- (IBAction)saveDocument:(id)sender {
    NSSavePanel *panel = [NSSavePanel savePanel];
    
    [panel beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSModalResponseOK) {
            NSURL *url = [panel URL];
            [self saveFileToURL:url];
        }
    }];
}

- (void)saveFileToURL:(NSURL *)url {
    ScintillaView *scintilla = (ScintillaView *)[self.mainWindow contentView];
    
    // Get content from Scintilla
    long length = [scintilla getGeneralProperty:SCI_GETLENGTH];
    char *buffer = malloc(length + 1);
    [scintilla getGeneralProperty:SCI_GETTEXT
                            value:length + 1
                           string:buffer];
    
    NSString *content = [NSString stringWithUTF8String:buffer];
    free(buffer);
    
    // Write to file
    NSError *error = nil;
    [content writeToURL:url
             atomically:YES
               encoding:NSUTF8StringEncoding
                  error:&error];
    
    if (error) {
        NSLog(@"Error saving file: %@", error);
    }
}
```

#### Menu Setup

In **MainMenu.xib** (or programmatically):
```objc
- (void)setupMenus {
    NSMenu *mainMenu = [[NSMenu alloc] init];
    
    // File menu
    NSMenuItem *fileMenuItem = [[NSMenuItem alloc] init];
    NSMenu *fileMenu = [[NSMenu alloc] initWithTitle:@"File"];
    
    [fileMenu addItemWithTitle:@"New"
                        action:@selector(newDocument:)
                 keyEquivalent:@"n"];
    
    [fileMenu addItemWithTitle:@"Open..."
                        action:@selector(openDocument:)
                 keyEquivalent:@"o"];
    
    [fileMenu addItemWithTitle:@"Save"
                        action:@selector(saveDocument:)
                 keyEquivalent:@"s"];
    
    [fileMenu addItem:[NSMenuItem separatorItem]];
    
    [fileMenu addItemWithTitle:@"Close"
                        action:@selector(performClose:)
                 keyEquivalent:@"w"];
    
    [fileMenuItem setSubmenu:fileMenu];
    [mainMenu addItem:fileMenuItem];
    
    [NSApp setMainMenu:mainMenu];
}
```

## Common Challenges & Solutions

### Challenge 1: Framework Not Found

**Error**: `Framework not found Scintilla`

**Solution**:
```bash
# Check framework search paths in Build Settings
# Add: $(PROJECT_DIR)/../../scintilla/cocoa/build/Release
# And:  $(PROJECT_DIR)/../../lexilla/src/Lexilla/build/Release
```

### Challenge 2: C++ Linking Errors

**Error**: `Undefined symbols for architecture arm64`

**Solution**:
- Ensure all files with C++ are renamed to .mm (Objective-C++)
- In Build Settings, set "C++ Standard Library" to libc++

### Challenge 3: Scintilla API Confusion

**Problem**: How do I call Scintilla functions?

**Solution**:
```objc
// General pattern:
[scintilla setGeneralProperty:SCI_PROPERTY_NAME
                        value:VALUE
                       string:STRING];  // Optional

// Examples:
[scintilla setGeneralProperty:SCI_SETLEXER value:SCLEX_CPP];
[scintilla setGeneralProperty:SCI_SETZOOM value:2];
[scintilla setGeneralProperty:SCI_SETWRAPMODE value:SC_WRAP_WORD];
```

Reference: [Scintilla Documentation](https://www.scintilla.org/ScintillaDoc.html)

### Challenge 4: Encoding Issues

**Problem**: Files with non-UTF8 encoding don't open correctly

**Solution**: Implement encoding detection (port from Windows code):
```objc
// Use uchardet (included in PowerEditor/src/uchardet/)
// Or NSString's encoding detection:
NSString *content = [NSString stringWithContentsOfURL:url
                                         usedEncoding:&encoding
                                                error:&error];
```

## Key Files to Understand

### Windows Side (Reference)
- `PowerEditor/src/Notepad_plus.cpp` - Main application class
- `PowerEditor/src/Notepad_plus.h` - Public interface
- `PowerEditor/src/Parameters.cpp` - Configuration management
- `PowerEditor/src/ScintillaComponent/ScintillaEditView.cpp` - Scintilla wrapper

### macOS Side (To Create)
- `PowerEditor/cocoa/AppDelegate.mm` - Application lifecycle
- `PowerEditor/cocoa/MainWindow.mm` - Main window controller
- `PowerEditor/cocoa/DocumentController.mm` - Multi-document management
- `PowerEditor/cocoa/Platform/FileManager.mm` - File I/O abstraction
- `PowerEditor/cocoa/Platform/ConfigManager.mm` - Preferences

### Shared (Cross-platform)
- `scintilla/cocoa/ScintillaCocoa.mm` - ✅ Already complete
- `scintilla/cocoa/ScintillaView.mm` - ✅ Already complete
- `PowerEditor/src/Parameters.h` - Can be reused
- `PowerEditor/src/uchardet/` - Encoding detection (reuse)

## Testing Your Build

### Manual Test Checklist

After each change, verify:
- [ ] Application launches without crash
- [ ] Window appears with editor
- [ ] Can type text
- [ ] Can select text
- [ ] Cut/Copy/Paste works
- [ ] Undo/Redo works
- [ ] Open file dialog appears
- [ ] Can open a .txt file
- [ ] Content displays correctly
- [ ] Can edit the file
- [ ] Save dialog appears
- [ ] File saves successfully

### Automated Testing

Create XCTest cases:
```objc
@interface FileOperationsTests : XCTestCase
@end

@implementation FileOperationsTests

- (void)testOpenFile {
    // Create temp file
    NSString *content = @"Hello, World!";
    NSURL *tempURL = [self createTempFileWithContent:content];
    
    // Open in editor
    [appDelegate openFileAtURL:tempURL];
    
    // Verify content loaded
    ScintillaView *view = [appDelegate scintillaView];
    NSString *loaded = [self getTextFromScintilla:view];
    XCTAssertEqualObjects(loaded, content);
}

@end
```

## Resources

### Documentation
- [Scintilla Documentation](https://www.scintilla.org/ScintillaDoc.html)
- [Scintilla Cocoa Usage](https://www.scintilla.org/ScintillaUsage.html)
- [AppKit Documentation](https://developer.apple.com/documentation/appkit)
- [macOS Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/macos)

### Example Code
- `scintilla/cocoa/ScintillaTest/` - Example Scintilla app
- Original Notepad++ code (Windows) - Reference for features

### Community
- Notepad++ Forum: https://community.notepad-plus-plus.org/
- Scintilla Mailing List: https://groups.google.com/g/scintilla-interest

## Next Steps

Once you have the basic editor working:

1. **Add tab bar** (NSTabView) for multiple documents
2. **Implement Find/Replace** dialog
3. **Port language definitions** (langs.xml parsing)
4. **Add syntax highlighting** (via Lexilla)
5. **Create preferences** system

Refer to `macOS_TODO.md` for complete checklist and `macOS_PORT_PLAN.md` for architecture details.

## Getting Help

If you encounter issues:

1. Check the `macOS_PORT_PLAN.md` for technical details
2. Review Scintilla documentation
3. Look at `scintilla/cocoa/ScintillaTest/` for examples
4. Search Notepad++ and Scintilla forums
5. Create an issue on GitHub with:
   - macOS version
   - Xcode version
   - Build error or runtime error (full stack trace)
   - Steps to reproduce

## Contributing

Once you make progress:

1. Commit your changes to a feature branch
2. Create a pull request
3. Document any deviations from the plan
4. Include screenshots of UI changes
5. Update this guide if you find better approaches

Good luck with the port! 🚀
