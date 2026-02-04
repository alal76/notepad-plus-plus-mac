# FindReplaceController

A comprehensive Find and Replace dialog controller for the Notepad++ macOS application.

## Overview

`FindReplaceController` is a standalone, reusable component that provides full-featured search and replace functionality for text editing applications on macOS. It's designed to integrate seamlessly with both NSTextView-based editors and the Scintilla text component.

## Features

### Search Capabilities
- **Find Next/Previous**: Navigate through search results in both directions
- **Case Sensitive Search**: Toggle case-sensitive matching
- **Whole Word Matching**: Match complete words only
- **Regular Expression Support**: Use regex patterns for complex searches
- **Wrap Around**: Automatically continue search from document beginning/end

### Replace Capabilities
- **Replace**: Replace the current match and find the next
- **Replace All**: Replace all occurrences in the document at once

### User Interface
- Clean, native macOS appearance using AppKit
- Resizable window with sensible defaults
- Real-time status feedback
- Keyboard shortcuts for efficient workflow
- Non-modal window allows working with document while searching

## Integration

### Basic Setup

1. **Import the header:**
```objc
#import "FindReplaceController.h"
```

2. **Create an instance:**
```objc
@property (strong, nonatomic) FindReplaceController *findReplaceController;

// In your initialization
_findReplaceController = [[FindReplaceController alloc] init];
_findReplaceController.delegate = self;
```

3. **Show the dialog:**
```objc
- (void)showFindDialog:(id)sender {
    [self.findReplaceController showWindow:sender];
}
```

### Implementing the Delegate Protocol

Implement `FindReplaceControllerDelegate` to provide document access:

```objc
@interface YourWindowController () <FindReplaceControllerDelegate>
@end

@implementation YourWindowController

#pragma mark - FindReplaceControllerDelegate

- (NSString *)textContentForFindReplaceController:(FindReplaceController *)controller {
    // Return the current document's text content
    return self.textView.string;
}

- (NSRange)selectedRangeForFindReplaceController:(FindReplaceController *)controller {
    // Return the current selection range
    return self.textView.selectedRange;
}

- (void)findReplaceController:(FindReplaceController *)controller selectRange:(NSRange)range {
    // Select the specified range and scroll it into view
    [self.textView setSelectedRange:range];
    [self.textView scrollRangeToVisible:range];
}

- (void)findReplaceController:(FindReplaceController *)controller 
                 replaceRange:(NSRange)range 
                   withString:(NSString *)replacement {
    // Replace text at the specified range
    [self.textView replaceCharactersInRange:range withString:replacement];
}

- (void)findReplaceController:(FindReplaceController *)controller 
              didFindMatchAtRange:(NSRange)range {
    // Optional: Update UI to indicate successful find
    NSLog(@"Found match at position %ld", (long)range.location);
}

- (void)findReplaceController:(FindReplaceController *)controller 
                 didNotFindText:(NSString *)searchText {
    // Optional: Show alert or update status bar
    NSLog(@"Text '%@' not found", searchText);
}

- (void)findReplaceController:(FindReplaceController *)controller 
          didReplaceAllWithCount:(NSInteger)count {
    // Optional: Show completion message
    NSLog(@"Replaced %ld occurrence(s)", (long)count);
}

@end
```

### Scintilla Integration

For Scintilla-based editors, implement the Scintilla-specific delegate method:

```objc
- (ScintillaView *)scintillaViewForFindReplaceController:(FindReplaceController *)controller {
    // Return the active ScintillaView
    return self.currentScintillaView;
}
```

Then extend the delegate methods to use Scintilla's native search capabilities:

```objc
- (void)findReplaceController:(FindReplaceController *)controller selectRange:(NSRange)range {
    ScintillaView *scintilla = [self scintillaViewForFindReplaceController:controller];
    if (scintilla) {
        [scintilla setSelectionStart:range.location];
        [scintilla setSelectionEnd:range.location + range.length];
        [scintilla scrollToLine:[scintilla lineFromPosition:range.location]];
    }
}
```

## Keyboard Shortcuts

The FindReplaceController supports standard macOS keyboard shortcuts:

- **Cmd+F**: Show find dialog (implement in main window)
- **Cmd+G**: Find next
- **Cmd+Shift+G**: Find previous
- **Return**: Find next
- **Escape**: Close dialog
- **Tab**: Move between fields

## Programmatic Control

### Setting Search Text

```objc
[self.findReplaceController setSearchText:@"TODO"];
[self.findReplaceController showWindow:nil];
```

### Getting Current Options

