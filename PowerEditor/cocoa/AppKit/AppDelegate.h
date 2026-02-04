//
//  AppDelegate.h
//  Notepad++ macOS
//
//  Copyright © 2024 Notepad++. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MainWindowController;

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (strong, nonatomic) MainWindowController *mainWindowController;
@property (strong, nonatomic) NSMutableArray<NSURL *> *recentFiles;

// Application lifecycle
- (void)applicationDidFinishLaunching:(NSNotification *)notification;
- (void)applicationWillTerminate:(NSNotification *)notification;
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender;

// File operations
- (void)openFiles:(NSArray<NSURL *> *)urls;
- (void)openFile:(NSURL *)url;
- (void)addRecentFile:(NSURL *)url;

// Menu actions
- (IBAction)newDocument:(id)sender;
- (IBAction)openDocument:(id)sender;
- (IBAction)openRecent:(id)sender;
- (IBAction)clearRecentFiles:(id)sender;
- (IBAction)showPreferences:(id)sender;
- (IBAction)showAbout:(id)sender;

// Services support
- (void)openSelection:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)error;
- (void)openSelectionAsText:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)error;

@end
