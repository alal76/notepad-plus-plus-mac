//
//  TabBarController_Example.mm
//  Notepad++ macOS - TabBarController Usage Example
//
//  Copyright © 2024 Notepad++. All rights reserved.
//
//  This file demonstrates how to integrate TabBarController into a window controller
//

#import <Cocoa/Cocoa.h>
#import "TabBarController.h"

/**
 * Example window controller demonstrating TabBarController integration
 */
@interface ExampleWindowController : NSWindowController <TabBarControllerDelegate>

@property (nonatomic, strong) TabBarController *tabBar;
@property (nonatomic, strong) NSMutableArray *documents;

@end

@implementation ExampleWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    self.documents = [NSMutableArray array];
    
    // Create and configure tab bar
    NSRect tabBarFrame = NSMakeRect(0, 
                                    self.window.contentView.bounds.size.height - 28, 
                                    self.window.contentView.bounds.size.width, 
                                    28);
    
    self.tabBar = [[TabBarController alloc] initWithFrame:tabBarFrame];
    self.tabBar.delegate = self;
    self.tabBar.autoresizingMask = NSViewWidthSizable | NSViewMinYMargin;
    
    // Optional: Customize appearance
    // self.tabBar.tabMaxWidth = 250.0;
    // self.tabBar.tabFont = [NSFont systemFontOfSize:13.0];
    
    [self.window.contentView addSubview:self.tabBar];
    
    // Example: Add some initial tabs
    [self createExampleTabs];
}

- (void)createExampleTabs {
    // Tab 1: Normal document
    TabItem *tab1 = [[TabItem alloc] initWithTitle:@"Welcome.txt"];
    tab1.tooltip = @"Welcome document";
    tab1.representedObject = @{@"path": @"/Documents/Welcome.txt"};
    [self.tabBar addTab:tab1];
    
    // Tab 2: Modified document
    TabItem *tab2 = [[TabItem alloc] initWithTitle:@"README.md"];
    tab2.isModified = YES;
    tab2.tooltip = @"README.md (modified)";
    tab2.representedObject = @{@"path": @"/Documents/README.md"};
    [self.tabBar addTab:tab2];
    
    // Tab 3: Another document
    TabItem *tab3 = [[TabItem alloc] initWithTitle:@"TODO.txt"];
    tab3.representedObject = @{@"path": @"/Documents/TODO.txt"};
    [self.tabBar addTab:tab3];
    
    // Select the first tab
    [self.tabBar selectTabAtIndex:0];
}

#pragma mark - TabBarControllerDelegate

- (void)tabBarController:(TabBarController *)controller 
           didSelectTab:(TabItem *)tabItem 
                atIndex:(NSInteger)index {
    NSLog(@"Selected tab: %@ at index %ld", tabItem.title, (long)index);
    
    // Load the document associated with this tab
    id documentData = tabItem.representedObject;
    if (documentData) {
        [self loadDocument:documentData];
    }
}

- (BOOL)tabBarController:(TabBarController *)controller 
          shouldCloseTab:(TabItem *)tabItem 
                 atIndex:(NSInteger)index {
    // Check if document has unsaved changes
    if (tabItem.isModified) {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"Do you want to save changes?";
        alert.informativeText = [NSString stringWithFormat:@"The document \"%@\" has unsaved changes.", tabItem.title];
        [alert addButtonWithTitle:@"Save"];
        [alert addButtonWithTitle:@"Don't Save"];
        [alert addButtonWithTitle:@"Cancel"];
        
        NSModalResponse response = [alert runModal];
        
        switch (response) {
            case NSAlertFirstButtonReturn: // Save
                [self saveDocument:tabItem.representedObject];
                return YES;
                
            case NSAlertSecondButtonReturn: // Don't Save
                return YES;
                
            case NSAlertThirdButtonReturn: // Cancel
            default:
                return NO;
        }
    }
    
    return YES;
}

- (void)tabBarController:(TabBarController *)controller 
            didCloseTab:(TabItem *)tabItem 
                atIndex:(NSInteger)index {
    NSLog(@"Closed tab: %@ at index %ld", tabItem.title, (long)index);
    
    // Clean up document resources
    id documentData = tabItem.representedObject;
    if (documentData) {
        [self.documents removeObject:documentData];
    }
}

- (void)tabBarController:(TabBarController *)controller 
      didMoveTabFromIndex:(NSInteger)fromIndex 
                  toIndex:(NSInteger)toIndex {
    NSLog(@"Moved tab from index %ld to %ld", (long)fromIndex, (long)toIndex);
    
    // Update internal document order
    if (fromIndex < self.documents.count && toIndex < self.documents.count) {
        id document = self.documents[fromIndex];
        [self.documents removeObjectAtIndex:fromIndex];
        [self.documents insertObject:document atIndex:toIndex];
    }
}

- (void)tabBarController:(TabBarController *)controller 
closeButtonClickedForTab:(TabItem *)tabItem 
                 atIndex:(NSInteger)index {
    NSLog(@"Close button clicked for tab: %@", tabItem.title);
}

