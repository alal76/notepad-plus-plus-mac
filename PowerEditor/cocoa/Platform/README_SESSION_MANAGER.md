# SessionManager Integration Guide

## Overview

The `SessionManager` class provides session persistence for Notepad++ macOS, allowing the application to save and restore the user's workspace including open files, active document, cursor positions, and window state.

## Architecture

### Components

1. **SessionManager**: Singleton class that manages session persistence
2. **SessionData**: Data model containing session information
3. **Integration Points**: AppDelegate and DocumentController

### Session File Location

Session data is stored in JSON format at:
```
~/Library/Application Support/Notepad++/session.json
```

## Features

- ✅ Save and restore open files
- ✅ Remember active document
- ✅ Preserve file encoding and line ending settings
- ✅ Store cursor and scroll positions (extensible)
- ✅ Save window state (size, position, fullscreen)
- ✅ Automatic save on quit (configurable)
- ✅ Automatic restore on launch (opt-in)
- ✅ JSON-based serialization using NSJSONSerialization
- ✅ Thread-safe singleton pattern

## Integration with AppDelegate

### Step 1: Import SessionManager

Add the import to your `AppDelegate.mm`:

```objc
#import "Platform/SessionManager.h"
```

### Step 2: Add DocumentController Property

If not already present, ensure your AppDelegate has access to the DocumentController:

```objc
@property (strong, nonatomic) DocumentController *documentController;
```

### Step 3: Implement Auto-Save on Quit

Modify your `applicationWillTerminate:` method:

```objc
- (void)applicationWillTerminate:(NSNotification *)notification {
    // Save session if auto-save is enabled
    [SessionManager saveSessionOnQuit:self.documentController];
    
    // ... other cleanup code ...
}
```

### Step 4: Implement Auto-Restore on Launch

Modify your `applicationDidFinishLaunching:` method:

```objc
- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    // ... existing initialization code ...
    
    // Initialize document controller if not already done
    if (!self.documentController) {
        self.documentController = [[DocumentController alloc] init];
    }
    
    // Restore session if auto-restore is enabled and session exists
    [SessionManager restoreSessionOnLaunch:self.documentController];
    
    // If no session was restored, create a new empty document
    if (self.documentController.documents.count == 0) {
        [self.documentController createNewDocument];
    }
    
    // ... rest of launch code ...
}
```

## Manual Session Management

You can also manage sessions manually:

### Save Session

```objc
SessionManager *sessionManager = [SessionManager sharedManager];
NSError *error = nil;
BOOL success = [sessionManager saveSession:documentController error:&error];
if (!success) {
    NSLog(@"Failed to save session: %@", error.localizedDescription);
}
```

### Load Session

```objc
SessionManager *sessionManager = [SessionManager sharedManager];
NSError *error = nil;
BOOL success = [sessionManager loadSession:documentController error:&error];
if (!success) {
    NSLog(@"Failed to load session: %@", error.localizedDescription);
}
```

### Clear Session

```objc
SessionManager *sessionManager = [SessionManager sharedManager];
NSError *error = nil;
BOOL success = [sessionManager clearSession:&error];
if (!success) {
    NSLog(@"Failed to clear session: %@", error.localizedDescription);
}
```

### Check for Existing Session

```objc
SessionManager *sessionManager = [SessionManager sharedManager];
if ([sessionManager hasExistingSession]) {
    // Session file exists
}
```

## Configuration

### User Preferences

The SessionManager uses NSUserDefaults for configuration:

```objc
SessionManager *sessionManager = [SessionManager sharedManager];

// Enable/disable auto-save on quit (default: YES)
sessionManager.autoSaveOnQuit = YES;

// Enable/disable auto-restore on launch (default: NO)
sessionManager.autoRestoreOnLaunch = YES;
```

### Preference Keys

These keys are stored in NSUserDefaults:
- `SessionAutoSaveOnQuit` - Boolean for auto-save behavior
- `SessionAutoRestoreOnLaunch` - Boolean for auto-restore behavior

## Window State Management

### Save Window State

```objc
SessionManager *sessionManager = [SessionManager sharedManager];

NSDictionary *windowState = @{
    @"frame": NSStringFromRect(window.frame),
    @"isMaximized": @(window.isZoomed),
    @"isFullScreen": @((window.styleMask & NSWindowStyleMaskFullScreen) != 0)
};

[sessionManager saveWindowState:windowState];
```

### Restore Window State

```objc
SessionManager *sessionManager = [SessionManager sharedManager];
NSDictionary *windowState = [sessionManager loadWindowState];

if (windowState) {
    NSString *frameString = windowState[@"frame"];
    if (frameString) {
        NSRect frame = NSRectFromString(frameString);
        [window setFrame:frame display:YES];
    }
    
    BOOL isMaximized = [windowState[@"isMaximized"] boolValue];
    if (isMaximized) {
        [window zoom:nil];
    }
}
```

## Session Data Structure

The session JSON file contains:

