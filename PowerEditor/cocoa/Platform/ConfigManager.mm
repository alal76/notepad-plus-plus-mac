//
//  ConfigManager.mm
//  Notepad++ macOS Platform Layer
//
//  Copyright © 2024 Notepad++. All rights reserved.
//

#import "ConfigManager.h"
#import "FileManager.h"

// Preference keys
static NSString * const kFontNameKey = @"FontName";
static NSString * const kFontSizeKey = @"FontSize";
static NSString * const kTabSizeKey = @"TabSize";
static NSString * const kUseSpacesKey = @"UseSpaces";
static NSString * const kShowLineNumbersKey = @"ShowLineNumbers";
static NSString * const kWordWrapKey = @"WordWrap";

// Default values
static NSString * const kDefaultFontName = @"Menlo";
static const CGFloat kDefaultFontSize = 13.0;
static const NSInteger kDefaultTabSize = 4;

@interface ConfigManager ()

@property (strong, nonatomic) NSUserDefaults *userDefaults;

@end

@implementation ConfigManager

+ (instancetype)sharedManager {
    static ConfigManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[ConfigManager alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _userDefaults = [NSUserDefaults standardUserDefaults];
        [self registerDefaults];
    }
    return self;
}

- (void)registerDefaults {
    NSDictionary *defaults = @{
        kFontNameKey: kDefaultFontName,
        kFontSizeKey: @(kDefaultFontSize),
        kTabSizeKey: @(kDefaultTabSize),
        kUseSpacesKey: @YES,
        kShowLineNumbersKey: @YES,
        kWordWrapKey: @NO,
    };
    
    [self.userDefaults registerDefaults:defaults];
}

#pragma mark - User Defaults

- (id)preferenceForKey:(NSString *)key {
    return [self.userDefaults objectForKey:key];
}

- (void)setPreference:(id)value forKey:(NSString *)key {
    [self.userDefaults setObject:value forKey:key];
}

- (void)removePreferenceForKey:(NSString *)key {
    [self.userDefaults removeObjectForKey:key];
}

- (void)synchronize {
    [self.userDefaults synchronize];
}

#pragma mark - XML Configuration Files

- (NSString *)pathForConfigFile:(NSString *)filename {
    NSString *configDir = [[FileManager sharedManager] configDirectory];
    return [configDir stringByAppendingPathComponent:filename];
}

- (NSDictionary *)loadConfigFile:(NSString *)filename error:(NSError **)error {
    NSString *path = [self pathForConfigFile:filename];
    
    // Check if file exists
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        if (error) {
            *error = [NSError errorWithDomain:NSCocoaErrorDomain
                                        code:NSFileReadNoSuchFileError
                                    userInfo:@{NSLocalizedDescriptionKey: @"Configuration file not found"}];
        }
        return nil;
    }
    
    // Load XML data
    NSData *data = [NSData dataWithContentsOfFile:path options:0 error:error];
    if (!data) {
        return nil;
    }
    
    // Parse XML (simplified - in real implementation would use proper XML parser)
    // For now, just return empty dictionary
    // TODO: Implement proper XML parsing using NSXMLDocument or libxml2
    
    return @{};
}

- (BOOL)saveConfigFile:(NSString *)filename data:(NSDictionary *)data error:(NSError **)error {
    NSString *path = [self pathForConfigFile:filename];
    
    // Convert dictionary to XML (simplified)
    // TODO: Implement proper XML generation
    
    NSString *xmlString = @"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<config></config>";
    NSData *xmlData = [xmlString dataUsingEncoding:NSUTF8StringEncoding];
    
    return [xmlData writeToFile:path options:NSDataWritingAtomic error:error];
}

#pragma mark - Common Preferences

- (NSString *)fontName {
    return [self.userDefaults stringForKey:kFontNameKey];
}

- (void)setFontName:(NSString *)fontName {
    [self.userDefaults setObject:fontName forKey:kFontNameKey];
    [self synchronize];
}

- (CGFloat)fontSize {
    return [self.userDefaults doubleForKey:kFontSizeKey];
}

- (void)setFontSize:(CGFloat)fontSize {
    [self.userDefaults setDouble:fontSize forKey:kFontSizeKey];
    [self synchronize];
}

- (NSInteger)tabSize {
    return [self.userDefaults integerForKey:kTabSizeKey];
}

- (void)setTabSize:(NSInteger)tabSize {
    [self.userDefaults setInteger:tabSize forKey:kTabSizeKey];
    [self synchronize];
}

- (BOOL)useSpacesInsteadOfTabs {
    return [self.userDefaults boolForKey:kUseSpacesKey];
}

- (void)setUseSpacesInsteadOfTabs:(BOOL)useSpaces {
    [self.userDefaults setBool:useSpaces forKey:kUseSpacesKey];
    [self synchronize];
}

- (BOOL)showLineNumbers {
    return [self.userDefaults boolForKey:kShowLineNumbersKey];
}

- (void)setShowLineNumbers:(BOOL)show {
    [self.userDefaults setBool:show forKey:kShowLineNumbersKey];
    [self synchronize];
}

- (BOOL)wordWrap {
    return [self.userDefaults boolForKey:kWordWrapKey];
}

- (void)setWordWrap:(BOOL)wrap {
    [self.userDefaults setBool:wrap forKey:kWordWrapKey];
    [self synchronize];
}

@end
