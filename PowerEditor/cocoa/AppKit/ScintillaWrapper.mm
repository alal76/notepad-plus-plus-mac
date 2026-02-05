//
//  ScintillaWrapper.mm
//  Notepad++ macOS
//
//  Bridge between Notepad++ Document model and Scintilla editor
//  Copyright © 2024 Notepad++. All rights reserved.
//

#import "ScintillaWrapper.h"
#import "Document.h"
#import "ConfigManager.h"

// Import Scintilla headers
#import <Cocoa/Cocoa.h>

// Forward declare ScintillaView to avoid compile-time dependency
@class ScintillaView;

// Scintilla message codes (from Scintilla.h)
#define SCI_SETTEXT 2181
#define SCI_GETTEXT 2182
#define SCI_GETTEXTLENGTH 2183
#define SCI_CUT 2177
#define SCI_COPY 2178
#define SCI_PASTE 2179
#define SCI_UNDO 2176
#define SCI_REDO 2011
#define SCI_SELECTALL 2013
#define SCI_CLEAR 2180
#define SCI_GETSELTEXT 2161
#define SCI_SETSEL 2160
#define SCI_GOTOPOS 2025
#define SCI_GETLINECOUNT 2154
#define SCI_GETCURRENTPOS 2008
#define SCI_GETCOLUMN 2129
#define SCI_LINEFROMPOSITION 2166
#define SCI_SETSAVEPOINT 2014
#define SCI_GETMODIFY 2159
#define SCI_ZOOMIN 2333
#define SCI_ZOOMOUT 2334
#define SCI_SETZOOM 2373
#define SCI_GETZOOM 2374
#define SCI_SETLEXER 4001
#define SCI_SETEOLMODE 2031
#define SCI_SETTABWIDTH 2036
#define SCI_SETUSETABS 2124
#define SCI_SETVIEWWS 2021
#define SCI_SETINDENTATIONGUIDES 2132
#define SCI_STYLESETFONT 4003
#define SCI_STYLESETSIZE 4005
#define SCI_STYLECLEARALL 2050

// EOL modes
#define SC_EOL_CRLF 0
#define SC_EOL_CR 1
#define SC_EOL_LF 2

@interface ScintillaWrapper ()

@property (assign, nonatomic) BOOL scintillaLoaded;

@end

@implementation ScintillaWrapper

- (instancetype)initWithDocument:(Document *)document {
    self = [super init];
    if (self) {
        _document = document;
        _suppressDocumentUpdates = NO;
        _scintillaLoaded = NO;
    }
    return self;
}

- (void)createScintillaViewWithFrame:(NSRect)frame {
    // Dynamically load ScintillaView class
    Class scintillaClass = NSClassFromString(@"ScintillaView");
    
    if (!scintillaClass) {
        NSLog(@"ERROR: ScintillaView class not found. Make sure Scintilla.framework is linked.");
        
        // Create a placeholder NSTextView for testing without Scintilla
        NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:frame];
        scrollView.hasVerticalScroller = YES;
        scrollView.hasHorizontalScroller = YES;
        scrollView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        
        NSTextView *textView = [[NSTextView alloc] initWithFrame:scrollView.bounds];
        textView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        textView.font = [NSFont fontWithName:@"Menlo" size:13.0];
        textView.string = self.document.content ?: @"";
        
        scrollView.documentView = textView;
        
        // Store as id to avoid type issues
        self.scintillaView = (ScintillaView *)scrollView;
        self.scintillaLoaded = NO;
        
        NSLog(@"WARNING: Using NSTextView as fallback. Full Scintilla features not available.");
        return;
    }
    
    // Create actual ScintillaView
    self.scintillaView = [[scintillaClass alloc] initWithFrame:frame];
    self.scintillaLoaded = YES;
    
    if (!self.scintillaView) {
        NSLog(@"ERROR: Failed to create ScintillaView instance");
        return;
    }
    
    // Configure ScintillaView
    [self applyUserPreferences];
    [self applyDocumentSettings];
    
    // Load document content
    if (self.document.content) {
        [self loadDocumentContent];
    }
    
    NSLog(@"ScintillaView created successfully");
}

