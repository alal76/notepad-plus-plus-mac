//
//  SessionManager.mm
//  Notepad++ macOS Platform Layer
//
//  Copyright © 2024 Notepad++. All rights reserved.
//

#import "SessionManager.h"
#import "FileManager.h"
#import "../AppKit/DocumentController.h"
#import "../AppKit/Document.h"

// Session file name
static NSString * const kSessionFileName = @"session.json";

// Session dictionary keys
static NSString * const kSessionOpenFilesKey = @"openFiles";
static NSString * const kSessionActiveFileKey = @"activeFile";
static NSString * const kSessionWindowStateKey = @"windowState";
static NSString * const kSessionCursorPositionsKey = @"cursorPositions";

// File entry keys
static NSString * const kFilePathKey = @"path";
static NSString * const kFileEncodingKey = @"encoding";
static NSString * const kFileLineEndingKey = @"lineEnding";
static NSString * const kFileLanguageKey = @"language";
static NSString * const kFileCursorPositionKey = @"cursorPosition";
static NSString * const kFileScrollPositionKey = @"scrollPosition";

// Window state keys
static NSString * const kWindowFrameKey = @"frame";
static NSString * const kWindowIsMaximizedKey = @"isMaximized";
static NSString * const kWindowIsFullScreenKey = @"isFullScreen";

// UserDefaults keys for preferences
static NSString * const kAutoSaveOnQuitKey = @"SessionAutoSaveOnQuit";
static NSString * const kAutoRestoreOnLaunchKey = @"SessionAutoRestoreOnLaunch";

#pragma mark - SessionData Implementation

@implementation SessionData

- (instancetype)init {
    self = [super init];
    if (self) {
        _openFiles = [NSMutableArray array];
        _cursorPositions = [NSDictionary dictionary];
        _windowState = [NSDictionary dictionary];
    }
    return self;
}

- (NSDictionary *)toDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    if (self.openFiles.count > 0) {
        dict[kSessionOpenFilesKey] = self.openFiles;
    }
    
    if (self.activeFilePath) {
        dict[kSessionActiveFileKey] = self.activeFilePath;
    }
    
    if (self.windowState.count > 0) {
        dict[kSessionWindowStateKey] = self.windowState;
    }
    
    if (self.cursorPositions.count > 0) {
        dict[kSessionCursorPositionsKey] = self.cursorPositions;
    }
    
    return [dict copy];
}

- (void)loadFromDictionary:(NSDictionary *)dictionary {
    if (!dictionary) {
        return;
    }
    
    NSArray *openFiles = dictionary[kSessionOpenFilesKey];
    if (openFiles && [openFiles isKindOfClass:[NSArray class]]) {
        self.openFiles = [openFiles mutableCopy];
    }
    
    NSString *activeFile = dictionary[kSessionActiveFileKey];
    if (activeFile && [activeFile isKindOfClass:[NSString class]]) {
        self.activeFilePath = activeFile;
    }
    
    NSDictionary *windowState = dictionary[kSessionWindowStateKey];
    if (windowState && [windowState isKindOfClass:[NSDictionary class]]) {
        self.windowState = windowState;
    }
    
    NSDictionary *cursorPositions = dictionary[kSessionCursorPositionsKey];
    if (cursorPositions && [cursorPositions isKindOfClass:[NSDictionary class]]) {
        self.cursorPositions = cursorPositions;
    }
}

@end

#pragma mark - SessionManager Implementation

@interface SessionManager ()

@property (strong, nonatomic) SessionData *currentSessionData;
@property (strong, nonatomic) NSString *sessionDirectory;

@end

@implementation SessionManager

+ (instancetype)sharedManager {
    static SessionManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[SessionManager alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _currentSessionData = [[SessionData alloc] init];
        [self setupSessionDirectory];
        [self loadPreferences];
    }
    return self;
}

- (void)setupSessionDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,
                                                         NSUserDomainMask,
                                                         YES);
    NSString *applicationSupportDirectory = [paths firstObject];
    self.sessionDirectory = [applicationSupportDirectory stringByAppendingPathComponent:@"Notepad++"];
    
    // Create directory if it doesn't exist
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    if (![fileManager fileExistsAtPath:self.sessionDirectory]) {
        [fileManager createDirectoryAtPath:self.sessionDirectory
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:&error];
        if (error) {
            NSLog(@"Failed to create session directory: %@", error.localizedDescription);
        }
    }
}

