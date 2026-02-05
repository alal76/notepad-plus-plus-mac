//
//  PreferencesWindowController.h
//  Notepad++ macOS
//
//  Copyright © 2024 Notepad++. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/**
 * Window controller for the Preferences window.
 * Provides a modern tabbed interface for managing application preferences
 * across different categories: General, Editor, Appearance, Files, and Advanced.
 */
@interface PreferencesWindowController : NSWindowController <NSWindowDelegate, NSTabViewDelegate>

// Singleton instance
+ (instancetype)sharedController;

// Show the preferences window
- (void)showWindow:(id)sender;

// Tab view and panels
@property (strong, nonatomic) NSTabView *tabView;
@property (strong, nonatomic) NSView *generalPanel;
@property (strong, nonatomic) NSView *editorPanel;
@property (strong, nonatomic) NSView *appearancePanel;
@property (strong, nonatomic) NSView *filesPanel;
@property (strong, nonatomic) NSView *advancedPanel;

// General preferences
@property (weak, nonatomic) NSPopUpButton *fontPopup;
@property (weak, nonatomic) NSPopUpButton *fontSizePopup;
@property (weak, nonatomic) NSPopUpButton *themePopup;

// Editor preferences
@property (weak, nonatomic) NSTextField *tabSizeField;
@property (weak, nonatomic) NSStepper *tabSizeStepper;
@property (weak, nonatomic) NSButton *useSpacesCheckbox;
@property (weak, nonatomic) NSButton *showLineNumbersCheckbox;
@property (weak, nonatomic) NSButton *wordWrapCheckbox;

// Appearance preferences
@property (weak, nonatomic) NSButton *showToolbarCheckbox;
@property (weak, nonatomic) NSButton *showStatusBarCheckbox;

// Files preferences
@property (weak, nonatomic) NSPopUpButton *encodingPopup;
@property (weak, nonatomic) NSPopUpButton *lineEndingPopup;
@property (weak, nonatomic) NSTextField *recentFilesLimitField;
@property (weak, nonatomic) NSStepper *recentFilesLimitStepper;

// Advanced preferences
@property (weak, nonatomic) NSButton *autoSaveCheckbox;
@property (weak, nonatomic) NSButton *backupCheckbox;
@property (weak, nonatomic) NSButton *sessionRestoreCheckbox;

// Actions
- (IBAction)restoreDefaults:(id)sender;
- (IBAction)applyChanges:(id)sender;

@end
