//
//  AppDelegate+SessionManager.mm
//  Notepad++ macOS - SessionManager Integration Example
//
//  Copyright © 2024 Notepad++. All rights reserved.
//
//  This is an example/reference file showing how to integrate SessionManager
//  with AppDelegate. Copy relevant methods to your actual AppDelegate implementation.
//

#import "AppDelegate+SessionManager.h"
#import "../SessionManager.h"
#import "../../AppKit/DocumentController.h"
#import "../../AppKit/MainWindowController.h"

@implementation AppDelegate (SessionManagerIntegration)

#pragma mark - Session Management Setup

- (void)setupSessionManagement:(DocumentController *)documentController {
    // This method should be called in applicationDidFinishLaunching:
    
    SessionManager *sessionManager = [SessionManager sharedManager];
    
    // Configure session preferences (optional - can be set by user preferences UI)
    // sessionManager.autoSaveOnQuit = YES;        // Default is YES
    // sessionManager.autoRestoreOnLaunch = NO;    // Default is NO (user opt-in)
    
    // Attempt to restore previous session if enabled
    BOOL sessionRestored = [self restorePreviousSession:documentController];
    
    if (!sessionRestored) {
        // No session was restored, create a new empty document
        if (documentController.documents.count == 0) {
            [documentController createNewDocument];
        }
    }
    
    NSLog(@"Session management initialized. Auto-save: %@, Auto-restore: %@",
          sessionManager.autoSaveOnQuit ? @"YES" : @"NO",
          sessionManager.autoRestoreOnLaunch ? @"YES" : @"NO");
}

- (void)saveSessionOnTerminate:(DocumentController *)documentController {
    // This method should be called in applicationWillTerminate:
    
    [SessionManager saveSessionOnQuit:documentController];
    
    NSLog(@"Application terminating - session saved");
}

- (BOOL)restorePreviousSession:(DocumentController *)documentController {
    // Check if auto-restore is enabled and a session exists
    SessionManager *sessionManager = [SessionManager sharedManager];
    
    if (!sessionManager.autoRestoreOnLaunch) {
        NSLog(@"Auto-restore is disabled");
        return NO;
    }
    
    if (![sessionManager hasExistingSession]) {
        NSLog(@"No existing session to restore");
        return NO;
    }
    
    // Restore the session
    NSError *error = nil;
    BOOL success = [sessionManager loadSession:documentController error:&error];
    
    if (success) {
        NSLog(@"Session restored successfully");
    } else {
        NSLog(@"Failed to restore session: %@", error ? error.localizedDescription : @"Unknown error");
    }
    
    return success;
}

#pragma mark - Window State Management

- (void)saveWindowStateForSession:(NSWindow *)window {
    if (!window) {
        return;
    }
    
    // Collect window state
    NSMutableDictionary *windowState = [NSMutableDictionary dictionary];
    
    // Save window frame
    windowState[@"frame"] = NSStringFromRect(window.frame);
    
    // Save maximized state
    windowState[@"isMaximized"] = @(window.isZoomed);
    
    // Save fullscreen state
    BOOL isFullScreen = (window.styleMask & NSWindowStyleMaskFullScreen) != 0;
    windowState[@"isFullScreen"] = @(isFullScreen);
    
    // Save window state to session
    SessionManager *sessionManager = [SessionManager sharedManager];
    [sessionManager saveWindowState:windowState];
    
    NSLog(@"Window state saved: %@", windowState);
}

- (void)restoreWindowStateFromSession:(NSWindow *)window {
    if (!window) {
        return;
    }
    
    // Load window state from session
    SessionManager *sessionManager = [SessionManager sharedManager];
    NSDictionary *windowState = [sessionManager loadWindowState];
    
    if (!windowState || windowState.count == 0) {
        NSLog(@"No window state to restore");
        return;
    }
    
    // Restore window frame
    NSString *frameString = windowState[@"frame"];
    if (frameString) {
        NSRect frame = NSRectFromString(frameString);
        
        // Validate frame is within screen bounds
        NSRect screenFrame = [[NSScreen mainScreen] visibleFrame];
        if (NSIntersectsRect(frame, screenFrame)) {
            [window setFrame:frame display:YES animate:NO];
            NSLog(@"Window frame restored: %@", frameString);
        } else {
            NSLog(@"Saved window frame is outside screen bounds, using default");
        }
    }
    
    // Restore maximized state
    NSNumber *isMaximized = windowState[@"isMaximized"];
    if (isMaximized && [isMaximized boolValue]) {
        [window zoom:nil];
        NSLog(@"Window maximized state restored");
    }
    
    // Note: Fullscreen restoration is more complex and may require user interaction
    // It's generally better to let the user manually enter fullscreen
    NSNumber *isFullScreen = windowState[@"isFullScreen"];
    if (isFullScreen && [isFullScreen boolValue]) {
        NSLog(@"Previous session was in fullscreen mode (manual restoration required)");
        // Uncomment to automatically restore fullscreen:
        // [window toggleFullScreen:nil];
    }
}

@end

#pragma mark - Example AppDelegate Implementation

