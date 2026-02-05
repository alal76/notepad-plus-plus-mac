//
//  FileManager.h
//  Notepad++ macOS Platform Layer
//
//  Copyright © 2024 Notepad++. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Platform abstraction for file operations on macOS.
 * This class wraps NSFileManager and provides utilities for
 * file I/O, encoding detection, and path management.
 */
@interface FileManager : NSObject

+ (instancetype)sharedManager;

// Path utilities
- (NSString *)applicationSupportDirectory;
- (NSString *)preferencesDirectory;
- (NSString *)pluginsDirectory;
- (NSString *)configDirectory;

// File operations
- (BOOL)fileExistsAtPath:(NSString *)path;
- (BOOL)directoryExistsAtPath:(NSString *)path;
- (BOOL)createDirectoryAtPath:(NSString *)path error:(NSError **)error;
- (NSArray<NSString *> *)contentsOfDirectoryAtPath:(NSString *)path error:(NSError **)error;

// Encoding detection
- (NSStringEncoding)detectEncodingForFileAtPath:(NSString *)path;
- (BOOL)hasBOMAtPath:(NSString *)path;

// Recent files
- (void)addRecentFileURL:(NSURL *)url;
- (NSArray<NSURL *> *)recentFileURLs;
- (void)clearRecentFiles;

@end
