//
//  AppDelegate+SessionManager.h
//  Notepad++ macOS - SessionManager Integration Example
//
//  Copyright © 2024 Notepad++. All rights reserved.
//
//  This is an example/reference file showing how to integrate SessionManager
//  with AppDelegate. Copy relevant methods to your actual AppDelegate implementation.
//

#import <Cocoa/Cocoa.h>

@class DocumentController;
@class MainWindowController;

/**
 * This category demonstrates SessionManager integration with AppDelegate.
 * These methods can be adapted and integrated into your actual AppDelegate class.
 */
@interface AppDelegate (SessionManagerIntegration)

/**
 * Call this in applicationDidFinishLaunching: to set up session management.
 * @param documentController Your document controller instance
 */
- (void)setupSessionManagement:(DocumentController *)documentController;

/**
 * Call this in applicationWillTerminate: to save the session on quit.
 * @param documentController Your document controller instance
 */
- (void)saveSessionOnTerminate:(DocumentController *)documentController;

/**
 * Restores the previous session if auto-restore is enabled.
 * @param documentController Your document controller instance
 * @return YES if session was restored, NO otherwise
 */
- (BOOL)restorePreviousSession:(DocumentController *)documentController;

/**
 * Saves the current window state to the session.
 * @param window The main window
 */
- (void)saveWindowStateForSession:(NSWindow *)window;

/**
 * Restores window state from the session.
 * @param window The main window to restore state to
 */
- (void)restoreWindowStateFromSession:(NSWindow *)window;

@end
