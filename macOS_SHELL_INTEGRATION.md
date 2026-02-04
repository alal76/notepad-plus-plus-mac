# macOS Shell Integration - Design Document

## Overview

This document designs macOS equivalents for Notepad++'s Windows registry shell integrations. Windows uses the registry for file associations and context menu extensions, while macOS uses different mechanisms that are more secure and integrated with the operating system.

## Windows Shell Integrations (Current)

### 1. File Type Associations (Registry)
**Windows Implementation**:
- Registry keys under `HKEY_CLASSES_ROOT\.ext`
- Associates file extensions (.txt, .cpp, .js, etc.) with Notepad++
- Sets "Open with" default application
- Supports ~100+ file extensions across 10 categories

**Registry Structure**:
```
HKEY_CLASSES_ROOT
├── .txt -> "Notepad++_file"
├── .cpp -> "Notepad++_file"
├── .js -> "Notepad++_file"
└── Notepad++_file
    ├── (Default) = "Notepad++ Document"
    └── shell
        └── open
            └── command
                └── (Default) = "C:\Program Files\Notepad++\notepad++.exe" "%1"
```

### 2. Context Menu Extension (NppShell.dll)
**Windows Implementation**:
- COM-based shell extension DLL (`NppShell.dll`)
- Registered via `regsvr32.exe`
- Adds "Edit with Notepad++" to right-click menu in Explorer
- Works on files and folders

### 3. "Edit with Notepad++" Context Menu
**Features**:
- Right-click on any file → "Edit with Notepad++"
- Right-click on folder → "Edit with Notepad++" (opens all text files)
- Available even if Notepad++ is not default editor

---

## macOS Equivalents - Architecture

macOS provides several modern, secure mechanisms for system integration:

### Option 1: Info.plist File Associations (✅ RECOMMENDED)
**Pros**:
- Native, sandboxing-compatible
- Standard macOS approach
- No special permissions needed
- Works with "Open with" menu

**Cons**:
- User must select Notepad++ as default
- Cannot add to all file types automatically

### Option 2: Finder Sync Extension
**Pros**:
- Can add badges, context menus to Finder
- Modern, sandboxed
- Part of app bundle

**Cons**:
- Requires user approval
- More complex implementation
- Limited to specific folders

### Option 3: macOS Services
**Pros**:
- System-wide availability
- Appears in Services submenu
- Simple to implement

**Cons**:
- Buried in Services submenu
- Less discoverable

### Option 4: Quick Action (Finder Extension)
**Pros**:
- Appears in Finder toolbar
- Very visible and accessible
- Modern macOS approach

**Cons**:
- Requires macOS 10.14+
- User must enable in System Preferences

### Option 5: Share Extension
**Pros**:
- Integrated with macOS Share menu
- Works across many apps

**Cons**:
- Limited to certain contexts
- May not be obvious for file editing

---

## Recommended Implementation Strategy

Implement **all compatible methods** to maximize user convenience:

1. **Info.plist associations** (Primary) - Always included
2. **macOS Services** (Secondary) - Easy to add, good fallback
3. **Quick Action** (Modern) - Best user experience for macOS 10.14+
4. **Finder Sync Extension** (Advanced) - Optional, for power users

---

## Detailed Implementation Plans

### 1. File Type Associations (Info.plist)

#### Implementation

