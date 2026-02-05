//
//  FileManager.mm
//  Notepad++ macOS Platform Layer
//
//  Copyright © 2024 Notepad++. All rights reserved.
//

#import "FileManager.h"

static NSString * const kRecentFilesKey = @"RecentFiles";
static NSString * const kApplicationName = @"Notepad++";

@implementation FileManager

+ (instancetype)sharedManager {
    static FileManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[FileManager alloc] init];
    });
    return sharedInstance;
}

#pragma mark - Path Utilities

- (NSString *)applicationSupportDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, 
                                                         NSUserDomainMask, 
                                                         YES);
    NSString *appSupportDir = paths.firstObject;
    NSString *notepadDir = [appSupportDir stringByAppendingPathComponent:kApplicationName];
    
    // Create directory if it doesn't exist
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:notepadDir]) {
        [fm createDirectoryAtPath:notepadDir 
      withIntermediateDirectories:YES 
                       attributes:nil 
                            error:nil];
    }
    
    return notepadDir;
}

- (NSString *)preferencesDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, 
                                                         NSUserDomainMask, 
                                                         YES);
    NSString *libraryDir = paths.firstObject;
    return [libraryDir stringByAppendingPathComponent:@"Preferences"];
}

- (NSString *)pluginsDirectory {
    NSString *appSupportDir = [self applicationSupportDirectory];
    NSString *pluginsDir = [appSupportDir stringByAppendingPathComponent:@"plugins"];
    
    // Create directory if it doesn't exist
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:pluginsDir]) {
        [fm createDirectoryAtPath:pluginsDir 
      withIntermediateDirectories:YES 
                       attributes:nil 
                            error:nil];
    }
    
    return pluginsDir;
}

- (NSString *)configDirectory {
    NSString *appSupportDir = [self applicationSupportDirectory];
    NSString *configDir = [appSupportDir stringByAppendingPathComponent:@"config"];
    
    // Create directory if it doesn't exist
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:configDir]) {
        [fm createDirectoryAtPath:configDir 
      withIntermediateDirectories:YES 
                       attributes:nil 
                            error:nil];
    }
    
    return configDir;
}

#pragma mark - File Operations

- (BOOL)fileExistsAtPath:(NSString *)path {
    return [[NSFileManager defaultManager] fileExistsAtPath:path];
}

- (BOOL)directoryExistsAtPath:(NSString *)path {
    BOOL isDirectory = NO;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];
    return exists && isDirectory;
}

- (BOOL)createDirectoryAtPath:(NSString *)path error:(NSError **)error {
    return [[NSFileManager defaultManager] createDirectoryAtPath:path
                                     withIntermediateDirectories:YES
                                                      attributes:nil
                                                           error:error];
}

- (NSArray<NSString *> *)contentsOfDirectoryAtPath:(NSString *)path error:(NSError **)error {
    return [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:error];
}

#pragma mark - Encoding Detection

- (NSStringEncoding)detectEncodingForFileAtPath:(NSString *)path {
    NSData *data = [NSData dataWithContentsOfFile:path];
    if (!data || data.length == 0) {
        return NSUTF8StringEncoding;
    }
    
    const unsigned char *bytes = (const unsigned char *)data.bytes;
    NSUInteger length = data.length;
    
    // Check for BOM
    if (length >= 3 && bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF) {
        return NSUTF8StringEncoding; // UTF-8 with BOM
    }
    
    if (length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xFE) {
        return NSUTF16LittleEndianStringEncoding; // UTF-16 LE
    }
    
    if (length >= 2 && bytes[0] == 0xFE && bytes[1] == 0xFF) {
        return NSUTF16BigEndianStringEncoding; // UTF-16 BE
    }
    
    // Try to detect encoding by attempting to decode
    NSString *string = nil;
    
    // Try UTF-8
    string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (string) {
        return NSUTF8StringEncoding;
    }
    
    // Try ISO Latin 1
    string = [[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding];
    if (string) {
        return NSISOLatin1StringEncoding;
    }
    
    // Default to UTF-8
    return NSUTF8StringEncoding;
}

- (BOOL)hasBOMAtPath:(NSString *)path {
    NSData *data = [NSData dataWithContentsOfFile:path options:0 error:nil];
    if (!data || data.length < 2) {
        return NO;
    }
    
    const unsigned char *bytes = (const unsigned char *)data.bytes;
    
    // Check for UTF-8 BOM
    if (data.length >= 3 && bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF) {
        return YES;
    }
    
    // Check for UTF-16 BOM
    if ((bytes[0] == 0xFF && bytes[1] == 0xFE) || (bytes[0] == 0xFE && bytes[1] == 0xFF)) {
        return YES;
    }
    
    return NO;
}

#pragma mark - Recent Files

- (void)addRecentFileURL:(NSURL *)url {
    NSMutableArray *recentFiles = [[self recentFileURLs] mutableCopy];
    if (!recentFiles) {
        recentFiles = [NSMutableArray array];
    }
    
    // Remove if already exists
    [recentFiles removeObject:url.path];
    
    // Add to beginning
    [recentFiles insertObject:url.path atIndex:0];
    
    // Limit to 10 files
    if (recentFiles.count > 10) {
        [recentFiles removeObjectsInRange:NSMakeRange(10, recentFiles.count - 10)];
    }
    
    // Save to user defaults
    [[NSUserDefaults standardUserDefaults] setObject:recentFiles forKey:kRecentFilesKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSArray<NSURL *> *)recentFileURLs {
    NSArray *paths = [[NSUserDefaults standardUserDefaults] arrayForKey:kRecentFilesKey];
    if (!paths) {
        return @[];
    }
    
    NSMutableArray *urls = [NSMutableArray array];
    for (NSString *path in paths) {
        // Only include files that still exist
        if ([self fileExistsAtPath:path]) {
            [urls addObject:[NSURL fileURLWithPath:path]];
        }
    }
    
    return urls;
}

- (void)clearRecentFiles {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kRecentFilesKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