#pragma mark - Document Synchronization

- (void)loadDocumentContent {
    if (!self.document) {
        return;
    }
    
    self.suppressDocumentUpdates = YES;
    
    if (self.scintillaLoaded) {
        // Use Scintilla API
        [self setText:self.document.content];
        [self setModified:NO];
    } else {
        // Fallback to NSTextView
        if ([self.scintillaView isKindOfClass:[NSScrollView class]]) {
            NSScrollView *scrollView = (NSScrollView *)self.scintillaView;
            NSTextView *textView = (NSTextView *)scrollView.documentView;
            if ([textView isKindOfClass:[NSTextView class]]) {
                textView.string = self.document.content ?: @"";
            }
        }
    }
    
    self.suppressDocumentUpdates = NO;
    
    NSLog(@"Loaded document content: %ld characters", (long)self.document.content.length);
}

- (void)saveDocumentContent {
    if (!self.document || self.suppressDocumentUpdates) {
        return;
    }
    
    NSString *text = [self getText];
    if (text) {
        self.document.content = text;
        NSLog(@"Saved document content: %ld characters", (long)text.length);
    }
}

- (void)applyDocumentSettings {
    if (!self.scintillaLoaded || !self.document) {
        return;
    }
    
    // Set EOL mode based on document line ending
    int eolMode = SC_EOL_LF;
    switch (self.document.lineEnding) {
        case DocumentLineEndingWindows:
            eolMode = SC_EOL_CRLF;
            break;
        case DocumentLineEndingMac:
            eolMode = SC_EOL_CR;
            break;
        case DocumentLineEndingUnix:
        default:
            eolMode = SC_EOL_LF;
            break;
    }
    
    [self sendMessage:SCI_SETEOLMODE wParam:eolMode lParam:0];
    
    // Set lexer based on language type
    // TODO: Map language type to lexer ID
    
    NSLog(@"Applied document settings (EOL mode: %d)", eolMode);
}

- (void)applyUserPreferences {
    ConfigManager *config = [ConfigManager sharedManager];
    
    if (self.scintillaLoaded) {
        // Clear all styles first
        [self sendMessage:SCI_STYLECLEARALL wParam:0 lParam:0];
        
        // Set font and size
        NSString *fontName = [config fontName];
        CGFloat fontSize = [config fontSize];
        
        // Apply to all styles (0-127)
        for (int style = 0; style < 128; style++) {
            [self sendMessage:SCI_STYLESETFONT wParam:style lParam:(sptr_t)[fontName UTF8String]];
            [self sendMessage:SCI_STYLESETSIZE wParam:style lParam:(long)fontSize];
        }
        
        // Set tab width
        NSInteger tabSize = [config tabSize];
        [self sendMessage:SCI_SETTABWIDTH wParam:tabSize lParam:0];
        
        // Set use tabs vs spaces
        BOOL useSpaces = [config useSpacesInsteadOfTabs];
        [self sendMessage:SCI_SETUSETABS wParam:!useSpaces lParam:0];
        
        NSLog(@"Applied user preferences (font: %@ %g, tab: %ld, spaces: %d)",
              fontName, fontSize, (long)tabSize, useSpaces);
    } else {
        // Fallback to NSTextView
        if ([self.scintillaView isKindOfClass:[NSScrollView class]]) {
            NSScrollView *scrollView = (NSScrollView *)self.scintillaView;
            NSTextView *textView = (NSTextView *)scrollView.documentView;
            if ([textView isKindOfClass:[NSTextView class]]) {
                NSString *fontName = [config fontName];
                CGFloat fontSize = [config fontSize];
                textView.font = [NSFont fontWithName:fontName size:fontSize];
            }
        }
    }
}

