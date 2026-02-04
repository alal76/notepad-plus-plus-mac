//
//  Document.h
//  Notepad++ macOS
//
//  Copyright © 2024 Notepad++. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, DocumentEncoding) {
    DocumentEncodingUTF8 = 0,
    DocumentEncodingUTF16,
    DocumentEncodingUTF16BE,
    DocumentEncodingASCII,
    DocumentEncodingISO88591,
};

typedef NS_ENUM(NSInteger, DocumentLineEnding) {
    DocumentLineEndingUnix = 0,    // LF
    DocumentLineEndingWindows,     // CRLF
    DocumentLineEndingMac,         // CR
};

@interface Document : NSObject

@property (strong, nonatomic) NSURL *fileURL;
@property (strong, nonatomic) NSString *content;
@property (assign, nonatomic) BOOL isModified;
@property (assign, nonatomic) DocumentEncoding encoding;
@property (assign, nonatomic) DocumentLineEnding lineEnding;
@property (strong, nonatomic) NSString *languageType;

// Display properties
@property (readonly, nonatomic) NSString *displayName;
@property (readonly, nonatomic) NSString *encodingName;
@property (readonly, nonatomic) NSString *lineEndingName;

// File operations
- (BOOL)loadFromURL:(NSURL *)url error:(NSError **)error;
- (BOOL)saveToURL:(NSURL *)url error:(NSError **)error;

// Content operations
- (void)setContentWithoutModifying:(NSString *)content;

@end