#pragma mark - Menu Actions

- (IBAction)newDocument:(id)sender {
    static NSInteger documentCounter = 1;
    
    TabItem *newTab = [[TabItem alloc] initWithTitle:[NSString stringWithFormat:@"Untitled %ld", (long)documentCounter++]];
    newTab.representedObject = @{@"path": @""};
    
    [self.tabBar addTab:newTab];
    [self.tabBar selectTab:newTab];
    
    NSLog(@"Created new document");
}

- (IBAction)closeCurrentDocument:(id)sender {
    if (self.tabBar.selectedIndex >= 0) {
        [self.tabBar removeTabAtIndex:self.tabBar.selectedIndex];
    }
}

- (IBAction)selectNextTab:(id)sender {
    NSInteger nextIndex = self.tabBar.selectedIndex + 1;
    if (nextIndex < self.tabBar.tabs.count) {
        [self.tabBar selectTabAtIndex:nextIndex];
    }
}

- (IBAction)selectPreviousTab:(id)sender {
    NSInteger prevIndex = self.tabBar.selectedIndex - 1;
    if (prevIndex >= 0) {
        [self.tabBar selectTabAtIndex:prevIndex];
    }
}

#pragma mark - Document Management (Placeholder Methods)

- (void)loadDocument:(id)documentData {
    // Load document content into editor view
    NSLog(@"Loading document: %@", documentData);
}

- (void)saveDocument:(id)documentData {
    // Save document content
    NSLog(@"Saving document: %@", documentData);
}

#pragma mark - Simulating Document Changes

- (void)markCurrentDocumentAsModified:(BOOL)modified {
    if (self.tabBar.selectedIndex >= 0) {
        TabItem *currentTab = [self.tabBar tabAtIndex:self.tabBar.selectedIndex];
        currentTab.isModified = modified;
        [self.tabBar setNeedsDisplay:YES];
    }
}

@end

#pragma mark - Usage Notes

/*
 USAGE EXAMPLE IN APPLICATION DELEGATE:
 
 @implementation AppDelegate
 
 - (void)applicationDidFinishLaunching:(NSNotification *)notification {
     ExampleWindowController *windowController = [[ExampleWindowController alloc] initWithWindow:mainWindow];
     [windowController showWindow:nil];
 }
 
 @end
 
 
 KEY INTEGRATION POINTS:
 
 1. Window Setup:
    - Add TabBarController as subview at top of content view
    - Set autoresizing mask for width and top margin
    - Configure delegate to handle tab events
 
 2. Tab Creation:
    - Create TabItem instances for each document
    - Set title, tooltip, and representedObject
    - Add to tab bar with addTab: or insertTab:atIndex:
 
 3. Tab Selection:
    - Listen for didSelectTab: delegate callback
    - Load corresponding document into editor
    - Update UI to reflect current document
 
 4. Tab Closure:
    - Implement shouldCloseTab: to check for unsaved changes
    - Show save dialog if needed
    - Handle didCloseTab: to clean up resources
 
 5. Modified State:
    - Update tab.isModified when document changes
    - Call [tabBar setNeedsDisplay:YES] to refresh
 
 6. Menu Integration:
    - Connect menu items to selectNextTab:/selectPreviousTab:
    - Implement Cmd+W for closeCurrentDocument:
    - Add Cmd+T for newDocument:
 
 7. Keyboard Shortcuts (recommended):
    - Cmd+T: New Tab
    - Cmd+W: Close Tab
    - Cmd+Shift+[: Previous Tab
    - Cmd+Shift+]: Next Tab
    - Cmd+1-9: Select Tab 1-9
 
 
 BEST PRACTICES:
 
 - Always check selectedIndex bounds before accessing tabs
 - Update tab.isModified whenever document content changes
 - Use representedObject to link tabs to document instances
 - Implement shouldCloseTab: to prevent accidental data loss
 - Call setNeedsDisplay: after programmatic tab property changes
 - Handle edge cases: empty tab bar, single tab, many tabs
 
 
 COMMON PATTERNS:
 
 // Add tab when opening document
 - (void)openDocument:(NSURL *)url {
     Document *doc = [self loadDocumentFromURL:url];
     TabItem *tab = [[TabItem alloc] initWithTitle:url.lastPathComponent];
     tab.representedObject = doc;
     [self.tabBar addTab:tab];
     [self.tabBar selectTab:tab];
 }
 
 // Update modified state on text change
 - (void)textDidChange:(NSNotification *)notification {
     if (self.tabBar.selectedIndex >= 0) {
         TabItem *tab = [self.tabBar tabAtIndex:self.tabBar.selectedIndex];
         tab.isModified = YES;
         [self.tabBar setNeedsDisplay:YES];
     }
 }
 
 // Clear modified state after save
 - (void)documentDidSave {
     if (self.tabBar.selectedIndex >= 0) {
         TabItem *tab = [self.tabBar tabAtIndex:self.tabBar.selectedIndex];
         tab.isModified = NO;
         [self.tabBar setNeedsDisplay:YES];
     }
 }
 
 */