**Location**: `PowerEditor/cocoa/Resources/Info.plist`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Application Info -->
    <key>CFBundleName</key>
    <string>Notepad++</string>
    
    <key>CFBundleIdentifier</key>
    <string>org.notepad-plus-plus</string>
    
    <key>CFBundleDisplayName</key>
    <string>Notepad++</string>
    
    <!-- Document Types -->
    <key>CFBundleDocumentTypes</key>
    <array>
        <!-- Plain Text -->
        <dict>
            <key>CFBundleTypeName</key>
            <string>Text Document</string>
            <key>CFBundleTypeRole</key>
            <string>Editor</string>
            <key>CFBundleTypeIconFile</key>
            <string>textfile</string>
            <key>LSHandlerRank</key>
            <string>Default</string>
            <key>LSItemContentTypes</key>
            <array>
                <string>public.plain-text</string>
                <string>public.text</string>
            </array>
            <key>NSDocumentClass</key>
            <string>NotepadDocument</string>
        </dict>
        
        <!-- Source Code (C/C++/Obj-C) -->
        <dict>
            <key>CFBundleTypeName</key>
            <string>C/C++ Source</string>
            <key>CFBundleTypeRole</key>
            <string>Editor</string>
            <key>CFBundleTypeIconFile</key>
            <string>sourcefile</string>
            <key>LSHandlerRank</key>
            <string>Default</string>
            <key>LSItemContentTypes</key>
            <array>
                <string>public.c-source</string>
                <string>public.c-header</string>
                <string>public.c-plus-plus-source</string>
                <string>public.c-plus-plus-header</string>
                <string>public.objective-c-source</string>
                <string>public.objective-c-plus-plus-source</string>
            </array>
        </dict>
        
        <!-- Web Files (HTML, CSS, JS) -->
        <dict>
            <key>CFBundleTypeName</key>
            <string>Web Document</string>
            <key>CFBundleTypeRole</key>
            <string>Editor</string>
            <key>CFBundleTypeIconFile</key>
            <string>webfile</string>
            <key>LSHandlerRank</key>
            <string>Alternate</string>
            <key>LSItemContentTypes</key>
            <array>
                <string>public.html</string>
                <string>public.xml</string>
                <string>public.css</string>
                <string>com.netscape.javascript-source</string>
                <string>public.json</string>
            </array>
        </dict>
        
        <!-- Scripts (Shell, Python, etc.) -->
        <dict>
            <key>CFBundleTypeName</key>
            <string>Script</string>
            <key>CFBundleTypeRole</key>
            <string>Editor</string>
            <key>CFBundleTypeIconFile</key>
            <string>scriptfile</string>
            <key>LSHandlerRank</key>
            <string>Default</string>
            <key>LSItemContentTypes</key>
            <array>
                <string>public.shell-script</string>
                <string>public.python-script</string>
                <string>public.perl-script</string>
                <string>public.ruby-script</string>
            </array>
        </dict>
        
        <!-- Custom Extensions -->
        <dict>
            <key>CFBundleTypeName</key>
            <string>Code File</string>
            <key>CFBundleTypeRole</key>
            <string>Editor</string>
            <key>LSHandlerRank</key>
            <string>Alternate</string>
            <key>CFBundleTypeExtensions</key>
            <array>
                <!-- C/C++ -->
                <string>h</string>
                <string>hh</string>
                <string>hpp</string>
                <string>hxx</string>
                <string>c</string>
                <string>cpp</string>
                <string>cxx</string>
                <string>cc</string>
                <string>m</string>
                <string>mm</string>
                
                <!-- Java/C# -->
                <string>java</string>
                <string>cs</string>
                
                <!-- Web -->
                <string>html</string>
                <string>htm</string>
                <string>css</string>
                <string>js</string>
                <string>json</string>
                <string>xml</string>
                <string>php</string>
                
                <!-- Scripts -->
                <string>sh</string>
                <string>bash</string>
                <string>bat</string>
                <string>cmd</string>
                <string>py</string>
                <string>pl</string>
                <string>rb</string>
                <string>lua</string>
                
                <!-- Config -->
                <string>ini</string>
                <string>conf</string>
                <string>cfg</string>
                <string>properties</string>
                
                <!-- Logs -->
                <string>log</string>
                <string>txt</string>
                
                <!-- And many more... -->
            </array>
        </dict>
    </array>
    
    <!-- Exported UTIs (for custom file types) -->
    <key>UTExportedTypeDeclarations</key>
    <array>
        <dict>
            <key>UTTypeIdentifier</key>
            <string>org.notepad-plus-plus.npp-session</string>
            <key>UTTypeDescription</key>
            <string>Notepad++ Session</string>
            <key>UTTypeConformsTo</key>
            <array>
                <string>public.xml</string>
            </array>
            <key>UTTypeTagSpecification</key>
            <dict>
                <key>public.filename-extension</key>
                <array>
                    <string>session</string>
                </array>
            </dict>
        </dict>
    </array>
</dict>
</plist>
```

#### User Configuration UI

**Create Preferences Panel**: `PowerEditor/cocoa/FileAssociations/`

**FileAssociationsController.h**:
```objc
@interface FileAssociationsController : NSViewController