- (void)loadPreferences {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // Default to YES for auto-save on quit
    if ([defaults objectForKey:kAutoSaveOnQuitKey] == nil) {
        _autoSaveOnQuit = YES;
    } else {
        _autoSaveOnQuit = [defaults boolForKey:kAutoSaveOnQuitKey];
    }
    
    // Default to NO for auto-restore on launch (user opt-in)
    _autoRestoreOnLaunch = [defaults boolForKey:kAutoRestoreOnLaunchKey];
}

- (void)setAutoSaveOnQuit:(BOOL)autoSaveOnQuit {
    _autoSaveOnQuit = autoSaveOnQuit;
    [[NSUserDefaults standardUserDefaults] setBool:autoSaveOnQuit forKey:kAutoSaveOnQuitKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setAutoRestoreOnLaunch:(BOOL)autoRestoreOnLaunch {
    _autoRestoreOnLaunch = autoRestoreOnLaunch;
    [[NSUserDefaults standardUserDefaults] setBool:autoRestoreOnLaunch forKey:kAutoRestoreOnLaunchKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *)sessionFilePath {
    return [self.sessionDirectory stringByAppendingPathComponent:kSessionFileName];
}

- (BOOL)hasExistingSession {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    return [fileManager fileExistsAtPath:[self sessionFilePath]];
}

#pragma mark - Session Saving

- (BOOL)saveSession:(DocumentController *)documentController error:(NSError **)error {
    if (!documentController) {
        if (error) {
            *error = [NSError errorWithDomain:@"SessionManagerErrorDomain"
                                        code:100
                                    userInfo:@{NSLocalizedDescriptionKey: @"DocumentController is nil"}];
        }
        return NO;
    }
    
    SessionData *sessionData = [[SessionData alloc] init];
    
    // Collect open files
    NSMutableArray *openFiles = [NSMutableArray array];
    for (Document *doc in documentController.documents) {
        if (doc.fileURL) {
            NSMutableDictionary *fileInfo = [NSMutableDictionary dictionary];
            fileInfo[kFilePathKey] = [doc.fileURL path];
            fileInfo[kFileEncodingKey] = @(doc.encoding);
            fileInfo[kFileLineEndingKey] = @(doc.lineEnding);
            
            if (doc.languageType) {
                fileInfo[kFileLanguageKey] = doc.languageType;
            }
            
            // Note: Cursor and scroll positions would need to be provided by the editor view
            // For now, we'll use placeholder values that can be extended later
            fileInfo[kFileCursorPositionKey] = @(0);
            fileInfo[kFileScrollPositionKey] = @(0);
            
            [openFiles addObject:fileInfo];
        }
    }
    sessionData.openFiles = openFiles;
    
    // Save active file
    if (documentController.currentDocument && documentController.currentDocument.fileURL) {
        sessionData.activeFilePath = [documentController.currentDocument.fileURL path];
    }
    
    // Convert to dictionary
    NSDictionary *sessionDict = [sessionData toDictionary];
    
    // Serialize to JSON
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:sessionDict
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:error];
    if (!jsonData) {
        return NO;
    }
    
    // Write to file
    NSString *filePath = [self sessionFilePath];
    BOOL success = [jsonData writeToFile:filePath
                              options:NSDataWritingAtomic
                                error:error];
    
    if (success) {
        NSLog(@"Session saved successfully to: %@", filePath);
        self.currentSessionData = sessionData;
    } else {
        NSLog(@"Failed to save session: %@", error ? [*error localizedDescription] : @"Unknown error");
    }
    
    return success;
}

#pragma mark - Session Loading

- (BOOL)loadSession:(DocumentController *)documentController error:(NSError **)error {
    if (!documentController) {
        if (error) {
            *error = [NSError errorWithDomain:@"SessionManagerErrorDomain"
                                        code:101
                                    userInfo:@{NSLocalizedDescriptionKey: @"DocumentController is nil"}];
        }
        return NO;
    }
    
    // Check if session file exists
    NSString *filePath = [self sessionFilePath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:filePath]) {
        if (error) {
            *error = [NSError errorWithDomain:@"SessionManagerErrorDomain"
                                        code:102
                                    userInfo:@{NSLocalizedDescriptionKey: @"No session file found"}];
        }
        return NO;
    }
    
    // Read file
    NSData *jsonData = [NSData dataWithContentsOfFile:filePath
                                              options:0
                                                error:error];
    if (!jsonData) {
        return NO;
    }
    
    // Parse JSON
    NSDictionary *sessionDict = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                options:0
                                                                  error:error];
    if (!sessionDict) {
        return NO;
    }
    
    // Load session data
    SessionData *sessionData = [[SessionData alloc] init];
    [sessionData loadFromDictionary:sessionDict];
    
    // Restore open files
    NSString *activeFilePath = sessionData.activeFilePath;
    Document *activeDocument = nil;
    
    for (NSDictionary *fileInfo in sessionData.openFiles) {
        NSString *filePath = fileInfo[kFilePathKey];
        if (!filePath || ![fileManager fileExistsAtPath:filePath]) {
            NSLog(@"Skipping file that no longer exists: %@", filePath);
            continue;
        }
        
        NSURL *fileURL = [NSURL fileURLWithPath:filePath];
        Document *doc = [documentController openDocument:fileURL];
        
        if (doc) {
            // Restore encoding and line ending
            NSNumber *encoding = fileInfo[kFileEncodingKey];
            if (encoding) {
                doc.encoding = (DocumentEncoding)[encoding integerValue];
            }
            
            NSNumber *lineEnding = fileInfo[kFileLineEndingKey];
            if (lineEnding) {
                doc.lineEnding = (DocumentLineEnding)[lineEnding integerValue];
            }
            
            NSString *language = fileInfo[kFileLanguageKey];
            if (language) {
                doc.languageType = language;
            }
            
            // Check if this is the active document
            if ([filePath isEqualToString:activeFilePath]) {
                activeDocument = doc;
            }
            
            // Note: Cursor and scroll position restoration would need to be handled
            // by the editor view controller when it's ready
        }
    }
    
    // Switch to active document
    if (activeDocument) {
        [documentController switchToDocument:activeDocument];
    }
    
    self.currentSessionData = sessionData;
    NSLog(@"Session loaded successfully from: %@", filePath);
    
    return YES;
}

