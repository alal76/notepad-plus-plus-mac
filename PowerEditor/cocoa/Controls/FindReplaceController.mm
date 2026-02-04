//
//  FindReplaceController.mm
//  Notepad++ macOS
//
//  Copyright © 2024 Notepad++. All rights reserved.
//

#import "FindReplaceController.h"

// TODO: Import ScintillaView when available
// #import "ScintillaView.h"

#pragma mark - Constants

static const CGFloat kWindowWidth = 500.0;
static const CGFloat kWindowHeight = 280.0;
static const CGFloat kMargin = 20.0;
static const CGFloat kControlSpacing = 10.0;
static const CGFloat kLabelWidth = 80.0;
static const CGFloat kTextFieldHeight = 24.0;
static const CGFloat kButtonWidth = 100.0;
static const CGFloat kButtonHeight = 32.0;
static const CGFloat kCheckboxHeight = 20.0;

#pragma mark - Private Interface

@interface FindReplaceController ()

// UI Components
@property (strong, nonatomic) NSTextField *findLabel;
@property (strong, nonatomic) NSTextField *replaceLabel;
@property (strong, nonatomic) NSButton *findNextButton;
@property (strong, nonatomic) NSButton *findPreviousButton;
@property (strong, nonatomic) NSButton *replaceButton;
@property (strong, nonatomic) NSButton *replaceAllButton;
@property (strong, nonatomic) NSButton *closeButton;

// Search state
@property (assign, nonatomic) NSInteger lastSearchPosition;
@property (assign, nonatomic) BOOL searchFromBeginning;

@end

#pragma mark - Implementation

@implementation FindReplaceController

#pragma mark - Initialization

