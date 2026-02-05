//
//  ScintillaWrapper.h
//  Notepad++ macOS
//
//  Bridge between Notepad++ Document model and Scintilla editor
//  Copyright © 2024 Notepad++. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ScintillaView;
@class Document;

/**
 * ScintillaWrapper provides a bridge between the Document model and ScintillaView.
 * It manages the lifecycle of a ScintillaView instance and provides methods to
 * synchronize document state with the editor.
 */
@interface ScintillaWrapper : NSObject

@property (strong, nonatomic) ScintillaView *scintillaView;
@property (weak, nonatomic) Document *document;
@property (assign, nonatomic) BOOL suppressDocumentUpdates;

/**
 * Create a new wrapper with an associated document.
 */
- (instancetype)initWithDocument:(Document *)document;

/**
 * Create and configure the ScintillaView with given frame.
 */
- (void)createScintillaViewWithFrame:(NSRect)frame;

/**
 * Load document content into Scintilla.
 */
- (void)loadDocumentContent;

/**
 * Save Scintilla content back to document.
 */
- (void)saveDocumentContent;

/**
 * Apply document settings (encoding, line ending, language) to Scintilla.
 */
- (void)applyDocumentSettings;

/**
 * Configure Scintilla with user preferences (font, tab size, etc.).
 */
- (void)applyUserPreferences;

/**
 * Get current text from Scintilla.
 */
- (NSString *)getText;

/**
 * Set text in Scintilla.
 */
- (void)setText:(NSString *)text;

/**
 * Get selected text from Scintilla.
 */
- (NSString *)getSelectedText;

/**
 * Check if document has been modified in Scintilla.
 */
- (BOOL)isModified;

/**
 * Set modified state in Scintilla.
 */
- (void)setModified:(BOOL)modified;

/**
 * Editing operations.
 */
- (void)cut;
- (void)copy;
- (void)paste;
- (void)undo;
- (void)redo;
- (void)selectAll;
- (void)deleteSelection;

/**
 * Search operations.
 */
- (BOOL)findText:(NSString *)searchText
       matchCase:(BOOL)matchCase
       wholeWord:(BOOL)wholeWord
          regexp:(BOOL)regexp
            wrap:(BOOL)wrap
       backwards:(BOOL)backwards;

- (NSInteger)replaceText:(NSString *)searchText
              withText:(NSString *)replaceText
             matchCase:(BOOL)matchCase
             wholeWord:(BOOL)wholeWord
                regexp:(BOOL)regexp
                 doAll:(BOOL)doAll;

/**
 * View operations.
 */
- (void)zoomIn;
- (void)zoomOut;
- (void)resetZoom;

/**
 * Get cursor position (line and column).
 */
- (void)getCursorPosition:(NSInteger *)line column:(NSInteger *)column;

/**
 * Get document statistics.
 */
- (NSInteger)getLineCount;
- (NSInteger)getTextLength;

@end
