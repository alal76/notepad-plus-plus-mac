//
//  Document.mm
//  Notepad++ macOS
//
//  Copyright © 2024 Notepad++. All rights reserved.
//

#import "Document.h"

static NSInteger gUntitledCount = 0;

@interface Document ()

@property (strong, nonatomic) NSString *untitledName;

@end

@implementation Document

- (instancetype)init {
    self = [super init];
    if (self) {
        _content = @"";
        _isModified = NO;
        _encoding = DocumentEncodingUTF8;
        _lineEnding = DocumentLineEndingUnix;
        _languageType = @"Plain Text";
        
        // Generate untitled name
        gUntitledCount++;
        _untitledName = [NSString stringWithFormat:@"Untitled %ld", (long)gUntitledCount];
    }
    return self;
}

#pragma mark - Display Properties

- (NSString *)displayName {
    if (self.fileURL) {
        return self.fileURL.lastPathComponent;
    }
    return self.untitledName;
}

- (NSString *)encodingName {
    switch (self.encoding) {
        case DocumentEncodingUTF8:
            return @"UTF-8";
        case DocumentEncodingUTF16:
            return @"UTF-16";
        case DocumentEncodingUTF16BE:
            return @"UTF-16BE";
        case DocumentEncodingASCII:
            return @"ASCII";
        case DocumentEncodingISO88591:
            return @"ISO-8859-1";
        default:
            return @"Unknown";
    }
}

- (NSString *)lineEndingName {
    switch (self.lineEnding) {
        case DocumentLineEndingUnix:
            return @"LF";
        case DocumentLineEndingWindows:
            return @"CRLF";
        case DocumentLineEndingMac:
            return @"CR";
        default:
            return @"Unknown";
    }
}

#pragma mark - File Operations

- (BOOL)loadFromURL:(NSURL *)url error:(NSError **)error {
    // Read file data
    NSData *data = [NSData dataWithContentsOfURL:url options:0 error:error];
    if (!data) {
        return NO;
    }
    
    // Detect encoding
    [self detectEncodingFromData:data];
    
    // Convert to string
    NSStringEncoding encoding = [self nsStringEncodingForDocumentEncoding:self.encoding];
    NSString *string = [[NSString alloc] initWithData:data encoding:encoding];
    
    if (!string) {
        // Try UTF-8 as fallback
        string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        self.encoding = DocumentEncodingUTF8;
    }
    
    if (!string) {
        if (error) {
            *error = [NSError errorWithDomain:NSCocoaErrorDomain
                                        code:NSFileReadUnknownError
                                    userInfo:@{NSLocalizedDescriptionKey: @"Unable to decode file content"}];
        }
        return NO;
    }
    
    // Detect line ending
    [self detectLineEndingFromString:string];
    
    // Detect language from file extension
    [self detectLanguageFromURL:url];
    
    // Set content
    self.fileURL = url;
    [self setContentWithoutModifying:string];
    
    return YES;
}

- (BOOL)saveToURL:(NSURL *)url error:(NSError **)error {
    // Convert content to appropriate line endings
    NSString *contentToSave = [self convertLineEndings:self.content to:self.lineEnding];
    
    // Convert to data with appropriate encoding
    NSStringEncoding encoding = [self nsStringEncodingForDocumentEncoding:self.encoding];
    NSData *data = [contentToSave dataUsingEncoding:encoding];
    
    if (!data) {
        if (error) {
            *error = [NSError errorWithDomain:NSCocoaErrorDomain
                                        code:NSFileWriteInapplicableStringEncodingError
                                    userInfo:@{NSLocalizedDescriptionKey: @"Unable to encode content"}];
        }
        return NO;
    }
    
    // Write to file
    BOOL success = [data writeToURL:url options:NSDataWritingAtomic error:error];
    
    if (success) {
        self.fileURL = url;
        self.isModified = NO;
    }
    
    return success;
}

#pragma mark - Content Operations

- (void)setContent:(NSString *)content {
    if (![_content isEqualToString:content]) {
        _content = content;
        self.isModified = YES;
    }
}