#pragma mark - Text Operations

- (NSString *)getText {
    if (!self.scintillaView) {
        return @"";
    }
    
    if (self.scintillaLoaded) {
        // Get text length
        long length = [self sendMessage:SCI_GETTEXTLENGTH wParam:0 lParam:0];
        if (length == 0) {
            return @"";
        }
        
        // Allocate buffer
        char *buffer = (char *)malloc(length + 1);
        if (!buffer) {
            return @"";
        }
        
        // Get text
        [self sendMessage:SCI_GETTEXT wParam:length + 1 lParam:(sptr_t)buffer];
        
        NSString *text = [NSString stringWithUTF8String:buffer];
        free(buffer);
        
        return text ?: @"";
    } else {
        // Fallback to NSTextView
        if ([self.scintillaView isKindOfClass:[NSScrollView class]]) {
            NSScrollView *scrollView = (NSScrollView *)self.scintillaView;
            NSTextView *textView = (NSTextView *)scrollView.documentView;
            if ([textView isKindOfClass:[NSTextView class]]) {
                return textView.string;
            }
        }
        return @"";
    }
}

- (void)setText:(NSString *)text {
    if (!self.scintillaView || !text) {
        return;
    }
    
    if (self.scintillaLoaded) {
        const char *utf8Text = [text UTF8String];
        [self sendMessage:SCI_SETTEXT wParam:0 lParam:(sptr_t)utf8Text];
    } else {
        // Fallback to NSTextView
        if ([self.scintillaView isKindOfClass:[NSScrollView class]]) {
            NSScrollView *scrollView = (NSScrollView *)self.scintillaView;
            NSTextView *textView = (NSTextView *)scrollView.documentView;
            if ([textView isKindOfClass:[NSTextView class]]) {
                textView.string = text;
            }
        }
    }
}

- (NSString *)getSelectedText {
    if (!self.scintillaView) {
        return @"";
    }
    
    if (self.scintillaLoaded) {
        // Get selected text length
        long length = [self sendMessage:SCI_GETSELTEXT wParam:0 lParam:0];
        if (length == 0) {
            return @"";
        }
        
        // Allocate buffer
        char *buffer = (char *)malloc(length + 1);
        if (!buffer) {
            return @"";
        }
        
        // Get selected text
        [self sendMessage:SCI_GETSELTEXT wParam:0 lParam:(sptr_t)buffer];
        
        NSString *text = [NSString stringWithUTF8String:buffer];
        free(buffer);
        
        return text ?: @"";
    } else {
        // Fallback to NSTextView
        if ([self.scintillaView isKindOfClass:[NSScrollView class]]) {
            NSScrollView *scrollView = (NSScrollView *)self.scintillaView;
            NSTextView *textView = (NSTextView *)scrollView.documentView;
            if ([textView isKindOfClass:[NSTextView class]]) {
                NSRange range = textView.selectedRange;
                if (range.length > 0) {
                    return [textView.string substringWithRange:range];
                }
            }
        }
        return @"";
    }
}

- (BOOL)isModified {
    if (!self.scintillaView) {
        return NO;
    }
    
    if (self.scintillaLoaded) {
        return [self sendMessage:SCI_GETMODIFY wParam:0 lParam:0] != 0;
    }
    
    return NO;
}

- (void)setModified:(BOOL)modified {
    if (!self.scintillaView) {
        return;
    }
    
    if (self.scintillaLoaded && !modified) {
        [self sendMessage:SCI_SETSAVEPOINT wParam:0 lParam:0];
    }
}

#pragma mark - Editing Operations

- (void)cut {
    if (self.scintillaLoaded) {
        [self sendMessage:SCI_CUT wParam:0 lParam:0];
    } else {
        // Fallback
        if ([self.scintillaView isKindOfClass:[NSScrollView class]]) {
            NSScrollView *scrollView = (NSScrollView *)self.scintillaView;
            NSTextView *textView = (NSTextView *)scrollView.documentView;
            if ([textView isKindOfClass:[NSTextView class]]) {
                [textView cut:nil];
            }
        }
    }
}

