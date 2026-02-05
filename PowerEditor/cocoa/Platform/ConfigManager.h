//
//  ConfigManager.h
//  Notepad++ macOS Platform Layer
//
//  Copyright © 2024 Notepad++. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Platform abstraction for configuration management on macOS.
 * This class provides access to user preferences (NSUserDefaults)
 * and XML configuration files.
 */
@interface ConfigManager : NSObject

+ (instancetype)sharedManager;

// User defaults (preferences)
- (id)preferenceForKey:(NSString *)key;
- (void)setPreference:(id)value forKey:(NSString *)key;
- (void)removePreferenceForKey:(NSString *)key;
- (void)synchronize;

// XML configuration files
- (NSString *)pathForConfigFile:(NSString *)filename;
- (NSDictionary *)loadConfigFile:(NSString *)filename error:(NSError **)error;
- (BOOL)saveConfigFile:(NSString *)filename data:(NSDictionary *)data error:(NSError **)error;

// Common preferences
- (NSString *)fontName;
- (void)setFontName:(NSString *)fontName;
- (CGFloat)fontSize;
- (void)setFontSize:(CGFloat)fontSize;
- (NSInteger)tabSize;
- (void)setTabSize:(NSInteger)tabSize;
- (BOOL)useSpacesInsteadOfTabs;
- (void)setUseSpacesInsteadOfTabs:(BOOL)useSpaces;
- (BOOL)showLineNumbers;
- (void)setShowLineNumbers:(BOOL)show;
- (BOOL)wordWrap;
- (void)setWordWrap:(BOOL)wrap;

@end
