//
//  MainWindowController.mm
//  Notepad++ macOS
//
//  Copyright © 2024 Notepad++. All rights reserved.
//

#import "MainWindowController.h"
#import "DocumentController.h"
#import "ScintillaWrapper.h"
#import "Document.h"

static const CGFloat kWindowMinWidth = 800.0;
static const CGFloat kWindowMinHeight = 600.0;
static const CGFloat kStatusBarHeight = 22.0;

@interface MainWindowController ()

@property (strong, nonatomic) NSView *contentView;
@property (strong, nonatomic) NSView *editorContainer;
@property (strong, nonatomic) NSTextField *statusBarLabel;

@end

@implementation MainWindowController

- (instancetype)init {
    // Create window
    NSRect windowFrame = NSMakeRect(100, 100, 1024, 768);
    NSWindow *window = [[NSWindow alloc] initWithContentRect:windowFrame
                                                   styleMask:(NSWindowStyleMaskTitled |
                                                             NSWindowStyleMaskClosable |
                                                             NSWindowStyleMaskResizable |
                                                             NSWindowStyleMaskMiniaturizable)
                                                     backing:NSBackingStoreBuffered
                                                       defer:NO];
    
    self = [super initWithWindow:window];
    if (self) {
        window.title = @"Notepad++";
        window.minSize = NSMakeSize(kWindowMinWidth, kWindowMinHeight);
        window.delegate = self;
        
        // Initialize document controller
        _documentController = [[DocumentController alloc] init];
        
        [self setupUI];
    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Center window on screen
    [self.window center];
    
    // Restore window frame from preferences
    NSString *frameString = [[NSUserDefaults standardUserDefaults] stringForKey:@"MainWindowFrame"];
    if (frameString) {
        [self.window setFrameFromString:frameString];
    }
}

#pragma mark - UI Setup

- (void)setupUI {
    // Create main content view
    self.contentView = [[NSView alloc] initWithFrame:self.window.contentView.bounds];
    self.contentView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    self.window.contentView = self.contentView;
    
    // Setup toolbar
    [self setupToolbar];
    
    // Setup main editor area
    [self setupEditorArea];
    
    // Setup status bar
    [self setupStatusBar];
    
    // Layout subviews
    [self layoutSubviews];
}

- (void)setupToolbar {
    self.toolbar = [[NSToolbar alloc] initWithIdentifier:@"MainToolbar"];
    self.toolbar.delegate = self;
    self.toolbar.displayMode = NSToolbarDisplayModeIconAndLabel;
    self.toolbar.allowsUserCustomization = YES;
    self.toolbar.autosavesConfiguration = YES;
    self.window.toolbar = self.toolbar;
}

- (void)setupEditorArea {
    // Create tab view for multi-document support
    NSRect editorFrame = NSMakeRect(0, kStatusBarHeight, 
                                   self.contentView.bounds.size.width,
                                   self.contentView.bounds.size.height - kStatusBarHeight);
    
    self.editorContainer = [[NSView alloc] initWithFrame:editorFrame];
    self.editorContainer.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    
    // Create tab view
    self.tabView = [[NSTabView alloc] initWithFrame:self.editorContainer.bounds];
    self.tabView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    self.tabView.tabViewType = NSTopTabsBezelBorder;
    
    [self.editorContainer addSubview:self.tabView];
    [self.contentView addSubview:self.editorContainer];
    
    // Create initial document
    [self newDocument:nil];
}

- (void)setupStatusBar {
    NSRect statusBarFrame = NSMakeRect(0, 0, 
                                      self.contentView.bounds.size.width,
                                      kStatusBarHeight);
    
    self.statusBarLabel = [[NSTextField alloc] initWithFrame:statusBarFrame];
    self.statusBarLabel.autoresizingMask = NSViewWidthSizable | NSViewMaxYMargin;
    self.statusBarLabel.editable = NO;
    self.statusBarLabel.bordered = NO;
    self.statusBarLabel.backgroundColor = [NSColor controlBackgroundColor];
    self.statusBarLabel.stringValue = @"Line: 1 | Col: 1 | UTF-8 | LF";
    
    [self.contentView addSubview:self.statusBarLabel];
    self.statusBar = self.statusBarLabel;
}

- (void)layoutSubviews {
    NSRect bounds = self.contentView.bounds;
    
    // Status bar at bottom
    NSRect statusBarFrame = NSMakeRect(0, 0, bounds.size.width, kStatusBarHeight);
    self.statusBarLabel.frame = statusBarFrame;
    
    // Editor area above status bar
    NSRect editorFrame = NSMakeRect(0, kStatusBarHeight,
                                   bounds.size.width,
                                   bounds.size.height - kStatusBarHeight);
    self.editorContainer.frame = editorFrame;
}

#pragma mark - NSWindowDelegate

- (BOOL)windowShouldClose:(NSWindow *)sender {
    // Check for unsaved changes
    // TODO: Implement unsaved changes check
    return YES;
}

- (void)windowWillClose:(NSNotification *)notification {
    // Save window frame
    NSString *frameString = [self.window stringWithSavedFrame];
    [[NSUserDefaults standardUserDefaults] setObject:frameString forKey:@"MainWindowFrame"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - NSToolbarDelegate

- (NSArray<NSToolbarItemIdentifier> *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
    return @[@"New", @"Open", @"Save", 
             NSToolbarFlexibleSpaceItemIdentifier,
             @"Cut", @"Copy", @"Paste",
             NSToolbarFlexibleSpaceItemIdentifier,
             @"Find"];
}

- (NSArray<NSToolbarItemIdentifier> *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
    return @[@"New", @"Open", @"Save", @"SaveAs",
             @"Cut", @"Copy", @"Paste",
             @"Undo", @"Redo",
             @"Find", @"Replace",
             @"ZoomIn", @"ZoomOut",
             NSToolbarSpaceItemIdentifier,
             NSToolbarFlexibleSpaceItemIdentifier];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar 
     itemForItemIdentifier:(NSToolbarItemIdentifier)itemIdentifier 
 willBeInsertedIntoToolbar:(BOOL)flag {
    
    NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
    
    if ([itemIdentifier isEqualToString:@"New"]) {
        item.label = @"New";
        item.paletteLabel = @"New";
        item.toolTip = @"Create a new document";
        item.image = [NSImage imageNamed:NSImageNameAddTemplate];
        item.target = self;
        item.action = @selector(newDocument:);
    } else if ([itemIdentifier isEqualToString:@"Open"]) {
        item.label = @"Open";
        item.paletteLabel = @"Open";
        item.toolTip = @"Open a file";
        item.image = [NSImage imageNamed:NSImageNameFolderSmart];
        item.target = self;
        item.action = @selector(openDocument:);
    } else if ([itemIdentifier isEqualToString:@"Save"]) {
        item.label = @"Save";
        item.paletteLabel = @"Save";
        item.toolTip = @"Save the current document";
        item.image = [NSImage imageNamed:NSImageNameActionTemplate];
        item.target = self;
        item.action = @selector(saveDocument:);
    } else if ([itemIdentifier isEqualToString:@"Cut"]) {
        item.label = @"Cut";
        item.paletteLabel = @"Cut";
        item.toolTip = @"Cut";
        item.image = [NSImage imageNamed:NSImageNameCutTemplate];
        item.target = self;
        item.action = @selector(cut:);
    } else if ([itemIdentifier isEqualToString:@"Copy"]) {
        item.label = @"Copy";
        item.paletteLabel = @"Copy";
        item.toolTip = @"Copy";
        item.image = [NSImage imageNamed:NSImageNameCopyTemplate];
        item.target = self;
        item.action = @selector(copy:);
    } else if ([itemIdentifier isEqualToString:@"Paste"]) {
        item.label = @"Paste";
        item.paletteLabel = @"Paste";
        item.toolTip = @"Paste";
        item.image = [NSImage imageNamed:NSImageNamePasteTemplate];
        item.target = self;
        item.action = @selector(paste:);
    } else if ([itemIdentifier isEqualToString:@"Find"]) {
        item.label = @"Find";
        item.paletteLabel = @"Find";
        item.toolTip = @"Find text";
        item.image = [NSImage imageNamed:NSImageNameQuickLookTemplate];
        item.target = self;
        item.action = @selector(find:);
    }
    
    return item;
}

#pragma mark - Document Operations

- (void)newDocument:(id)sender {
    [self.documentController createNewDocument];
    [self updateUIForCurrentDocument];
    [self updateEditorView];
}

- (void)newDocumentWithText:(NSString *)text {
    [self.documentController createNewDocumentWithText:text];
    [self updateUIForCurrentDocument];
    [self updateEditorView];
}

- (void)openFile:(NSURL *)url {
    [self.documentController openDocument:url];
    [self updateUIForCurrentDocument];
    [self updateEditorView];
}

- (void)openDocument:(id)sender {
    // This is called from toolbar - delegate to AppDelegate
    [[NSApp delegate] performSelector:@selector(openDocument:) withObject:sender];
}

- (void)saveDocument:(id)sender {
    [self.documentController saveCurrentDocument];
}

- (void)saveDocumentAs:(id)sender {
    [self.documentController saveCurrentDocumentAs];
}

- (void)closeDocument:(id)sender {
    [self.documentController closeCurrentDocument];
    [self updateUIForCurrentDocument];
}

#pragma mark - Edit Operations

- (void)undo:(id)sender {
    ScintillaWrapper *wrapper = [self.documentController currentWrapper];
    if (wrapper) {
        [wrapper undo];
    }
}

- (void)redo:(id)sender {
    ScintillaWrapper *wrapper = [self.documentController currentWrapper];
    if (wrapper) {
        [wrapper redo];
    }
}

- (void)cut:(id)sender {
    ScintillaWrapper *wrapper = [self.documentController currentWrapper];
    if (wrapper) {
        [wrapper cut];
    }
}

- (void)copy:(id)sender {
    ScintillaWrapper *wrapper = [self.documentController currentWrapper];
    if (wrapper) {
        [wrapper copy];
    }
}

- (void)paste:(id)sender {
    ScintillaWrapper *wrapper = [self.documentController currentWrapper];
    if (wrapper) {
        [wrapper paste];
    }
}

- (void)selectAll:(id)sender {
    ScintillaWrapper *wrapper = [self.documentController currentWrapper];
    if (wrapper) {
        [wrapper selectAll];
    }
}

#pragma mark - Search Operations

- (void)find:(id)sender {
    // TODO: Implement find dialog
    NSLog(@"Find");
}

- (void)findNext:(id)sender {
    // TODO: Implement find next
    NSLog(@"Find Next");
}

- (void)findPrevious:(id)sender {
    // TODO: Implement find previous
    NSLog(@"Find Previous");
}

- (void)replace:(id)sender {
    // TODO: Implement replace dialog
    NSLog(@"Replace");
}

#pragma mark - View Operations

- (void)toggleToolbar:(id)sender {
    [self.window toggleToolbarShown:sender];
}

- (void)toggleStatusBar:(id)sender {
    BOOL isHidden = self.statusBarLabel.isHidden;
    self.statusBarLabel.hidden = !isHidden;
    [self layoutSubviews];
}

- (void)zoomIn:(id)sender {
    ScintillaWrapper *wrapper = [self.documentController currentWrapper];
    if (wrapper) {
        [wrapper zoomIn];
    }
}

- (void)zoomOut:(id)sender {
    ScintillaWrapper *wrapper = [self.documentController currentWrapper];
    if (wrapper) {
        [wrapper zoomOut];
    }
}

- (void)resetZoom:(id)sender {
    ScintillaWrapper *wrapper = [self.documentController currentWrapper];
    if (wrapper) {
        [wrapper resetZoom];
    }
}

#pragma mark - UI Updates

- (void)updateUIForCurrentDocument {
    // Update window title
    NSString *filename = self.documentController.currentDocumentName;
    if (filename) {
        self.window.title = [NSString stringWithFormat:@"%@ - Notepad++", filename];
    } else {
        self.window.title = @"Notepad++";
    }
    
    // Update status bar
    [self updateStatusBar];
}

- (void)updateStatusBar {
    ScintillaWrapper *wrapper = [self.documentController currentWrapper];
    if (wrapper) {
        NSInteger line, column;
        [wrapper getCursorPosition:&line column:&column];
        
        Document *doc = self.documentController.currentDocument;
        NSString *statusText = [NSString stringWithFormat:@"Line: %ld | Col: %ld | %@ | %@",
                               (long)line, (long)column,
                               doc.encodingName, doc.lineEndingName];
        self.statusBarLabel.stringValue = statusText;
    } else {
        self.statusBarLabel.stringValue = @"Line: 1 | Col: 1 | UTF-8 | LF";
    }
}

- (void)updateEditorView {
    // Get current wrapper
    ScintillaWrapper *wrapper = [self.documentController currentWrapper];
    if (!wrapper) {
        return;
    }
    
    // Create ScintillaView if needed
    if (!wrapper.scintillaView) {
        NSRect editorFrame = self.tabView.selectedTabViewItem.view.bounds;
        [wrapper createScintillaViewWithFrame:editorFrame];
        [wrapper loadDocumentContent];
    }
    
    // Add to current tab
    NSTabViewItem *currentTab = self.tabView.selectedTabViewItem;
    if (currentTab && wrapper.scintillaView) {
        // Remove existing subviews
        for (NSView *subview in currentTab.view.subviews) {
            [subview removeFromSuperview];
        }
        
        // Add ScintillaView
        NSView *scintillaView = (NSView *)wrapper.scintillaView;
        scintillaView.frame = currentTab.view.bounds;
        scintillaView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        [currentTab.view addSubview:scintillaView];
    }
}

@end
