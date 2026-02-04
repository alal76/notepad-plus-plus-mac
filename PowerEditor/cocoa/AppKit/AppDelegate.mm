//
//  AppDelegate.mm
//  Notepad++ macOS
//
//  Copyright © 2024 Notepad++. All rights reserved.
//

#import "AppDelegate.h"
#import "MainWindowController.h"

static NSString * const kRecentFilesKey = @"RecentFiles";
static const NSUInteger kMaxRecentFiles = 10;

@implementation AppDelegate

- (instancetype)init {
    self = [super init];
    if (self) {
        _recentFiles = [[NSMutableArray alloc] init];
        [self loadRecentFiles];
    }
    return self;
}

#pragma mark - Application Lifecycle

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    // Register for URL events (for file associations)
    [[NSAppleEventManager sharedAppleEventManager] 
        setEventHandler:self
        andSelector:@selector(handleURLEvent:withReplyEvent:)
        forEventClass:kInternetEventClass
        andEventID:kAEGetURL];
    
    // Create main window controller
    self.mainWindowController = [[MainWindowController alloc] init];
    [self.mainWindowController showWindow:self];
    
    // Set up services
    [NSApp setServicesProvider:self];
    
    NSLog(@"Notepad++ macOS launched successfully");
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    // Save application state
    [self saveRecentFiles];
    
    // Clean up resources
    self.mainWindowController = nil;
    
    NSLog(@"Notepad++ macOS terminating");
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename {
    NSURL *url = [NSURL fileURLWithPath:filename];
    [self openFile:url];
    return YES;
}

- (void)application:(NSApplication *)sender openFiles:(NSArray<NSString *> *)filenames {
    for (NSString *filename in filenames) {
        NSURL *url = [NSURL fileURLWithPath:filename];
        [self openFile:url];
    }
    [sender replyToOpenOrPrint:NSApplicationDelegateReplySuccess];
}

#pragma mark - File Operations

- (void)openFiles:(NSArray<NSURL *> *)urls {
    for (NSURL *url in urls) {
        [self openFile:url];
    }
}

- (void)openFile:(NSURL *)url {
    if (!url) {
        return;
    }
    
    // Check if file exists
    if (![[NSFileManager defaultManager] fileExistsAtPath:url.path]) {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"File Not Found";
        alert.informativeText = [NSString stringWithFormat:@"The file '%@' could not be found.", url.lastPathComponent];
        alert.alertStyle = NSAlertStyleWarning;
        [alert addButtonWithTitle:@"OK"];
        [alert runModal];
        return;
    }
    
    // Add to recent files
    [self addRecentFile:url];
    
    // Open in main window controller
    [self.mainWindowController openFile:url];
}

- (void)addRecentFile:(NSURL *)url {
    // Remove if already exists
    [self.recentFiles removeObject:url];
    
    // Add to beginning
    [self.recentFiles insertObject:url atIndex:0];
    
    // Limit to max recent files
    if (self.recentFiles.count > kMaxRecentFiles) {
        [self.recentFiles removeObjectsInRange:NSMakeRange(kMaxRecentFiles, self.recentFiles.count - kMaxRecentFiles)];
    }
    
    // Update menu
    [self updateRecentFilesMenu];
    
    // Save
    [self saveRecentFiles];
}

#pragma mark - Menu Actions

- (IBAction)newDocument:(id)sender {
    [self.mainWindowController newDocument:sender];
}

- (IBAction)openDocument:(id)sender {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    openPanel.canChooseFiles = YES;
    openPanel.canChooseDirectories = NO;
    openPanel.allowsMultipleSelection = YES;
    openPanel.message = @"Choose files to open";
    
    [openPanel beginSheetModalForWindow:self.mainWindowController.window completionHandler:^(NSModalResponse result) {
        if (result == NSModalResponseOK) {
            [self openFiles:openPanel.URLs];
        }
    }];
}

- (IBAction)openRecent:(id)sender {
    NSMenuItem *menuItem = (NSMenuItem *)sender;
    NSInteger index = menuItem.tag;
    
    if (index >= 0 && index < self.recentFiles.count) {
        NSURL *url = self.recentFiles[index];
        [self openFile:url];
    }
}

- (IBAction)clearRecentFiles:(id)sender {
    [self.recentFiles removeAllObjects];
    [self updateRecentFilesMenu];
    [self saveRecentFiles];
}