```json
{
  "openFiles": [
    {
      "path": "/path/to/file1.txt",
      "encoding": 0,
      "lineEnding": 0,
      "language": "plaintext",
      "cursorPosition": 0,
      "scrollPosition": 0
    },
    {
      "path": "/path/to/file2.cpp",
      "encoding": 0,
      "lineEnding": 1,
      "language": "cpp",
      "cursorPosition": 125,
      "scrollPosition": 50
    }
  ],
  "activeFile": "/path/to/file2.cpp",
  "windowState": {
    "frame": "{{100, 100}, {800, 600}}",
    "isMaximized": false,
    "isFullScreen": false
  },
  "cursorPositions": {
    "/path/to/file1.txt": 0,
    "/path/to/file2.cpp": 125
  }
}
```

## Extending Cursor and Scroll Position Support

To fully support cursor and scroll positions, you'll need to integrate with your editor view:

### In Your Editor View Controller

```objc
// When saving session
- (void)saveEditorState:(Document *)document {
    // Get cursor position from your text view
    NSRange cursorRange = self.textView.selectedRange;
    NSInteger cursorPosition = cursorRange.location;
    
    // Get scroll position
    NSPoint scrollPosition = self.scrollView.contentView.bounds.origin;
    
    // Store these values (you may need to add properties to Document class)
    document.cursorPosition = cursorPosition;
    document.scrollPosition = scrollPosition.y;
}

// When restoring session
- (void)restoreEditorState:(Document *)document {
    // Restore cursor position
    if (document.cursorPosition >= 0) {
        NSRange range = NSMakeRange(document.cursorPosition, 0);
        [self.textView setSelectedRange:range];
    }
    
    // Restore scroll position
    if (document.scrollPosition >= 0) {
        NSPoint point = NSMakePoint(0, document.scrollPosition);
        [self.scrollView.contentView scrollToPoint:point];
        [self.scrollView reflectScrolledClipView:self.scrollView.contentView];
    }
}
```

## Menu Integration

You can add menu items for session management:

### In MainMenu.xib or Programmatically

```objc
// In AppDelegate or MenuController
- (IBAction)saveSessionMenuItem:(id)sender {
    SessionManager *sessionManager = [SessionManager sharedManager];
    NSError *error = nil;
    [sessionManager saveSession:self.documentController error:&error];
    
    if (error) {
        [self showErrorAlert:@"Failed to save session" 
                     message:error.localizedDescription];
    } else {
        [self showInfoAlert:@"Session saved successfully"];
    }
}

- (IBAction)restoreSessionMenuItem:(id)sender {
    SessionManager *sessionManager = [SessionManager sharedManager];
    NSError *error = nil;
    [sessionManager loadSession:self.documentController error:&error];
    
    if (error) {
        [self showErrorAlert:@"Failed to restore session" 
                     message:error.localizedDescription];
    }
}
```

## Error Handling

The SessionManager provides detailed error information:

```objc
NSError *error = nil;
BOOL success = [sessionManager saveSession:documentController error:&error];

if (!success && error) {
    switch (error.code) {
        case 100:
            NSLog(@"DocumentController is nil");
            break;
        case 101:
            NSLog(@"Cannot load - DocumentController is nil");
            break;
        case 102:
            NSLog(@"No session file found");
            break;
        default:
            NSLog(@"Error: %@", error.localizedDescription);
            break;
    }
}
```

## Best Practices

1. **Auto-Save**: Keep `autoSaveOnQuit` enabled by default to prevent data loss
2. **Auto-Restore**: Make `autoRestoreOnLaunch` opt-in to respect user preference
3. **File Validation**: The session loader skips files that no longer exist
4. **Error Handling**: Always check for errors when loading/saving sessions
5. **User Feedback**: Provide UI feedback when sessions are saved/restored manually
6. **Testing**: Test with missing files, corrupted JSON, and permission issues

## Testing Checklist

- [ ] Session saves correctly on application quit
- [ ] Session restores correctly on application launch
- [ ] Active document is restored correctly
- [ ] Files that no longer exist are skipped gracefully
- [ ] Window state is preserved and restored
- [ ] User preferences are respected
- [ ] Manual save/load operations work
- [ ] Clear session removes the file
- [ ] Corrupted JSON files are handled gracefully
- [ ] Multiple documents are restored in correct order

## Troubleshooting

### Session Not Saving

1. Check if `autoSaveOnQuit` is enabled
2. Verify DocumentController is not nil
3. Check file permissions in Application Support directory
4. Look for errors in Console.app

### Session Not Restoring

1. Check if `autoRestoreOnLaunch` is enabled
2. Verify session file exists at expected path
3. Check JSON format is valid
4. Ensure file paths in session are still valid

### Session File Location

To view the session file:

```bash
cat ~/Library/Application\ Support/Notepad++/session.json
```

To delete the session file:

```bash
rm ~/Library/Application\ Support/Notepad++/session.json
```

## Future Enhancements

Potential improvements for future versions:

1. Support for multiple named sessions
2. Export/import session files
3. Session templates
4. Workspace-specific sessions
5. Cloud synchronization of sessions
6. Session history with timestamps
7. Selective file restoration (UI for choosing which files to restore)
8. Better handling of unsaved document content
9. Integration with Time Machine for session backups
10. Session comparison and merging

## License

Copyright © 2024 Notepad++. All rights reserved.