```objc
BOOL caseSensitive = [self.findReplaceController isCaseSensitive];
BOOL wholeWord = [self.findReplaceController isWholeWord];
BOOL regex = [self.findReplaceController isRegex];
BOOL wrapAround = [self.findReplaceController isWrapAround];

NSString *searchText = [self.findReplaceController searchText];
NSString *replaceText = [self.findReplaceController replacementText];
```

## Architecture

### Design Patterns
- **Delegate Pattern**: Decouples the controller from the document model
- **MVC**: Clear separation between UI (View), logic (Controller), and data (Model via delegate)
- **Factory Methods**: Consistent UI element creation

### Key Components

1. **Window Management**: NSWindowController subclass with custom window
2. **UI Layout**: Programmatic layout using NSView and Auto-resizing masks
3. **Search Engine**: 
   - Plain text search using NSString methods
   - Regex search using NSRegularExpression
   - Word boundary detection for whole-word matching
4. **State Management**: Tracks search position and options

### Search Algorithm

The search implementation supports multiple modes:

**Plain Text Search:**
- Uses `NSString rangeOfString:options:range:`
- Efficient for simple text matching
- Supports case-insensitive and backward search

**Regular Expression Search:**
- Uses `NSRegularExpression`
- Validates regex pattern before searching
- Reports pattern errors to user

**Whole Word Matching:**
- Post-processes matches to verify word boundaries
- Uses character set checking for alphanumeric + underscore

**Wrap Around:**
- Automatically continues from document start/end
- Provides visual feedback when wrapping occurs

## UI Customization

The window size and layout can be adjusted by modifying the constants:

```objc
static const CGFloat kWindowWidth = 500.0;
static const CGFloat kWindowHeight = 280.0;
static const CGFloat kMargin = 20.0;
static const CGFloat kControlSpacing = 10.0;
```

## Error Handling

The controller provides comprehensive error feedback:

- **Empty search field**: Prompts user to enter text
- **No document available**: Reports when delegate is not set
- **Empty document**: Handles documents with no content
- **Invalid regex**: Reports regex syntax errors with details
- **No matches found**: Visual and audio feedback (beep)

## Performance Considerations

- **Incremental Search**: Searches from current position, not from beginning
- **Efficient Replace All**: Replaces in reverse order to maintain range validity
- **Lazy Evaluation**: Only gets document content when needed
- **Smart Status Updates**: Clears status automatically when user types

## Thread Safety

⚠️ **Important**: The FindReplaceController is not thread-safe. All operations must be performed on the main thread.

```objc
dispatch_async(dispatch_get_main_queue(), ^{
    [self.findReplaceController findNext:nil];
});
```

## Future Enhancements

Potential improvements for future versions:

- [ ] Search history and recent searches dropdown
- [ ] Search in selection only
- [ ] Multi-file search (Find in Files)
- [ ] Search results panel
- [ ] Incremental search as you type
- [ ] Highlight all matches
- [ ] Search scope options (current document, all open documents, project)
- [ ] Bookmarking found results
- [ ] Advanced regex builder/tester

## Testing

### Manual Testing Checklist

- [ ] Find with plain text
- [ ] Find with case sensitivity on/off
- [ ] Find whole words only
- [ ] Find with regular expressions
- [ ] Find next/previous navigation
- [ ] Wrap around behavior
- [ ] Replace single occurrence
- [ ] Replace all occurrences
- [ ] Status messages display correctly
- [ ] Keyboard shortcuts work
- [ ] Window positioning and sizing
- [ ] Text field focus management

### Test Cases

```objc
// Example test case structure
- (void)testFindNextCaseSensitive {
    NSString *content = @"Hello world hello WORLD";
    [self.findReplaceController setSearchText:@"hello"];
    // Enable case sensitive
    // Perform search
    // Assert correct range found
}
```

## Example Usage

See the MainWindowController implementation for a complete integration example:

```objc
// MainWindowController.h
@property (strong, nonatomic) FindReplaceController *findReplaceController;

// MainWindowController.mm
- (void)setupFindReplace {
    self.findReplaceController = [[FindReplaceController alloc] init];
    self.findReplaceController.delegate = self;
}

- (void)find:(id)sender {
    [self.findReplaceController showWindow:sender];
}

- (void)findNext:(id)sender {
    [self.findReplaceController findNext:sender];
}

- (void)findPrevious:(id)sender {
    [self.findReplaceController findPrevious:sender];
}
```

## License

Copyright © 2024 Notepad++. All rights reserved.

This component is part of the Notepad++ macOS port and is governed by the same GPL License as the main project.

## See Also

- [MainWindowController](../AppKit/MainWindowController.h) - Main window integration
- [Document](../AppKit/Document.h) - Document model
- [Scintilla Documentation](https://www.scintilla.org/ScintillaDoc.html) - Text editor component