// Check if Notepad++ is default for a file type
- (BOOL)isDefaultHandlerForUTI:(NSString *)uti;

// Check if Notepad++ is default for extension
- (BOOL)isDefaultHandlerForExtension:(NSString *)ext;

// Set as default (opens System Preferences)
- (void)setAsDefaultHandler;

// Get list of supported extensions
- (NSArray<NSString *> *)supportedExtensions;

@end
```

**FileAssociationsController.mm**:
```objc
#import "FileAssociationsController.h"
#import <AppKit/AppKit.h>

@implementation FileAssociationsController

- (BOOL)isDefaultHandlerForUTI:(NSString *)uti {
    CFStringRef defaultApp = LSCopyDefaultRoleHandlerForContentType(
        (__bridge CFStringRef)uti,
        kLSRolesEditor
    );
    
    if (!defaultApp) return NO;
    
    NSString *bundleId = (__bridge_transfer NSString *)defaultApp;
    return [bundleId isEqualToString:@"org.notepad-plus-plus"];
}

- (BOOL)isDefaultHandlerForExtension:(NSString *)ext {
    // Get UTI for extension
    CFStringRef uti = UTTypeCreatePreferredIdentifierForTag(
        kUTTagClassFilenameExtension,
        (__bridge CFStringRef)ext,
        NULL
    );
    
    if (!uti) return NO;
    
    BOOL isDefault = [self isDefaultHandlerForUTI:(__bridge NSString *)uti];
    CFRelease(uti);
    
    return isDefault;
}

- (void)setAsDefaultHandler {
    // Open System Preferences to Extensions pane
    // User must manually set Notepad++ as default
    
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"Set Notepad++ as Default Editor"];
    [alert setInformativeText:
        @"To set Notepad++ as your default editor:\n\n"
        @"1. Click 'Open System Preferences'\n"
        @"2. Select a file type (e.g., .txt)\n"
        @"3. Right-click > Get Info\n"
        @"4. Under 'Open with:', select Notepad++\n"
        @"5. Click 'Change All...'"];
    [alert addButtonWithTitle:@"Open System Preferences"];
    [alert addButtonWithTitle:@"Cancel"];
    
    if ([alert runModal] == NSAlertFirstButtonReturn) {
        [[NSWorkspace sharedWorkspace] 
            openURL:[NSURL URLWithString:@"x-apple.systempreferences:com.apple.preference.extensions"]];
    }
}

- (NSArray<NSString *> *)supportedExtensions {
    return @[
        // Plain text
        @"txt", @"log",
        
        // C/C++/Obj-C
        @"h", @"hh", @"hpp", @"hxx", @"c", @"cpp", @"cxx", @"cc", @"m", @"mm",
        
        // Java/C#
        @"java", @"cs", @"pas", @"pp", @"inc",
        
        // Web
        @"html", @"htm", @"css", @"js", @"json", @"xml", @"php",
        
        // Scripts
        @"sh", @"bash", @"bat", @"cmd", @"py", @"pl", @"rb", @"lua",
        
        // Config
        @"ini", @"inf", @"conf", @"cfg",
        
        // And many more...
    ];
}

@end
```

---

### 2. macOS Services Integration

Services appear in the "Services" submenu (right-click context menu).

#### Implementation

**Location**: `PowerEditor/cocoa/Resources/Info.plist`

```xml
<!-- Services -->
<key>NSServices</key>
<array>
    <!-- Open File in Notepad++ -->
    <dict>
        <key>NSMenuItem</key>
        <dict>
            <key>default</key>
            <string>Open in Notepad++</string>
        </dict>
        <key>NSMessage</key>
        <string>openInNotepadPlusPlus</string>
        <key>NSRequiredContext</key>
        <dict>
            <key>NSTextContent</key>
            <string>FilePath</string>
        </dict>
        <key>NSSendFileTypes</key>
        <array>
            <string>public.text</string>
            <string>public.plain-text</string>
            <string>public.source-code</string>
        </array>
    </dict>
    
    <!-- Open Selected Text in Notepad++ -->
    <dict>
        <key>NSMenuItem</key>
        <dict>
            <key>default</key>
            <string>Open Selection in Notepad++</string>
        </dict>
        <key>NSMessage</key>
        <string>openTextInNotepadPlusPlus</string>
        <key>NSRequiredContext</key>
        <dict>
            <key>NSTextContent</key>
            <string>NSStringPboardType</string>
        </dict>
        <key>NSSendTypes</key>
        <array>
            <string>NSStringPboardType</string>
        </array>
    </dict>