- (void)copy {
    if (self.scintillaLoaded) {
        [self sendMessage:SCI_COPY wParam:0 lParam:0];
    } else {
        // Fallback
        if ([self.scintillaView isKindOfClass:[NSScrollView class]]) {
            NSScrollView *scrollView = (NSScrollView *)self.scintillaView;
            NSTextView *textView = (NSTextView *)scrollView.documentView;
            if ([textView isKindOfClass:[NSTextView class]]) {
                [textView copy:nil];
            }
        }
    }
}

- (void)paste {
    if (self.scintillaLoaded) {
        [self sendMessage:SCI_PASTE wParam:0 lParam:0];
    } else {
        // Fallback
        if ([self.scintillaView isKindOfClass:[NSScrollView class]]) {
            NSScrollView *scrollView = (NSScrollView *)self.scintillaView;
            NSTextView *textView = (NSTextView *)scrollView.documentView;
            if ([textView isKindOfClass:[NSTextView class]]) {
                [textView paste:nil];
            }
        }
    }
}

- (void)undo {
    if (self.scintillaLoaded) {
        [self sendMessage:SCI_UNDO wParam:0 lParam:0];
    } else {
        // Fallback
        if ([self.scintillaView isKindOfClass:[NSScrollView class]]) {
            NSScrollView *scrollView = (NSScrollView *)self.scintillaView;
            NSTextView *textView = (NSTextView *)scrollView.documentView;
            if ([textView isKindOfClass:[NSTextView class]]) {
                [textView.undoManager undo];
            }
        }
    }
}

- (void)redo {
    if (self.scintillaLoaded) {
        [self sendMessage:SCI_REDO wParam:0 lParam:0];
    } else {
        // Fallback
        if ([self.scintillaView isKindOfClass:[NSScrollView class]]) {
            NSScrollView *scrollView = (NSScrollView *)self.scintillaView;
            NSTextView *textView = (NSTextView *)scrollView.documentView;
            if ([textView isKindOfClass:[NSTextView class]]) {
                [textView.undoManager redo];
            }
        }
    }
}

- (void)selectAll {
    if (self.scintillaLoaded) {
        [self sendMessage:SCI_SELECTALL wParam:0 lParam:0];
    } else {
        // Fallback
        if ([self.scintillaView isKindOfClass:[NSScrollView class]]) {
            NSScrollView *scrollView = (NSScrollView *)self.scintillaView;
            NSTextView *textView = (NSTextView *)scrollView.documentView;
            if ([textView isKindOfClass:[NSTextView class]]) {
                [textView selectAll:nil];
            }
        }
    }
}

- (void)deleteSelection {
    if (self.scintillaLoaded) {
        [self sendMessage:SCI_CLEAR wParam:0 lParam:0];
    } else {
        // Fallback
        if ([self.scintillaView isKindOfClass:[NSScrollView class]]) {
            NSScrollView *scrollView = (NSScrollView *)self.scintillaView;
            NSTextView *textView = (NSTextView *)scrollView.documentView;
            if ([textView isKindOfClass:[NSTextView class]]) {
                [textView delete:nil];
            }
        }
    }
}

#pragma mark - Search Operations

- (BOOL)findText:(NSString *)searchText
       matchCase:(BOOL)matchCase
       wholeWord:(BOOL)wholeWord
          regexp:(BOOL)regexp
            wrap:(BOOL)wrap
       backwards:(BOOL)backwards {
    
    if (!self.scintillaView || !searchText || searchText.length == 0) {
        return NO;
    }
    
    if (self.scintillaLoaded) {
        // Use ScintillaView's built-in find method if available
        if ([self.scintillaView respondsToSelector:@selector(findAndHighlightText:matchCase:wholeWord:scrollTo:wrap:backwards:)]) {
            return [self.scintillaView performSelector:@selector(findAndHighlightText:matchCase:wholeWord:scrollTo:wrap:backwards:)
                                            withObject:searchText
                                            withObject:@(matchCase)
                                            withObject:@(wholeWord)
                                            withObject:@YES
                                            withObject:@(wrap)
                                            withObject:@(backwards)] != nil;
        }
    }
    
    // TODO: Implement custom search using Scintilla messages
    return NO;
}