#pragma mark - Session Clearing

- (BOOL)clearSession:(NSError **)error {
    NSString *filePath = [self sessionFilePath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if ([fileManager fileExistsAtPath:filePath]) {
        BOOL success = [fileManager removeItemAtPath:filePath error:error];
        if (success) {
            NSLog(@"Session cleared successfully");
            self.currentSessionData = [[SessionData alloc] init];
        } else {
            NSLog(@"Failed to clear session: %@", error ? [*error localizedDescription] : @"Unknown error");
        }
        return success;
    }
    
    // No session file exists, consider it a success
    return YES;
}

#pragma mark - Window State Management

- (void)saveWindowState:(NSDictionary *)windowState {
    if (windowState) {
        self.currentSessionData.windowState = windowState;
    }
}

- (NSDictionary *)loadWindowState {
    return self.currentSessionData.windowState;
}

#pragma mark - AppDelegate Integration Helpers

/**
 * Call this method from AppDelegate's applicationWillTerminate:
 * to automatically save the session on quit if enabled.
 */
+ (void)saveSessionOnQuit:(DocumentController *)documentController {
    SessionManager *manager = [SessionManager sharedManager];
    if (manager.autoSaveOnQuit && documentController) {
        NSError *error = nil;
        [manager saveSession:documentController error:&error];
        if (error) {
            NSLog(@"Failed to auto-save session on quit: %@", error.localizedDescription);
        }
    }
}

/**
 * Call this method from AppDelegate's applicationDidFinishLaunching:
 * to automatically restore the session on launch if enabled.
 */
+ (void)restoreSessionOnLaunch:(DocumentController *)documentController {
    SessionManager *manager = [SessionManager sharedManager];
    if (manager.autoRestoreOnLaunch && [manager hasExistingSession] && documentController) {
        NSError *error = nil;
        [manager loadSession:documentController error:&error];
        if (error) {
            NSLog(@"Failed to auto-restore session on launch: %@", error.localizedDescription);
        }
    }
}

@end