</array>
```

**AppDelegate.mm** (Service handlers):
```objc
@implementation AppDelegate

// Service: Open file(s) in Notepad++
- (void)openInNotepadPlusPlus:(NSPasteboard *)pboard
                     userData:(NSString *)userData
                        error:(NSString **)error {
    NSArray *filePaths = [pboard propertyListForType:NSFilenamesPboardType];
    
    for (NSString *path in filePaths) {
        [self openFileAtPath:path];
    }
}

// Service: Open selected text in new document
- (void)openTextInNotepadPlusPlus:(NSPasteboard *)pboard
                         userData:(NSString *)userData
                            error:(NSString **)error {
    NSString *text = [pboard stringForType:NSStringPboardType];
    
    if (text) {
        [self createNewDocumentWithText:text];
    }
}

@end
```

**Enable Services**:
After installation, user enables via:
- System Preferences > Keyboard > Shortcuts > Services
- Check "Open in Notepad++"

---

### 3. Quick Action (Finder Extension)

Quick Actions appear directly in Finder's context menu and toolbar (macOS 10.14+).

#### Implementation

**Create Extension Target in Xcode**:
1. File > New > Target
2. macOS > Finder Extension
3. Name: "NotepadQuickAction"

**Location**: `PowerEditor/cocoa/NotepadQuickAction/`

**Info.plist** (in extension):
```xml
<key>NSExtension</key>
<dict>
    <key>NSExtensionAttributes</key>
    <dict>
        <key>NSExtensionActivationRule</key>
        <dict>
            <!-- Activate on files only -->
            <key>NSExtensionActivationSupportsFileWithMaxCount</key>
            <integer>100</integer>
            
            <!-- Supported file types -->
            <key>NSExtensionActivationSupportsText</key>
            <true/>
        </dict>
    </dict>
    
    <key>NSExtensionPointIdentifier</key>
    <string>com.apple.services</string>
    
    <key>NSExtensionPrincipalClass</key>
    <string>QuickActionHandler</string>
</dict>
```

**QuickActionHandler.h**:
```objc
#import <Cocoa/Cocoa.h>

@interface QuickActionHandler : NSObject

@end
```

**QuickActionHandler.m**:
```objc
#import "QuickActionHandler.h"

@implementation QuickActionHandler

- (void)prepareForActionWithContext:(NSExtensionContext *)context {
    // Called when Quick Action is invoked
    
    NSArray *items = context.inputItems;
    
    for (NSExtensionItem *item in items) {
        for (NSItemProvider *provider in item.attachments) {
            if ([provider hasItemConformingToTypeIdentifier:@"public.file-url"]) {
                [provider loadItemForTypeIdentifier:@"public.file-url"
                                            options:nil
                                  completionHandler:^(NSURL *url, NSError *error) {
                    if (url) {
                        [self openFileInNotepadPlusPlus:url];
                    }
                }];
            }
        }
    }
    
    [context completeRequestReturningItems:@[] completionHandler:nil];
}

- (void)openFileInNotepadPlusPlus:(NSURL *)url {
    // Launch main app with file
    NSWorkspaceOpenConfiguration *config = [NSWorkspaceOpenConfiguration configuration];
    
    [[NSWorkspace sharedWorkspace] 
        openApplicationAtURL:[self notepadAppURL]
              configuration:config
          completionHandler:^(NSRunningApplication *app, NSError *error) {
        if (!error) {
            // Send open file event to main app
            [self sendOpenFileEvent:url toApp:app];
        }
    }];
}

- (NSURL *)notepadAppURL {
    // Get main app bundle URL
    NSURL *extensionURL = [[NSBundle mainBundle] bundleURL];
    
    // Navigate up to main app
    // Extension is at: Notepad++.app/Contents/PlugIns/NotepadQuickAction.appex
    NSURL *appURL = [[[extensionURL URLByDeletingLastPathComponent]
                      URLByDeletingLastPathComponent]
                     URLByDeletingLastPathComponent];
    
    return appURL;
}