- (NSInteger)replaceText:(NSString *)searchText
              withText:(NSString *)replaceText
             matchCase:(BOOL)matchCase
             wholeWord:(BOOL)wholeWord
                regexp:(BOOL)regexp
                 doAll:(BOOL)doAll {
    
    if (!self.scintillaView || !searchText || !replaceText) {
        return 0;
    }
    
    if (self.scintillaLoaded) {
        // Use ScintillaView's built-in replace method if available
        if ([self.scintillaView respondsToSelector:@selector(findAndReplaceText:byText:matchCase:wholeWord:doAll:)]) {
            NSNumber *result = [self.scintillaView performSelector:@selector(findAndReplaceText:byText:matchCase:wholeWord:doAll:)
                                                        withObject:searchText
                                                        withObject:replaceText
                                                        withObject:@(matchCase)
                                                        withObject:@(wholeWord)
                                                        withObject:@(doAll)];
            return [result integerValue];
        }
    }
    
    // TODO: Implement custom replace using Scintilla messages
    return 0;
}

#pragma mark - View Operations

- (void)zoomIn {
    if (self.scintillaLoaded) {
        [self sendMessage:SCI_ZOOMIN wParam:0 lParam:0];
    }
}

- (void)zoomOut {
    if (self.scintillaLoaded) {
        [self sendMessage:SCI_ZOOMOUT wParam:0 lParam:0];
    }
}

- (void)resetZoom {
    if (self.scintillaLoaded) {
        [self sendMessage:SCI_SETZOOM wParam:0 lParam:0];
    }
}

#pragma mark - Document Statistics

- (void)getCursorPosition:(NSInteger *)line column:(NSInteger *)column {
    if (!self.scintillaView) {
        if (line) *line = 0;
        if (column) *column = 0;
        return;
    }
    
    if (self.scintillaLoaded) {
        long pos = [self sendMessage:SCI_GETCURRENTPOS wParam:0 lParam:0];
        
        if (line) {
            *line = [self sendMessage:SCI_LINEFROMPOSITION wParam:pos lParam:0] + 1;
        }
        
        if (column) {
            *column = [self sendMessage:SCI_GETCOLUMN wParam:pos lParam:0] + 1;
        }
    } else {
        if (line) *line = 1;
        if (column) *column = 1;
    }
}

- (NSInteger)getLineCount {
    if (!self.scintillaView) {
        return 0;
    }
    
    if (self.scintillaLoaded) {
        return [self sendMessage:SCI_GETLINECOUNT wParam:0 lParam:0];
    }
    
    return 1;
}

- (NSInteger)getTextLength {
    if (!self.scintillaView) {
        return 0;
    }
    
    if (self.scintillaLoaded) {
        return [self sendMessage:SCI_GETTEXTLENGTH wParam:0 lParam:0];
    }
    
    return 0;
}

#pragma mark - Helper Methods

- (long)sendMessage:(unsigned int)message wParam:(uptr_t)wParam lParam:(sptr_t)lParam {
    if (!self.scintillaView || !self.scintillaLoaded) {
        return 0;
    }
    
    // Use Scintilla's message method
    if ([self.scintillaView respondsToSelector:@selector(message:wParam:lParam:)]) {
        NSNumber *result = [self.scintillaView performSelector:@selector(message:wParam:lParam:)
                                                    withObject:@(message)
                                                    withObject:@(wParam)
                                                    withObject:@(lParam)];
        return [result longValue];
    }
    
    return 0;
}

@end
