//
//  DocumentController.h
//  Notepad++ macOS
//
//  Copyright © 2024 Notepad++. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Document;

@interface DocumentController : NSObject

@property (strong, nonatomic) NSMutableArray<Document *> *documents;
@property (strong, nonatomic) Document *currentDocument;

// Document management
- (Document *)createNewDocument;
- (Document *)createNewDocumentWithText:(NSString *)text;
- (Document *)openDocument:(NSURL *)url;
- (BOOL)closeDocument:(Document *)document;
- (BOOL)closeCurrentDocument;
- (BOOL)closeAllDocuments;

// Save operations
- (BOOL)saveCurrentDocument;
- (BOOL)saveCurrentDocumentAs;
- (BOOL)saveDocument:(Document *)document;
- (BOOL)saveDocumentAs:(Document *)document;

// Document navigation
- (void)switchToDocument:(Document *)document;
- (void)switchToNextDocument;
- (void)switchToPreviousDocument;

// Utilities
- (NSString *)currentDocumentName;
- (NSInteger)documentCount;
- (BOOL)hasUnsavedChanges;

@end