- (void)sendOpenFileEvent:(NSURL *)url toApp:(NSRunningApplication *)app {
    // Use Apple Events to tell main app to open file
    NSAppleEventDescriptor *target = 
        [NSAppleEventDescriptor descriptorWithProcessIdentifier:app.processIdentifier];
    
    NSAppleEventDescriptor *event = 
        [NSAppleEventDescriptor appleEventWithEventClass:kCoreEventClass
                                                 eventID:kAEOpenDocuments
                                        targetDescriptor:target
                                                returnID:kAutoGenerateReturnID
                                           transactionID:kAnyTransactionID];
    
    NSAppleEventDescriptor *fileList = [NSAppleEventDescriptor listDescriptor];
    [fileList insertDescriptor:[NSAppleEventDescriptor descriptorWithFileURL:url]
                       atIndex:1];
    
    [event setParamDescriptor:fileList forKeyword:keyDirectObject];
    [event sendEventWithOptions:kAENoReply | kAECanInteract timeout:kAEDefaultTimeout error:nil];
}

@end
```

**User Configuration**:
- After installing Notepad++, user must approve extension in System Preferences
- System Preferences > Extensions > Finder
- Enable "Open in Notepad++"

---

### 4. Finder Sync Extension (Advanced)

Adds context menu items directly in Finder (like NppShell.dll on Windows).

#### Implementation

**Create Extension Target**:
1. File > New > Target
2. macOS > Finder Sync Extension
3. Name: "NotepadFinderSync"

**Location**: `PowerEditor/cocoa/NotepadFinderSync/`

**FinderSync.h**:
```objc
#import <Cocoa/Cocoa.h>
#import <FinderSync/FinderSync.h>

@interface FinderSync : FIFinderSync

@end
```

**FinderSync.m**:
```objc
#import "FinderSync.h"

@implementation FinderSync

- (instancetype)init {
    self = [super init];
    if (self) {
        // Monitor user's home directory
        NSURL *homeURL = [NSURL fileURLWithPath:NSHomeDirectory()];
        [FIFinderSyncController defaultController].directoryURLs = 
            [NSSet setWithObject:homeURL];
    }
    return self;
}

#pragma mark - Menu and toolbar item support

- (NSString *)toolbarItemName {
    return @"Notepad++";
}

- (NSString *)toolbarItemToolTip {
    return @"Open with Notepad++";
}

- (NSImage *)toolbarItemImage {
    return [NSImage imageNamed:NSImageNameFolder];
}

- (NSMenu *)menuForMenuKind:(FIMenuKind)menuKind {
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@""];
    
    // Add menu items
    [menu addItemWithTitle:@"Open in Notepad++"
                    action:@selector(openInNotepad:)
             keyEquivalent:@""];
    
    [menu addItemWithTitle:@"Open in New Window"
                    action:@selector(openInNewWindow:)
             keyEquivalent:@""];
    
    return menu;
}

#pragma mark - Actions

- (IBAction)openInNotepad:(id)sender {
    FIFinderSyncController *controller = [FIFinderSyncController defaultController];
    NSArray *targets = [controller selectedItemURLs];
    
    for (NSURL *url in targets) {
        [self openFileInNotepad:url];
    }
}

- (IBAction)openInNewWindow:(id)sender {
    FIFinderSyncController *controller = [FIFinderSyncController defaultController];
    NSArray *targets = [controller selectedItemURLs];
    
    for (NSURL *url in targets) {
        [self openFileInNewWindow:url];
    }
}

- (void)openFileInNotepad:(NSURL *)url {
    // Open in existing window
    [self launchNotepadWithFile:url newWindow:NO];
}

- (void)openFileInNewWindow:(NSURL *)url {
    // Open in new window
    [self launchNotepadWithFile:url newWindow:YES];
}

