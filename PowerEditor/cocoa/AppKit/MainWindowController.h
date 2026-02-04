//
//  MainWindowController.h
//  Notepad++ macOS
//
//  Copyright © 2024 Notepad++. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class DocumentController;
@class ScintillaView;

@interface MainWindowController : NSWindowController <NSWindowDelegate, NSToolbarDelegate>

@property (strong, nonatomic) DocumentController *documentController;
@property (strong, nonatomic) NSTabView *tabView;
@property (strong, nonatomic) NSToolbar *toolbar;
@property (strong, nonatomic) NSSplitView *splitView;
@property (weak, nonatomic) NSTextField *statusBar;

// Document operations
- (void)newDocument:(id)sender;
- (void)newDocumentWithText:(NSString *)text;
- (void)openFile:(NSURL *)url;
- (void)saveDocument:(id)sender;
- (void)saveDocumentAs:(id)sender;
- (void)closeDocument:(id)sender;

// Edit operations
- (void)undo:(id)sender;
- (void)redo:(id)sender;
- (void)cut:(id)sender;
- (void)copy:(id)sender;
- (void)paste:(id)sender;
- (void)selectAll:(id)sender;

// Search operations
- (void)find:(id)sender;
- (void)findNext:(id)sender;
- (void)findPrevious:(id)sender;
- (void)replace:(id)sender;

// View operations
- (void)toggleToolbar:(id)sender;
- (void)toggleStatusBar:(id)sender;
- (void)zoomIn:(id)sender;
- (void)zoomOut:(id)sender;
- (void)resetZoom:(id)sender;

@end
