//
//  FindReplaceController.h
//  Notepad++ macOS
//
//  Copyright © 2024 Notepad++. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class FindReplaceController;
@class ScintillaView;

NS_ASSUME_NONNULL_BEGIN

/**
 * Delegate protocol for FindReplaceController
 * Notifies the main window about search operations and results
 */
@protocol FindReplaceControllerDelegate <NSObject>

@optional

/**
 * Called when a search operation finds a match
 * @param controller The FindReplaceController instance
 * @param range The range of the found text in the document
 */
- (void)findReplaceController:(FindReplaceController *)controller didFindMatchAtRange:(NSRange)range;

/**
 * Called when a search operation fails to find a match
 * @param controller The FindReplaceController instance
 * @param searchText The text that was not found
 */
- (void)findReplaceController:(FindReplaceController *)controller didNotFindText:(NSString *)searchText;

/**
 * Called when replace all operation completes
 * @param controller The FindReplaceController instance
 * @param count Number of replacements made
 */
- (void)findReplaceController:(FindReplaceController *)controller didReplaceAllWithCount:(NSInteger)count;

/**
 * Requests the current text content from the active document
 * @param controller The FindReplaceController instance
 * @return The current document text, or nil if no document is active
 */
- (nullable NSString *)textContentForFindReplaceController:(FindReplaceController *)controller;

/**
 * Requests the current selection range in the active document
 * @param controller The FindReplaceController instance
 * @return The current selection range, or NSMakeRange(NSNotFound, 0) if no selection
 */
- (NSRange)selectedRangeForFindReplaceController:(FindReplaceController *)controller;

/**
 * Requests to select and scroll to a range in the active document
 * @param controller The FindReplaceController instance
 * @param range The range to select
 */
- (void)findReplaceController:(FindReplaceController *)controller selectRange:(NSRange)range;

/**
 * Requests to replace text in the active document
 * @param controller The FindReplaceController instance
 * @param range The range to replace
 * @param replacement The replacement text
 */
- (void)findReplaceController:(FindReplaceController *)controller replaceRange:(NSRange)range withString:(NSString *)replacement;

/**
 * Returns the active ScintillaView for advanced search operations
 * @param controller The FindReplaceController instance
 * @return The active ScintillaView, or nil if not available
 */
- (nullable ScintillaView *)scintillaViewForFindReplaceController:(FindReplaceController *)controller;

@end

/**
 * FindReplaceController
 * 
 * A reusable Find/Replace dialog controller for the Notepad++ macOS application.
 * Provides comprehensive search and replace functionality with support for:
 * - Case-sensitive searching
 * - Whole word matching
 * - Regular expression patterns
 * - Wrap-around searching
 * - Find next/previous navigation
 * - Single and bulk replacement operations
 * 
 * The controller is designed to integrate with both NSString-based text views
 * and Scintilla editor components through its delegate protocol.
 */
@interface FindReplaceController : NSWindowController <NSTextFieldDelegate>

#pragma mark - Properties

/** Delegate for search operation callbacks */
@property (weak, nonatomic, nullable) id<FindReplaceControllerDelegate> delegate;

/** The text to search for */
@property (strong, nonatomic, readonly) NSTextField *findTextField;

/** The replacement text */
@property (strong, nonatomic, readonly) NSTextField *replaceTextField;

/** Enable case-sensitive searching */
@property (strong, nonatomic, readonly) NSButton *caseSensitiveCheckbox;

/** Match whole words only */
@property (strong, nonatomic, readonly) NSButton *wholeWordCheckbox;

/** Use regular expression patterns */
@property (strong, nonatomic, readonly) NSButton *regexCheckbox;

/** Wrap around when reaching document end */
@property (strong, nonatomic, readonly) NSButton *wrapAroundCheckbox;

/** Status label for displaying search results */
@property (strong, nonatomic, readonly) NSTextField *statusLabel;

#pragma mark - Initialization

/**
 * Initializes a new FindReplaceController
 * @return A new FindReplaceController instance
 */
- (instancetype)init;

#pragma mark - Search Operations

/**
 * Opens the find/replace window and focuses the find text field
 * @param sender The sender of the action
 */
- (IBAction)showWindow:(nullable id)sender;

/**
 * Performs a search starting from the current selection
 * Searches forward by default
 * @param sender The sender of the action
 */
- (IBAction)find:(nullable id)sender;

/**
 * Finds the next occurrence of the search text
 * @param sender The sender of the action
 */
- (IBAction)findNext:(nullable id)sender;

/**
 * Finds the previous occurrence of the search text
 * @param sender The sender of the action
 */
- (IBAction)findPrevious:(nullable id)sender;

#pragma mark - Replace Operations

/**
 * Replaces the current selection with the replacement text
 * If no text is selected, performs a find operation first
 * @param sender The sender of the action
 */
- (IBAction)replace:(nullable id)sender;

/**
 * Replaces all occurrences of the search text in the document
 * @param sender The sender of the action
 */
- (IBAction)replaceAll:(nullable id)sender;

#pragma mark - Search Options

/**
 * Returns whether case-sensitive search is enabled
 * @return YES if case-sensitive search is enabled
 */
- (BOOL)isCaseSensitive;

/**
 * Returns whether whole word matching is enabled
 * @return YES if whole word matching is enabled
 */
- (BOOL)isWholeWord;

/**
 * Returns whether regex matching is enabled
 * @return YES if regex matching is enabled
 */
- (BOOL)isRegex;

/**
 * Returns whether wrap-around is enabled
 * @return YES if wrap-around is enabled
 */
- (BOOL)isWrapAround;

/**
 * Returns the current search text
 * @return The search text, or empty string if not set
 */
- (NSString *)searchText;

/**
 * Returns the current replacement text
 * @return The replacement text, or empty string if not set
 */
- (NSString *)replacementText;

/**
 * Sets the search text programmatically
 * @param text The text to search for
 */
- (void)setSearchText:(NSString *)text;

@end

NS_ASSUME_NONNULL_END