- (void)launchNotepadWithFile:(NSURL *)url newWindow:(BOOL)newWindow {
    NSWorkspaceOpenConfiguration *config = [NSWorkspaceOpenConfiguration configuration];
    config.activates = YES;
    
    if (newWindow) {
        config.createsNewApplicationInstance = YES;
    }
    
    [[NSWorkspace sharedWorkspace] 
        openURLs:@[url]
        withApplicationAtURL:[self notepadAppURL]
        configuration:config
        completionHandler:^(NSRunningApplication *app, NSError *error) {
        if (error) {
            NSLog(@"Error opening file: %@", error);
        }
    }];
}

- (NSURL *)notepadAppURL {
    // Get main app bundle URL
    NSURL *extensionURL = [[NSBundle mainBundle] bundleURL];
    NSURL *appURL = [[[extensionURL URLByDeletingLastPathComponent]
                      URLByDeletingLastPathComponent]
                     URLByDeletingLastPathComponent];
    return appURL;
}

@end
```

**Info.plist** (in extension):
```xml
<key>NSExtension</key>
<dict>
    <key>NSExtensionPointIdentifier</key>
    <string>com.apple.FinderSync</string>
    
    <key>NSExtensionPrincipalClass</key>
    <string>FinderSync</string>
</dict>

<key>NSExtensionFileProviderSupportsEnumeration</key>
<false/>
```

**User Configuration**:
- System Preferences > Extensions > Finder
- Enable "Notepad++ Finder Sync"
- Grant Full Disk Access (if needed)

---

## Comparison Matrix

| Feature | Windows (Registry) | macOS (Info.plist) | macOS (Service) | macOS (Quick Action) | macOS (Finder Sync) |
|---------|-------------------|-------------------|----------------|---------------------|-------------------|
| File associations | ✅ | ✅ | ❌ | ❌ | ❌ |
| Default editor | ✅ | ✅ | ❌ | ❌ | ❌ |
| Context menu | ✅ (NppShell.dll) | ❌ | ✅ (Services submenu) | ✅ (direct) | ✅ (direct) |
| Multi-selection | ✅ | ✅ | ✅ | ✅ | ✅ |
| No user action | ✅ (installer) | ❌ (user sets default) | ❌ (user enables) | ❌ (user enables) | ❌ (user enables) |
| Sandboxed | ❌ | ✅ | ✅ | ✅ | ⚠️ (requires entitlements) |
| Notarization | N/A | ✅ | ✅ | ✅ | ✅ |

---

## Implementation Priority

### Phase 1 (MVP - Essential)
- [x] Document requirements
- [ ] **Info.plist file associations** - Critical for "Open with"
- [ ] **macOS Services** - Easy to implement, good UX

### Phase 2 (Enhanced UX)
- [ ] **Quick Action extension** - Best modern macOS UX
- [ ] **File Associations UI** - Preferences panel to check/set defaults

### Phase 3 (Power Users)
- [ ] **Finder Sync extension** - Most similar to Windows NppShell.dll
- [ ] **Badge support** - Show Notepad++ badge on associated files

---

## User Experience Flow

### Setting Notepad++ as Default Editor

**Windows**:
1. Install Notepad++
2. Run as Administrator
3. Settings > Preferences > File Association
4. Select extensions → automatically registered

**macOS** (Recommended):
1. Install Notepad++
2. Right-click any .txt file
3. Get Info
4. Open with: Notepad++
5. Click "Change All..."
6. Done

**Or via Notepad++ Preferences**:
1. Notepad++ > Preferences > File Associations
2. See list of extensions
3. Click "Set as Default Editor"
4. Opens System Preferences with instructions

### Using Context Menu

**Windows**:
- Right-click file → "Edit with Notepad++"

**macOS Option 1 (Services)**:
- Right-click file → Services → "Open in Notepad++"

**macOS Option 2 (Quick Action)**:
- Right-click file → Quick Actions → "Open in Notepad++"

**macOS Option 3 (Finder Sync)**:
- Right-click file → "Open in Notepad++"

---

## Code Organization

```
PowerEditor/cocoa/
├── FileAssociations/
│   ├── FileAssociationsController.h
│   ├── FileAssociationsController.mm
│   └── FileAssociationsPanel.xib
│
├── NotepadQuickAction/            # Quick Action extension
│   ├── Info.plist
│   ├── QuickActionHandler.h
│   └── QuickActionHandler.m
│
├── NotepadFinderSync/             # Finder Sync extension
│   ├── Info.plist
│   ├── FinderSync.h
│   └── FinderSync.m
│
└── Resources/
    ├── Info.plist                 # Main app (with Services, UTIs)
    └── Assets.xcassets/
        └── AppIcon.appiconset/
