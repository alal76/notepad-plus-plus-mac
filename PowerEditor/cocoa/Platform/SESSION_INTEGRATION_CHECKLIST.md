# SessionManager Integration Checklist

Use this checklist when integrating SessionManager into your AppDelegate.

## Pre-Integration

- [ ] Ensure DocumentController is available in your AppDelegate
- [ ] Verify Document class has fileURL, encoding, lineEnding, and languageType properties
- [ ] Review README_SESSION_MANAGER.md for detailed integration instructions

## AppDelegate.h Changes

- [ ] Add import: `#import "Platform/SessionManager.h"`
- [ ] Verify DocumentController property exists

## AppDelegate.mm Implementation

### applicationDidFinishLaunching:

- [ ] Initialize DocumentController if not already done
- [ ] Call `[SessionManager restoreSessionOnLaunch:self.documentController]`
- [ ] Create new document if no session was restored and no documents are open
- [ ] Optionally restore window state with `[sessionManager loadWindowState]`

Example:
```objc
- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    // ... existing code ...
    
    if (!self.documentController) {
        self.documentController = [[DocumentController alloc] init];
    }
    
    [SessionManager restoreSessionOnLaunch:self.documentController];
    
    if (self.documentController.documents.count == 0) {
        [self.documentController createNewDocument];
    }
    
    // ... rest of code ...
}
```

### applicationWillTerminate:

- [ ] Call `[SessionManager saveSessionOnQuit:self.documentController]`
- [ ] Optionally save window state before terminating

Example:
```objc
- (void)applicationWillTerminate:(NSNotification *)notification {
    // Save window state if needed
    SessionManager *sessionManager = [SessionManager sharedManager];
    if (self.mainWindowController && self.mainWindowController.window) {
        NSDictionary *windowState = @{
            @"frame": NSStringFromRect(self.mainWindowController.window.frame),
            @"isMaximized": @(self.mainWindowController.window.isZoomed)
        };
        [sessionManager saveWindowState:windowState];
    }
    
    // Save session
    [SessionManager saveSessionOnQuit:self.documentController];
    
    // ... other cleanup ...
}
```

### applicationShouldTerminate: (Optional)

- [ ] Check for unsaved changes
- [ ] Prompt user about session saving if needed
- [ ] Optionally allow user to cancel quit

Example:
```objc
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    if ([self.documentController hasUnsavedChanges]) {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"Do you want to save your changes?";
        alert.informativeText = @"Your changes will be automatically saved in the session.";
        [alert addButtonWithTitle:@"Save Session"];
        [alert addButtonWithTitle:@"Don't Save"];
        [alert addButtonWithTitle:@"Cancel"];
        
        NSModalResponse response = [alert runModal];
        
        if (response == NSAlertThirdButtonReturn) {
            return NSTerminateCancel;
        } else if (response == NSAlertSecondButtonReturn) {
            [SessionManager sharedManager].autoSaveOnQuit = NO;
        }
    }
    
    return NSTerminateNow;
}
```

## Optional: Add Menu Items

### File Menu or Session Menu

- [ ] Add "Save Session" menu item
- [ ] Add "Restore Session" menu item  
- [ ] Add "Clear Session" menu item
- [ ] Connect menu items to appropriate IBAction methods

Example actions (see AppDelegate+SessionManager.mm for complete implementations):
```objc
- (IBAction)saveSession:(id)sender;
- (IBAction)restoreSession:(id)sender;
- (IBAction)clearSession:(id)sender;
```

## Optional: Add Preferences

### Preferences Window

- [ ] Add checkbox for "Auto-save session on quit" (default: ON)
- [ ] Add checkbox for "Auto-restore session on launch" (default: OFF)
- [ ] Connect to SessionManager properties

Example:
```objc
SessionManager *sessionManager = [SessionManager sharedManager];
sessionManager.autoSaveOnQuit = self.autoSaveCheckbox.state == NSControlStateValueOn;
sessionManager.autoRestoreOnLaunch = self.autoRestoreCheckbox.state == NSControlStateValueOn;
```

## Testing

- [ ] Test session saves on quit
- [ ] Test session restores on launch
- [ ] Test with multiple open files
- [ ] Test active file is restored correctly
- [ ] Test with files that no longer exist (should skip gracefully)
- [ ] Test window state restoration
- [ ] Test clearing session
- [ ] Test with empty session (no files open)
- [ ] Test with corrupted session.json (should handle gracefully)
- [ ] Test manual save/restore from menu items

## Verification

- [ ] Check session file exists at: `~/Library/Application Support/Notepad++/session.json`
- [ ] Verify session.json format is valid JSON
- [ ] Verify all open files are in session.json
- [ ] Verify active file is recorded
- [ ] Check Console.app for any SessionManager log messages

## Post-Integration

- [ ] Document session feature for users
- [ ] Update application help/documentation
- [ ] Consider adding to release notes
- [ ] Add to known issues if any edge cases discovered

## Known Limitations

Current implementation has placeholders for:
- Cursor position tracking (needs editor view integration)
- Scroll position tracking (needs editor view integration)

To fully implement these features, extend the Document class and integrate with your text editor view.

## Support

For detailed examples and troubleshooting:
- See README_SESSION_MANAGER.md
- See examples/AppDelegate+SessionManager.mm
- Check PowerEditor/cocoa/Platform/SessionManager.mm for implementation details