/**
 * EXAMPLE USAGE IN YOUR ACTUAL AppDelegate.mm:
 *
 * - (void)applicationDidFinishLaunching:(NSNotification *)notification {
 *     // ... existing initialization code ...
 *     
 *     // Initialize document controller
 *     self.documentController = [[DocumentController alloc] init];
 *     
 *     // Setup session management
 *     [self setupSessionManagement:self.documentController];
 *     
 *     // Restore window state if available
 *     if (self.mainWindowController && self.mainWindowController.window) {
 *         [self restoreWindowStateFromSession:self.mainWindowController.window];
 *     }
 *     
 *     // ... rest of your launch code ...
 * }
 *
 * - (void)applicationWillTerminate:(NSNotification *)notification {
 *     // Save window state before terminating
 *     if (self.mainWindowController && self.mainWindowController.window) {
 *         [self saveWindowStateForSession:self.mainWindowController.window];
 *     }
 *     
 *     // Save session
 *     [self saveSessionOnTerminate:self.documentController];
 *     
 *     // ... other cleanup code ...
 * }
 *
 * - (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
 *     // Check for unsaved changes before terminating
 *     if ([self.documentController hasUnsavedChanges]) {
 *         NSAlert *alert = [[NSAlert alloc] init];
 *         alert.messageText = @"Do you want to save your changes?";
 *         alert.informativeText = @"Your changes will be automatically saved in the session.";
 *         [alert addButtonWithTitle:@"Save Session"];
 *         [alert addButtonWithTitle:@"Don't Save"];
 *         [alert addButtonWithTitle:@"Cancel"];
 *         
 *         NSModalResponse response = [alert runModal];
 *         
 *         switch (response) {
 *             case NSAlertFirstButtonReturn:
 *                 // Save Session - will happen automatically in applicationWillTerminate
 *                 return NSTerminateNow;
 *             case NSAlertSecondButtonReturn:
 *                 // Don't Save - disable auto-save temporarily
 *                 [SessionManager sharedManager].autoSaveOnQuit = NO;
 *                 return NSTerminateNow;
 *             case NSAlertThirdButtonReturn:
 *                 // Cancel
 *                 return NSTerminateCancel;
 *         }
 *     }
 *     
 *     return NSTerminateNow;
 * }
 */

#pragma mark - Example Menu Actions

/**
 * EXAMPLE MENU ACTIONS TO ADD TO YOUR AppDelegate:
 *
 * - (IBAction)saveSession:(id)sender {
 *     SessionManager *sessionManager = [SessionManager sharedManager];
 *     NSError *error = nil;
 *     
 *     BOOL success = [sessionManager saveSession:self.documentController error:&error];
 *     
 *     if (success) {
 *         // Show success notification
 *         [self showNotification:@"Session Saved" message:@"Your workspace has been saved."];
 *     } else {
 *         // Show error alert
 *         NSAlert *alert = [[NSAlert alloc] init];
 *         alert.messageText = @"Failed to Save Session";
 *         alert.informativeText = error.localizedDescription;
 *         alert.alertStyle = NSAlertStyleWarning;
 *         [alert runModal];
 *     }
 * }
 *
 * - (IBAction)restoreSession:(id)sender {
 *     SessionManager *sessionManager = [SessionManager sharedManager];
 *     
 *     if (![sessionManager hasExistingSession]) {
 *         NSAlert *alert = [[NSAlert alloc] init];
 *         alert.messageText = @"No Session Found";
 *         alert.informativeText = @"There is no saved session to restore.";
 *         alert.alertStyle = NSAlertStyleInformational;
 *         [alert runModal];
 *         return;
 *     }
 *     
 *     // Ask user for confirmation if there are unsaved changes
 *     if ([self.documentController hasUnsavedChanges]) {
 *         NSAlert *alert = [[NSAlert alloc] init];
 *         alert.messageText = @"Restore Previous Session?";
 *         alert.informativeText = @"This will close all current documents. Any unsaved changes will be lost.";
 *         [alert addButtonWithTitle:@"Restore"];
 *         [alert addButtonWithTitle:@"Cancel"];
 *         
 *         if ([alert runModal] != NSAlertFirstButtonReturn) {
 *             return;
 *         }
 *     }
 *     
 *     // Close all current documents
 *     [self.documentController closeAllDocuments];
 *     
 *     // Restore session
 *     NSError *error = nil;
 *     BOOL success = [sessionManager loadSession:self.documentController error:&error];
 *     
 *     if (success) {
 *         [self showNotification:@"Session Restored" message:@"Your previous workspace has been restored."];
 *     } else {
 *         NSAlert *alert = [[NSAlert alloc] init];
 *         alert.messageText = @"Failed to Restore Session";
 *         alert.informativeText = error.localizedDescription;
 *         alert.alertStyle = NSAlertStyleWarning;
 *         [alert runModal];
 *     }
 * }
 *
 * - (IBAction)clearSession:(id)sender {
 *     NSAlert *alert = [[NSAlert alloc] init];
 *     alert.messageText = @"Clear Saved Session?";
 *     alert.informativeText = @"This will delete your saved workspace. This action cannot be undone.";
 *     [alert addButtonWithTitle:@"Clear"];
 *     [alert addButtonWithTitle:@"Cancel"];
 *     alert.alertStyle = NSAlertStyleWarning;
 *     
 *     if ([alert runModal] != NSAlertFirstButtonReturn) {
 *         return;
 *     }
 *     
 *     SessionManager *sessionManager = [SessionManager sharedManager];
 *     NSError *error = nil;
 *     
 *     BOOL success = [sessionManager clearSession:&error];
 *     
 *     if (success) {
 *         [self showNotification:@"Session Cleared" message:@"Your saved workspace has been deleted."];
 *     } else {
 *         NSAlert *errorAlert = [[NSAlert alloc] init];
 *         errorAlert.messageText = @"Failed to Clear Session";
 *         errorAlert.informativeText = error.localizedDescription;
 *         errorAlert.alertStyle = NSAlertStyleWarning;
 *         [errorAlert runModal];
 *     }
 * }
 *
 * - (void)showNotification:(NSString *)title message:(NSString *)message {
 *     NSUserNotification *notification = [[NSUserNotification alloc] init];
 *     notification.title = title;
 *     notification.informativeText = message;
 *     [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
 * }
 */