- (instancetype)init {
    // Create the window
    NSRect windowFrame = NSMakeRect(0, 0, kWindowWidth, kWindowHeight);
    NSWindow *window = [[NSWindow alloc] initWithContentRect:windowFrame
                                                   styleMask:(NSWindowStyleMaskTitled |
                                                             NSWindowStyleMaskClosable |
                                                             NSWindowStyleMaskResizable)
                                                     backing:NSBackingStoreBuffered
                                                       defer:NO];
    
    self = [super initWithWindow:window];
    if (self) {
        window.title = @"Find and Replace";
        window.minSize = NSMakeSize(kWindowWidth, kWindowHeight);
        window.maxSize = NSMakeSize(kWindowWidth, kWindowHeight);
        
        _lastSearchPosition = 0;
        _searchFromBeginning = YES;
        
        [self setupUI];
        [self setupKeyboardShortcuts];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UI Setup

- (void)setupUI {
    NSView *contentView = self.window.contentView;
    contentView.wantsLayer = YES;
    
    CGFloat yPosition = kWindowHeight - kMargin;
    
    // Find text field and label
    yPosition -= kTextFieldHeight;
    _findLabel = [self createLabel:@"Find:" atPoint:NSMakePoint(kMargin, yPosition)];
    [contentView addSubview:_findLabel];
    
    CGFloat textFieldX = kMargin + kLabelWidth + kControlSpacing;
    CGFloat textFieldWidth = kWindowWidth - textFieldX - kMargin;
    _findTextField = [self createTextField:NSMakeRect(textFieldX, yPosition, textFieldWidth, kTextFieldHeight)];
    _findTextField.placeholderString = @"Enter text to find";
    _findTextField.delegate = self;
    [contentView addSubview:_findTextField];
    
    // Replace text field and label
    yPosition -= (kTextFieldHeight + kControlSpacing);
    _replaceLabel = [self createLabel:@"Replace:" atPoint:NSMakePoint(kMargin, yPosition)];
    [contentView addSubview:_replaceLabel];
    
    _replaceTextField = [self createTextField:NSMakeRect(textFieldX, yPosition, textFieldWidth, kTextFieldHeight)];
    _replaceTextField.placeholderString = @"Enter replacement text";
    _replaceTextField.delegate = self;
    [contentView addSubview:_replaceTextField];
    
    // Options checkboxes
    yPosition -= (kCheckboxHeight + kMargin);
    CGFloat checkboxX = kMargin;
    
    _caseSensitiveCheckbox = [self createCheckbox:@"Case sensitive" atPoint:NSMakePoint(checkboxX, yPosition)];
    [contentView addSubview:_caseSensitiveCheckbox];
    
    checkboxX += 150;
    _wholeWordCheckbox = [self createCheckbox:@"Whole word" atPoint:NSMakePoint(checkboxX, yPosition)];
    [contentView addSubview:_wholeWordCheckbox];
    
    yPosition -= (kCheckboxHeight + kControlSpacing);
    checkboxX = kMargin;
    
    _regexCheckbox = [self createCheckbox:@"Regular expression" atPoint:NSMakePoint(checkboxX, yPosition)];
    [contentView addSubview:_regexCheckbox];
    
    checkboxX += 150;
    _wrapAroundCheckbox = [self createCheckbox:@"Wrap around" atPoint:NSMakePoint(checkboxX, yPosition)];
    _wrapAroundCheckbox.state = NSControlStateValueOn; // Default to on
    [contentView addSubview:_wrapAroundCheckbox];
    
    // Status label
    yPosition -= (kTextFieldHeight + kMargin);
    _statusLabel = [self createStatusLabel:NSMakeRect(kMargin, yPosition, kWindowWidth - 2 * kMargin, kTextFieldHeight)];
    [contentView addSubview:_statusLabel];
    
    // Action buttons
    yPosition -= (kButtonHeight + kMargin);
    CGFloat buttonX = kWindowWidth - kMargin - kButtonWidth;
    
    _closeButton = [self createButton:@"Close" atPoint:NSMakePoint(buttonX, yPosition) action:@selector(closeWindow:)];
    _closeButton.keyEquivalent = @"\e"; // Escape key
    [contentView addSubview:_closeButton];
    
    buttonX -= (kButtonWidth + kControlSpacing);
    _replaceAllButton = [self createButton:@"Replace All" atPoint:NSMakePoint(buttonX, yPosition) action:@selector(replaceAll:)];
    [contentView addSubview:_replaceAllButton];
    
    buttonX -= (kButtonWidth + kControlSpacing);
    _replaceButton = [self createButton:@"Replace" atPoint:NSMakePoint(buttonX, yPosition) action:@selector(replace:)];
    [contentView addSubview:_replaceButton];
    
    buttonX = kMargin;
    _findNextButton = [self createButton:@"Find Next" atPoint:NSMakePoint(buttonX, yPosition) action:@selector(findNext:)];
    _findNextButton.keyEquivalent = @"\r"; // Return key
    [contentView addSubview:_findNextButton];
    
    buttonX += (kButtonWidth + kControlSpacing);
    _findPreviousButton = [self createButton:@"Find Previous" atPoint:NSMakePoint(buttonX, yPosition) action:@selector(findPrevious:)];
    [contentView addSubview:_findPreviousButton];
}

- (void)setupKeyboardShortcuts {
    // Cmd+G - Find Next
    [self.window addLocalMonitorForEventsMatchingMask:NSEventMaskKeyDown handler:^NSEvent * _Nullable(NSEvent *event) {
        if (event.modifierFlags & NSEventModifierFlagCommand) {
            if ([event.charactersIgnoringModifiers isEqualToString:@"g"]) {
                if (event.modifierFlags & NSEventModifierFlagShift) {
                    [self findPrevious:nil];
                } else {
                    [self findNext:nil];
                }
                return nil;
            }
        }
        return event;
    }];
}

#pragma mark - UI Factory Methods

- (NSTextField *)createLabel:(NSString *)title atPoint:(NSPoint)point {
    NSTextField *label = [[NSTextField alloc] initWithFrame:NSMakeRect(point.x, point.y, kLabelWidth, kTextFieldHeight)];
    label.stringValue = title;
    label.bordered = NO;
    label.editable = NO;
    label.selectable = NO;
    label.backgroundColor = [NSColor clearColor];
    label.alignment = NSTextAlignmentRight;
    return label;
}

- (NSTextField *)createTextField:(NSRect)frame {
    NSTextField *textField = [[NSTextField alloc] initWithFrame:frame];
    textField.autoresizingMask = NSViewWidthSizable;
    return textField;
}

- (NSTextField *)createStatusLabel:(NSRect)frame {
    NSTextField *label = [[NSTextField alloc] initWithFrame:frame];
    label.stringValue = @"";
    label.bordered = NO;
    label.editable = NO;
    label.selectable = NO;
    label.backgroundColor = [NSColor clearColor];
    label.textColor = [NSColor secondaryLabelColor];
    label.font = [NSFont systemFontOfSize:11];
    label.autoresizingMask = NSViewWidthSizable;
    return label;
}

- (NSButton *)createCheckbox:(NSString *)title atPoint:(NSPoint)point {
    NSButton *checkbox = [[NSButton alloc] initWithFrame:NSMakeRect(point.x, point.y, 140, kCheckboxHeight)];
    [checkbox setButtonType:NSButtonTypeSwitch];
    checkbox.title = title;
    checkbox.state = NSControlStateValueOff;
    return checkbox;
}

- (NSButton *)createButton:(NSString *)title atPoint:(NSPoint)point action:(SEL)action {
    NSButton *button = [[NSButton alloc] initWithFrame:NSMakeRect(point.x, point.y, kButtonWidth, kButtonHeight)];
    [button setButtonType:NSButtonTypeMomentaryPushIn];
    button.bezelStyle = NSBezelStyleRounded;
    button.title = title;
    button.target = self;
    button.action = action;
    return button;
}

#pragma mark - Window Management

- (void)showWindow:(id)sender {
    [super showWindow:sender];
    
    // Center window relative to main window
    if (self.window.parentWindow) {
        NSRect parentFrame = self.window.parentWindow.frame;
        NSRect windowFrame = self.window.frame;
        NSPoint center = NSMakePoint(NSMidX(parentFrame) - windowFrame.size.width / 2,
                                    NSMidY(parentFrame) - windowFrame.size.height / 2);
        [self.window setFrameOrigin:center];
    } else {
        [self.window center];
    }
    
    // Focus the find text field
    [self.window makeFirstResponder:_findTextField];
    
    // Select all text in find field if any
    if (_findTextField.stringValue.length > 0) {
        [_findTextField selectText:nil];
    }
    
    [self clearStatus];
}

- (IBAction)closeWindow:(id)sender {
    [self.window close];
}

#pragma mark - Search Operations

- (IBAction)find:(id)sender {
    [self findNext:sender];
}

- (IBAction)findNext:(id)sender {
    [self performSearchInDirection:YES];
}

- (IBAction)findPrevious:(id)sender {
    [self performSearchInDirection:NO];
}

- (void)performSearchInDirection:(BOOL)forward {
    NSString *searchText = [self searchText];
    
    if (searchText.length == 0) {
        [self setStatus:@"Please enter text to find" isError:YES];
        [self.window makeFirstResponder:_findTextField];
        return;
    }
    
    // Get the text content and current selection from delegate
    if (!self.delegate) {
        [self setStatus:@"No document available" isError:YES];
        return;
    }
    
    NSString *content = nil;
    NSRange selectedRange = NSMakeRange(NSNotFound, 0);
    
    if ([self.delegate respondsToSelector:@selector(textContentForFindReplaceController:)]) {
        content = [self.delegate textContentForFindReplaceController:self];
    }
    
    if ([self.delegate respondsToSelector:@selector(selectedRangeForFindReplaceController:)]) {
        selectedRange = [self.delegate selectedRangeForFindReplaceController:self];
    }
    
    if (!content || content.length == 0) {
        [self setStatus:@"Document is empty" isError:YES];
        return;
    }
    
    // Determine search start position
    NSInteger startPos;
    if (selectedRange.location != NSNotFound && selectedRange.length > 0) {
        startPos = forward ? (selectedRange.location + selectedRange.length) : selectedRange.location;
    } else if (selectedRange.location != NSNotFound) {
        startPos = selectedRange.location;
    } else {
        startPos = 0;
    }
    
    // Perform the search
    NSRange foundRange = [self searchInString:content
                                   searchText:searchText
                                 startPosition:startPos
                                       forward:forward];
    
    // Handle wrap-around if enabled
    if (foundRange.location == NSNotFound && [self isWrapAround]) {
        startPos = forward ? 0 : content.length;
        foundRange = [self searchInString:content
                               searchText:searchText
                             startPosition:startPos
                                   forward:forward];
        
        if (foundRange.location != NSNotFound) {
            [self setStatus:@"Search wrapped" isError:NO];
        }
    }
    
    if (foundRange.location != NSNotFound) {
        // Select the found text
        if ([self.delegate respondsToSelector:@selector(findReplaceController:selectRange:)]) {
            [self.delegate findReplaceController:self selectRange:foundRange];
        }
        
        // Notify delegate
        if ([self.delegate respondsToSelector:@selector(findReplaceController:didFindMatchAtRange:)]) {
            [self.delegate findReplaceController:self didFindMatchAtRange:foundRange];
        }
        
        [self setStatus:[NSString stringWithFormat:@"Found at position %ld", (long)foundRange.location] isError:NO];
    } else {
        // Not found
        if ([self.delegate respondsToSelector:@selector(findReplaceController:didNotFindText:)]) {
            [self.delegate findReplaceController:self didNotFindText:searchText];
        }
        
        [self setStatus:[NSString stringWithFormat:@"\"%@\" not found", searchText] isError:YES];
        NSBeep();
    }
}

- (NSRange)searchInString:(NSString *)content
               searchText:(NSString *)searchText
             startPosition:(NSInteger)startPos
                   forward:(BOOL)forward {
    
    if ([self isRegex]) {
        return [self regexSearchInString:content searchText:searchText startPosition:startPos forward:forward];
    } else {
        return [self plainSearchInString:content searchText:searchText startPosition:startPos forward:forward];
    }
}

- (NSRange)plainSearchInString:(NSString *)content
                    searchText:(NSString *)searchText
                  startPosition:(NSInteger)startPos
                        forward:(BOOL)forward {
    
    NSStringCompareOptions options = 0;
    
    if (![self isCaseSensitive]) {
        options |= NSCaseInsensitiveSearch;
    }
    
    if (!forward) {
        options |= NSBackwardsSearch;
    }
    
    NSRange searchRange;
    if (forward) {
        searchRange = NSMakeRange(startPos, content.length - startPos);
    } else {
        searchRange = NSMakeRange(0, startPos);
    }
    
    NSRange foundRange = [content rangeOfString:searchText options:options range:searchRange];
    
    // Check whole word constraint if enabled
    if (foundRange.location != NSNotFound && [self isWholeWord]) {
        if (![self isWholeWordMatch:content range:foundRange]) {
            // Continue searching
            NSInteger newStartPos;
            if (forward) {
                newStartPos = foundRange.location + 1;
                if (newStartPos < content.length) {
                    return [self plainSearchInString:content searchText:searchText startPosition:newStartPos forward:forward];
                }
            } else {
                newStartPos = foundRange.location;
                if (newStartPos > 0) {
                    return [self plainSearchInString:content searchText:searchText startPosition:newStartPos forward:forward];
                }
            }
            return NSMakeRange(NSNotFound, 0);
        }
    }
    
    return foundRange;
}

- (NSRange)regexSearchInString:(NSString *)content
                    searchText:(NSString *)searchText
                  startPosition:(NSInteger)startPos
                        forward:(BOOL)forward {
    
    NSRegularExpressionOptions regexOptions = 0;
    if (![self isCaseSensitive]) {
        regexOptions |= NSRegularExpressionCaseInsensitive;
    }
    
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:searchText
                                                                           options:regexOptions
                                                                             error:&error];
    
    if (error) {
        [self setStatus:[NSString stringWithFormat:@"Invalid regex: %@", error.localizedDescription] isError:YES];
        return NSMakeRange(NSNotFound, 0);
    }
    
    NSRange searchRange;
    if (forward) {
        searchRange = NSMakeRange(startPos, content.length - startPos);
    } else {
        searchRange = NSMakeRange(0, startPos);
    }
    
    NSArray<NSTextCheckingResult *> *matches = [regex matchesInString:content options:0 range:searchRange];
    
    if (matches.count == 0) {
        return NSMakeRange(NSNotFound, 0);
    }
    
    NSTextCheckingResult *match = forward ? matches.firstObject : matches.lastObject;
    return match.range;
}

- (BOOL)isWholeWordMatch:(NSString *)content range:(NSRange)range {
    // Check if the match is surrounded by word boundaries
    BOOL startOK = YES;
    BOOL endOK = YES;
    
    if (range.location > 0) {
        unichar prevChar = [content characterAtIndex:range.location - 1];
        startOK = ![self isWordCharacter:prevChar];
    }
    
    NSInteger endPos = range.location + range.length;
    if (endPos < content.length) {
        unichar nextChar = [content characterAtIndex:endPos];
        endOK = ![self isWordCharacter:nextChar];
    }
    
    return startOK && endOK;
}

- (BOOL)isWordCharacter:(unichar)c {
    return [[NSCharacterSet alphanumericCharacterSet] characterIsMember:c] || c == '_';
}

#pragma mark - Replace Operations

- (IBAction)replace:(id)sender {
    NSString *searchText = [self searchText];
    NSString *replaceText = [self replacementText];
    
    if (searchText.length == 0) {
        [self setStatus:@"Please enter text to find" isError:YES];
        [self.window makeFirstResponder:_findTextField];
        return;
    }
    
    if (!self.delegate) {
        [self setStatus:@"No document available" isError:YES];
        return;
    }
    
    // Get current selection
    NSRange selectedRange = NSMakeRange(NSNotFound, 0);
    if ([self.delegate respondsToSelector:@selector(selectedRangeForFindReplaceController:)]) {
        selectedRange = [self.delegate selectedRangeForFindReplaceController:self];
    }
    
    // Check if current selection matches the search text
    if (selectedRange.location != NSNotFound && selectedRange.length > 0) {
        NSString *content = nil;
        if ([self.delegate respondsToSelector:@selector(textContentForFindReplaceController:)]) {
            content = [self.delegate textContentForFindReplaceController:self];
        }
        
        if (content && selectedRange.location + selectedRange.length <= content.length) {
            NSString *selectedText = [content substringWithRange:selectedRange];
            
            BOOL matches = NO;
            if ([self isRegex]) {
                NSRegularExpressionOptions options = [self isCaseSensitive] ? 0 : NSRegularExpressionCaseInsensitive;
                NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:searchText options:options error:nil];
                matches = [regex numberOfMatchesInString:selectedText options:0 range:NSMakeRange(0, selectedText.length)] > 0;
            } else {
                NSStringCompareOptions options = [self isCaseSensitive] ? 0 : NSCaseInsensitiveSearch;
                matches = [selectedText compare:searchText options:options] == NSOrderedSame;
            }
            
            if (matches) {
                // Replace the selection
                if ([self.delegate respondsToSelector:@selector(findReplaceController:replaceRange:withString:)]) {
                    [self.delegate findReplaceController:self replaceRange:selectedRange withString:replaceText];
                    [self setStatus:@"Replaced" isError:NO];
                }
                
                // Find next occurrence
                [self findNext:nil];
                return;
            }
        }
    }
    
    // No matching selection, perform find first
    [self findNext:nil];
}