```

---

## Testing Checklist

### File Associations
- [ ] Install Notepad++
- [ ] Right-click .txt file → "Open with" lists Notepad++
- [ ] Set Notepad++ as default for .txt
- [ ] Double-click .txt opens in Notepad++
- [ ] Verify for 10+ different extensions
- [ ] Uninstall and verify associations removed

### Services
- [ ] Install Notepad++
- [ ] Enable Service in System Preferences
- [ ] Right-click .txt → Services → "Open in Notepad++"
- [ ] File opens in Notepad++
- [ ] Test with multiple files selected
- [ ] Test "Open Selection in Notepad++" with text

### Quick Action
- [ ] Install Notepad++
- [ ] Enable extension in System Preferences
- [ ] Right-click .txt → Quick Actions → "Open in Notepad++"
- [ ] Appears in Finder toolbar
- [ ] Works with multiple selections

### Finder Sync
- [ ] Install Notepad++
- [ ] Enable Finder Sync in System Preferences
- [ ] Right-click .txt → "Open in Notepad++"
- [ ] Test "Open in New Window"
- [ ] Works in all folders
- [ ] Test with 10+ files selected

---

## Security Considerations

### Code Signing
All components must be properly code signed:
```bash
# Sign main app
codesign --deep --force --verify --verbose \
  --sign "Developer ID Application: Your Name" \
  Notepad++.app

# Sign extensions
codesign --force --verify --verbose \
  --sign "Developer ID Application: Your Name" \
  Notepad++.app/Contents/PlugIns/NotepadQuickAction.appex

codesign --force --verify --verbose \
  --sign "Developer ID Application: Your Name" \
  Notepad++.app/Contents/PlugIns/NotepadFinderSync.appex
```

### Entitlements

**NotepadQuickAction.entitlements**:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
</dict>
</plist>
```

**NotepadFinderSync.entitlements**:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
    <key>com.apple.developer.finder-sync</key>
    <true/>
</dict>
</plist>
```

### Notarization
All extensions must pass notarization:
```bash
# Create app bundle
# Sign everything
# Create .dmg
# Submit for notarization
xcrun altool --notarize-app \
  --primary-bundle-id "org.notepad-plus-plus" \
  --username "your@apple.id" \
  --password "@keychain:AC_PASSWORD" \
  --file Notepad++.dmg

# Staple ticket
xcrun stapler staple Notepad++.dmg
```

---

## Migration from Windows

For users familiar with Windows Notepad++:

| Windows Feature | macOS Equivalent |
|----------------|------------------|
| Right-click → "Edit with Notepad++" | Right-click → Quick Actions → "Open in Notepad++" |
| Settings → File Association dialog | Preferences → File Associations (info only) |
| Automatic registry registration | User sets default via Finder "Get Info" |
| NppShell.dll context menu | Finder Sync extension |
| "Open with Notepad++" on install | User enables extensions after install |

---

## Summary

The macOS shell integration strategy uses **multiple complementary approaches**:

1. **Info.plist** - Essential for file associations and "Open with"
2. **Services** - Quick to implement, good fallback
3. **Quick Action** - Best modern macOS UX for Finder integration
4. **Finder Sync** - Most Windows-like, but requires user approval

This multi-pronged approach ensures Notepad++ is well-integrated while respecting macOS security and user experience guidelines.

### Key Differences from Windows:
- ✅ More secure (no automatic registry modification)
- ✅ Better sandboxing support
- ✅ Notarization-compatible
- ❌ Requires user action to enable
- ❌ Cannot automatically set as default
- ✅ More discoverable (system UI vs hidden registry)

### Next Steps:
1. Implement Info.plist associations
2. Add Services support to AppDelegate
3. Create Quick Action extension
4. (Optional) Create Finder Sync extension
5. Add preferences panel to guide users
6. Test on macOS 10.15, 11, 12, 13, 14
7. Submit for notarization