- (void)setContentWithoutModifying:(NSString *)content {
    _content = content;
    self.isModified = NO;
}

#pragma mark - Encoding Detection

- (void)detectEncodingFromData:(NSData *)data {
    // Simple BOM detection
    const unsigned char *bytes = (const unsigned char *)data.bytes;
    NSUInteger length = data.length;
    
    if (length >= 3 && bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF) {
        // UTF-8 BOM
        self.encoding = DocumentEncodingUTF8;
        return;
    }
    
    if (length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xFE) {
        // UTF-16 LE BOM
        self.encoding = DocumentEncodingUTF16;
        return;
    }
    
    if (length >= 2 && bytes[0] == 0xFE && bytes[1] == 0xFF) {
        // UTF-16 BE BOM
        self.encoding = DocumentEncodingUTF16BE;
        return;
    }
    
    // Default to UTF-8
    self.encoding = DocumentEncodingUTF8;
}

- (void)detectLineEndingFromString:(NSString *)string {
    // Check for CRLF first (Windows)
    if ([string rangeOfString:@"\r\n"].location != NSNotFound) {
        self.lineEnding = DocumentLineEndingWindows;
        return;
    }
    
    // Check for CR (old Mac)
    if ([string rangeOfString:@"\r"].location != NSNotFound) {
        self.lineEnding = DocumentLineEndingMac;
        return;
    }
    
    // Default to LF (Unix/Mac)
    self.lineEnding = DocumentLineEndingUnix;
}

- (void)detectLanguageFromURL:(NSURL *)url {
    NSString *extension = url.pathExtension.lowercaseString;
    
    // Simple language detection based on extension
    NSDictionary *extensionToLanguage = @{
        @"c": @"C",
        @"cpp": @"C++",
        @"cxx": @"C++",
        @"cc": @"C++",
        @"h": @"C/C++ Header",
        @"hpp": @"C++ Header",
        @"m": @"Objective-C",
        @"mm": @"Objective-C++",
        @"py": @"Python",
        @"js": @"JavaScript",
        @"jsx": @"JavaScript",
        @"ts": @"TypeScript",
        @"tsx": @"TypeScript",
        @"java": @"Java",
        @"html": @"HTML",
        @"htm": @"HTML",
        @"css": @"CSS",
        @"xml": @"XML",
        @"json": @"JSON",
        @"sh": @"Shell",
        @"bash": @"Bash",
        @"md": @"Markdown",
        @"txt": @"Plain Text",
    };
    
    NSString *language = extensionToLanguage[extension];
    self.languageType = language ?: @"Plain Text";
}

#pragma mark - Encoding Utilities

- (NSStringEncoding)nsStringEncodingForDocumentEncoding:(DocumentEncoding)encoding {
    switch (encoding) {
        case DocumentEncodingUTF8:
            return NSUTF8StringEncoding;
        case DocumentEncodingUTF16:
            return NSUTF16LittleEndianStringEncoding;
        case DocumentEncodingUTF16BE:
            return NSUTF16BigEndianStringEncoding;
        case DocumentEncodingASCII:
            return NSASCIIStringEncoding;
        case DocumentEncodingISO88591:
            return NSISOLatin1StringEncoding;
        default:
            return NSUTF8StringEncoding;
    }
}

- (NSString *)convertLineEndings:(NSString *)string to:(DocumentLineEnding)lineEnding {
    // First normalize to LF
    NSString *normalized = [string stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"];
    normalized = [normalized stringByReplacingOccurrencesOfString:@"\r" withString:@"\n"];
    
    // Then convert to target line ending
    switch (lineEnding) {
        case DocumentLineEndingUnix:
            return normalized; // Already LF
            
        case DocumentLineEndingWindows:
            return [normalized stringByReplacingOccurrencesOfString:@"\n" withString:@"\r\n"];
            
        case DocumentLineEndingMac:
            return [normalized stringByReplacingOccurrencesOfString:@"\n" withString:@"\r"];
            
        default:
            return normalized;
    }
}

@end
