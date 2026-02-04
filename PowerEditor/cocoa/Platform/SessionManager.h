//
//  SessionManager.h
//  Notepad++ macOS Platform Layer
//
//  Copyright © 2024 Notepad++. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Document;
@class DocumentController;

/**
 * Session data structure for persisting application state.
 */
@interface SessionData : NSObject

@property (strong, nonatomic) NSMutableArray<NSDictionary *> *openFiles;
@property (strong, nonatomic) NSString *activeFilePath;
@property (strong, nonatomic) NSDictionary *windowState;
@property (strong, nonatomic) NSDictionary *cursorPositions;

- (instancetype)init;
- (NSDictionary *)toDictionary;
- (void)loadFromDictionary:(NSDictionary *)dictionary;

@end

/**
 * Platform abstraction for session management on macOS.
 * Handles saving and restoring application state including open files,
 * active document, cursor positions, and window state.
 * 
 * Session data is stored in: ~/Library/Application Support/Notepad++/session.json
 */
@interface SessionManager : NSObject

/**
 * Returns the shared singleton instance.
 */
+ (instancetype)sharedManager;

/**
 * Saves the current session to disk.
 * @param documentController The document controller containing active documents
 * @param error Optional error pointer
 * @return YES if successful, NO otherwise
 */
- (BOOL)saveSession:(DocumentController *)documentController error:(NSError **)error;

/**
 * Loads and restores a previously saved session.
 * @param documentController The document controller to restore documents into
 * @param error Optional error pointer
 * @return YES if successful, NO otherwise
 */
- (BOOL)loadSession:(DocumentController *)documentController error:(NSError **)error;

/**
 * Clears the saved session from disk.
 * @param error Optional error pointer
 * @return YES if successful, NO otherwise
 */
- (BOOL)clearSession:(NSError **)error;

/**
 * Checks if a saved session exists.
 * @return YES if a session file exists, NO otherwise
 */
- (BOOL)hasExistingSession;

/**
 * Returns the path to the session file.
 * @return Full path to session.json
 */
- (NSString *)sessionFilePath;

/**
 * Saves the current window state (size, position, etc).
 * @param windowState Dictionary containing window properties
 */
- (void)saveWindowState:(NSDictionary *)windowState;

/**
 * Retrieves the saved window state.
 * @return Dictionary containing window properties, or nil if none saved
 */
- (NSDictionary *)loadWindowState;

/**
 * Enables or disables automatic session saving on application quit.
 * Default is YES.
 */
@property (assign, nonatomic) BOOL autoSaveOnQuit;

/**
 * Enables or disables automatic session restoration on application launch.
 * Default is NO (user must opt-in).
 */
@property (assign, nonatomic) BOOL autoRestoreOnLaunch;

@end