- (IBAction)replaceAll:(id)sender {
    NSString *searchText = [self searchText];
    NSString *replaceText = [self replacementText];
    
    if (searchText.length == 0) {
        [self setStatus:@"Please enter text to find" isError:YES];
        [self.window makeFirstResponder:_findTextField];
        return;
    }
    
    if (!self.delegate) {
        [self setStatus:@"No document available" isError:YES];
        return;
    }
    
    NSString *content = nil;
    if ([self.delegate respondsToSelector:@selector(textContentForFindReplaceController:)]) {
        content = [self.delegate textContentForFindReplaceController:self];
    }
    
    if (!content || content.length == 0) {
        [self setStatus:@"Document is empty" isError:YES];
        return;
    }
    
    // Find all matches
    NSMutableArray<NSValue *> *matches = [NSMutableArray array];
    NSInteger searchPos = 0;
    
    while (searchPos < content.length) {
        NSRange foundRange = [self searchInString:content searchText:searchText startPosition:searchPos forward:YES];
        
        if (foundRange.location == NSNotFound || foundRange.location < searchPos) {
            break;
        }
        
        [matches addObject:[NSValue valueWithRange:foundRange]];
        searchPos = foundRange.location + foundRange.length;
    }
    
    if (matches.count == 0) {
        [self setStatus:[NSString stringWithFormat:@"\"%@\" not found", searchText] isError:YES];
        NSBeep();
        return;
    }
    
    // Replace all matches in reverse order to maintain range validity
    for (NSInteger i = matches.count - 1; i >= 0; i--) {
        NSRange range = [matches[i] rangeValue];
        if ([self.delegate respondsToSelector:@selector(findReplaceController:replaceRange:withString:)]) {
            [self.delegate findReplaceController:self replaceRange:range withString:replaceText];
        }
    }
    
    // Notify delegate
    if ([self.delegate respondsToSelector:@selector(findReplaceController:didReplaceAllWithCount:)]) {
        [self.delegate findReplaceController:self didReplaceAllWithCount:matches.count];
    }
    
    [self setStatus:[NSString stringWithFormat:@"Replaced %ld occurrence%@",
                    (long)matches.count,
                    matches.count == 1 ? @"" : @"s"] isError:NO];
}