- (IBAction)showPreferences:(id)sender {
    // TODO: Implement preferences window
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Preferences";
    alert.informativeText = @"Preferences window is not yet implemented.";
    alert.alertStyle = NSAlertStyleInformational;
    [alert addButtonWithTitle:@"OK"];
    [alert runModal];
}

- (IBAction)showAbout:(id)sender {
    NSMutableDictionary *options = [NSMutableDictionary dictionary];
    options[NSAboutPanelOptionApplicationName] = @"Notepad++";
    options[NSAboutPanelOptionApplicationVersion] = @"8.6.0";
    options[NSAboutPanelOptionVersion] = @"macOS Port";
    options[NSAboutPanelOptionCopyright] = @"Copyright © 2024 Notepad++. All rights reserved.";
    options[NSAboutPanelOptionApplicationIcon] = [NSApp applicationIconImage];
    
    [NSApp orderFrontStandardAboutPanelWithOptions:options];
}

#pragma mark - Services

- (void)openSelection:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)error {
    NSArray *types = pboard.types;
    
    if ([types containsObject:NSPasteboardTypeFileURL]) {
        // Open files
        NSArray *files = [pboard readObjectsForClasses:@[[NSURL class]] options:nil];
        [self openFiles:files];
    } else if ([types containsObject:NSPasteboardTypeString]) {
        // Open text as new document
        NSString *text = [pboard stringForType:NSPasteboardTypeString];
        [self.mainWindowController newDocumentWithText:text];
    }
}

- (void)openSelectionAsText:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)error {
    NSString *text = [pboard stringForType:NSPasteboardTypeString];
    if (text) {
        [self.mainWindowController newDocumentWithText:text];
    }
}

#pragma mark - URL Handling

- (void)handleURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent {
    NSString *urlString = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
    NSURL *url = [NSURL URLWithString:urlString];
    
    if (url && [url isFileURL]) {
        [self openFile:url];
    }
}

#pragma mark - Recent Files Management

- (void)loadRecentFiles {
    NSArray *paths = [[NSUserDefaults standardUserDefaults] arrayForKey:kRecentFilesKey];
    if (paths) {
        NSMutableArray *urls = [NSMutableArray array];
        for (NSString *path in paths) {
            NSURL *url = [NSURL fileURLWithPath:path];
            if (url && [[NSFileManager defaultManager] fileExistsAtPath:path]) {
                [urls addObject:url];
            }
        }
        self.recentFiles = urls;
    }
}

- (void)saveRecentFiles {
    NSMutableArray *paths = [NSMutableArray array];
    for (NSURL *url in self.recentFiles) {
        [paths addObject:url.path];
    }
    [[NSUserDefaults standardUserDefaults] setObject:paths forKey:kRecentFilesKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)updateRecentFilesMenu {
    // Find the "Open Recent" menu
    NSMenu *mainMenu = [NSApp mainMenu];
    NSMenuItem *fileMenuItem = [mainMenu itemWithTitle:@"File"];
    if (!fileMenuItem) {
        return;
    }
    
    NSMenu *fileMenu = fileMenuItem.submenu;
    NSMenuItem *openRecentMenuItem = [fileMenu itemWithTitle:@"Open Recent"];
    if (!openRecentMenuItem) {
        return;
    }
    
    NSMenu *recentMenu = openRecentMenuItem.submenu;
    if (!recentMenu) {
        return;
    }
    
    // Clear existing items
    [recentMenu removeAllItems];
    
    // Add recent files
    if (self.recentFiles.count > 0) {
        for (NSUInteger i = 0; i < self.recentFiles.count; i++) {
            NSURL *url = self.recentFiles[i];
            NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:url.lastPathComponent
                                                         action:@selector(openRecent:)
                                                  keyEquivalent:@""];
            item.target = self;
            item.tag = i;
            item.toolTip = url.path;
            [recentMenu addItem:item];
        }
        
        // Add separator and clear menu item
        [recentMenu addItem:[NSMenuItem separatorItem]];
        NSMenuItem *clearItem = [[NSMenuItem alloc] initWithTitle:@"Clear Menu"
                                                          action:@selector(clearRecentFiles:)
                                                   keyEquivalent:@""];
        clearItem.target = self;
        [recentMenu addItem:clearItem];
    } else {
        // Add "No Recent Files" item
        NSMenuItem *emptyItem = [[NSMenuItem alloc] initWithTitle:@"No Recent Files"
                                                          action:nil
                                                   keyEquivalent:@""];
        emptyItem.enabled = NO;
        [recentMenu addItem:emptyItem];
    }
}

@end