#pragma mark - Search Options

- (BOOL)isCaseSensitive {
    return _caseSensitiveCheckbox.state == NSControlStateValueOn;
}

- (BOOL)isWholeWord {
    return _wholeWordCheckbox.state == NSControlStateValueOn;
}

- (BOOL)isRegex {
    return _regexCheckbox.state == NSControlStateValueOn;
}

- (BOOL)isWrapAround {
    return _wrapAroundCheckbox.state == NSControlStateValueOn;
}

- (NSString *)searchText {
    return _findTextField.stringValue ?: @"";
}

- (NSString *)replacementText {
    return _replaceTextField.stringValue ?: @"";
}

- (void)setSearchText:(NSString *)text {
    _findTextField.stringValue = text ?: @"";
}

#pragma mark - Status Management

- (void)setStatus:(NSString *)message isError:(BOOL)isError {
    _statusLabel.stringValue = message;
    _statusLabel.textColor = isError ? [NSColor systemRedColor] : [NSColor secondaryLabelColor];
}

- (void)clearStatus {
    _statusLabel.stringValue = @"";
}

#pragma mark - NSTextFieldDelegate

- (void)controlTextDidChange:(NSNotification *)notification {
    // Clear status when user types
    [self clearStatus];
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector {
    // Handle Return key in text fields
    if (commandSelector == @selector(insertNewline:)) {
        [self findNext:nil];
        return YES;
    }
    return NO;
}

@end
