//
//  PreferencesWindowController.mm
//  Notepad++ macOS
//
//  Copyright © 2024 Notepad++. All rights reserved.
//

#import "PreferencesWindowController.h"
#import "../Platform/ConfigManager.h"

static const CGFloat kWindowWidth = 600.0;
static const CGFloat kWindowHeight = 500.0;
static const CGFloat kPanelPadding = 20.0;
static const CGFloat kControlHeight = 24.0;
static const CGFloat kControlSpacing = 12.0;
static const CGFloat kLabelWidth = 180.0;
static const CGFloat kControlWidth = 200.0;

// Preference keys for additional settings
static NSString * const kThemeKey = @"Theme";
static NSString * const kShowToolbarKey = @"ShowToolbar";
static NSString * const kShowStatusBarKey = @"ShowStatusBar";
static NSString * const kDefaultEncodingKey = @"DefaultEncoding";
static NSString * const kLineEndingKey = @"LineEnding";
static NSString * const kRecentFilesLimitKey = @"RecentFilesLimit";
static NSString * const kAutoSaveKey = @"AutoSave";
static NSString * const kBackupKey = @"Backup";
static NSString * const kSessionRestoreKey = @"SessionRestore";

@interface PreferencesWindowController () <NSTextFieldDelegate>

@property (strong, nonatomic) ConfigManager *configManager;

@end

@implementation PreferencesWindowController

+ (instancetype)sharedController {
    static PreferencesWindowController *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[PreferencesWindowController alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    NSRect windowFrame = NSMakeRect(0, 0, kWindowWidth, kWindowHeight);
    NSWindow *window = [[NSWindow alloc] initWithContentRect:windowFrame
                                                   styleMask:(NSWindowStyleMaskTitled |
                                                             NSWindowStyleMaskClosable)
                                                     backing:NSBackingStoreBuffered
                                                       defer:NO];
    
    self = [super initWithWindow:window];
    if (self) {
        window.title = @"Preferences";
        window.delegate = self;
        [window center];
        
        _configManager = [ConfigManager sharedManager];
        
        [self setupUI];
        [self loadPreferences];
    }
    return self;
}

- (void)setupUI {
    NSWindow *window = self.window;
    NSView *contentView = window.contentView;
    
    // Create tab view
    _tabView = [[NSTabView alloc] initWithFrame:contentView.bounds];
    _tabView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    _tabView.delegate = self;
    _tabView.tabViewType = NSTopTabsBezelBorder;
    [contentView addSubview:_tabView];
    
    // Create tab view items
    [self setupGeneralPanel];
    [self setupEditorPanel];
    [self setupAppearancePanel];
    [self setupFilesPanel];
    [self setupAdvancedPanel];
}

#pragma mark - Panel Setup

- (void)setupGeneralPanel {
    _generalPanel = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, kWindowWidth - 40, kWindowHeight - 80)];
    
    CGFloat yPos = _generalPanel.bounds.size.height - kPanelPadding - kControlHeight;
    
    // Font
    [self addLabel:@"Font:" atY:yPos toView:_generalPanel];
    NSPopUpButton *fontPopup = [self createPopUpButtonAtY:yPos];
    [self populateFontPopup:fontPopup];
    [_generalPanel addSubview:fontPopup];
    _fontPopup = fontPopup;
    yPos -= (kControlHeight + kControlSpacing);
    
    // Font size
    [self addLabel:@"Font size:" atY:yPos toView:_generalPanel];
    NSPopUpButton *fontSizePopup = [self createPopUpButtonAtY:yPos];
    [fontSizePopup addItemsWithTitles:@[@"9", @"10", @"11", @"12", @"13", @"14", @"16", @"18", @"20", @"24"]];
    [_generalPanel addSubview:fontSizePopup];
    _fontSizePopup = fontSizePopup;
    yPos -= (kControlHeight + kControlSpacing);
    
    // Theme
    [self addLabel:@"Theme:" atY:yPos toView:_generalPanel];
    NSPopUpButton *themePopup = [self createPopUpButtonAtY:yPos];
    [themePopup addItemsWithTitles:@[@"Light", @"Dark", @"Auto"]];
    [_generalPanel addSubview:themePopup];
    _themePopup = themePopup;
    
    NSTabViewItem *item = [[NSTabViewItem alloc] initWithIdentifier:@"general"];
    item.label = @"General";
    item.view = _generalPanel;
    [_tabView addTabViewItem:item];
}

- (void)setupEditorPanel {
    _editorPanel = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, kWindowWidth - 40, kWindowHeight - 80)];
    
    CGFloat yPos = _editorPanel.bounds.size.height - kPanelPadding - kControlHeight;
    
    // Tab size
    [self addLabel:@"Tab size:" atY:yPos toView:_editorPanel];
    NSTextField *tabSizeField = [[NSTextField alloc] initWithFrame:NSMakeRect(kLabelWidth + kPanelPadding, yPos, 60, kControlHeight)];
    tabSizeField.formatter = [[NSNumberFormatter alloc] init];
    tabSizeField.delegate = self;
    [_editorPanel addSubview:tabSizeField];
    _tabSizeField = tabSizeField;
    
    NSStepper *tabSizeStepper = [[NSStepper alloc] initWithFrame:NSMakeRect(kLabelWidth + kPanelPadding + 70, yPos, 20, kControlHeight)];
    tabSizeStepper.minValue = 1;
    tabSizeStepper.maxValue = 16;
    tabSizeStepper.increment = 1;
    [tabSizeStepper setTarget:self];
    [tabSizeStepper setAction:@selector(tabSizeStepperChanged:)];
    [_editorPanel addSubview:tabSizeStepper];
    _tabSizeStepper = tabSizeStepper;
    yPos -= (kControlHeight + kControlSpacing);
    
    // Use spaces instead of tabs
    NSButton *useSpacesCheckbox = [self createCheckboxWithTitle:@"Use spaces instead of tabs" atY:yPos];
    [_editorPanel addSubview:useSpacesCheckbox];
    _useSpacesCheckbox = useSpacesCheckbox;
    yPos -= (kControlHeight + kControlSpacing);
    
    // Show line numbers
    NSButton *showLineNumbersCheckbox = [self createCheckboxWithTitle:@"Show line numbers" atY:yPos];
    [_editorPanel addSubview:showLineNumbersCheckbox];
    _showLineNumbersCheckbox = showLineNumbersCheckbox;
    yPos -= (kControlHeight + kControlSpacing);
    
    // Word wrap
    NSButton *wordWrapCheckbox = [self createCheckboxWithTitle:@"Enable word wrap" atY:yPos];
    [_editorPanel addSubview:wordWrapCheckbox];
    _wordWrapCheckbox = wordWrapCheckbox;
    
    NSTabViewItem *item = [[NSTabViewItem alloc] initWithIdentifier:@"editor"];
    item.label = @"Editor";
    item.view = _editorPanel;
    [_tabView addTabViewItem:item];
}

- (void)setupAppearancePanel {
    _appearancePanel = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, kWindowWidth - 40, kWindowHeight - 80)];
    
    CGFloat yPos = _appearancePanel.bounds.size.height - kPanelPadding - kControlHeight;
    
    // Show toolbar
    NSButton *showToolbarCheckbox = [self createCheckboxWithTitle:@"Show toolbar" atY:yPos];
    [_appearancePanel addSubview:showToolbarCheckbox];
    _showToolbarCheckbox = showToolbarCheckbox;
    yPos -= (kControlHeight + kControlSpacing);
    
    // Show status bar
    NSButton *showStatusBarCheckbox = [self createCheckboxWithTitle:@"Show status bar" atY:yPos];
    [_appearancePanel addSubview:showStatusBarCheckbox];
    _showStatusBarCheckbox = showStatusBarCheckbox;
    
    NSTabViewItem *item = [[NSTabViewItem alloc] initWithIdentifier:@"appearance"];
    item.label = @"Appearance";
    item.view = _appearancePanel;
    [_tabView addTabViewItem:item];
}

- (void)setupFilesPanel {
    _filesPanel = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, kWindowWidth - 40, kWindowHeight - 80)];
    
    CGFloat yPos = _filesPanel.bounds.size.height - kPanelPadding - kControlHeight;
    
    // Default encoding
    [self addLabel:@"Default encoding:" atY:yPos toView:_filesPanel];
    NSPopUpButton *encodingPopup = [self createPopUpButtonAtY:yPos];
    [encodingPopup addItemsWithTitles:@[@"UTF-8", @"UTF-16", @"ISO-8859-1", @"Windows-1252", @"Mac Roman"]];
    [_filesPanel addSubview:encodingPopup];
    _encodingPopup = encodingPopup;
    yPos -= (kControlHeight + kControlSpacing);
    
    // Line ending
    [self addLabel:@"Line ending:" atY:yPos toView:_filesPanel];
    NSPopUpButton *lineEndingPopup = [self createPopUpButtonAtY:yPos];
    [lineEndingPopup addItemsWithTitles:@[@"Unix (LF)", @"Windows (CRLF)", @"Mac (CR)"]];
    [_filesPanel addSubview:lineEndingPopup];
    _lineEndingPopup = lineEndingPopup;
    yPos -= (kControlHeight + kControlSpacing);
    
    // Recent files limit
    [self addLabel:@"Recent files limit:" atY:yPos toView:_filesPanel];
    NSTextField *recentFilesLimitField = [[NSTextField alloc] initWithFrame:NSMakeRect(kLabelWidth + kPanelPadding, yPos, 60, kControlHeight)];
    recentFilesLimitField.formatter = [[NSNumberFormatter alloc] init];
    recentFilesLimitField.delegate = self;
    [_filesPanel addSubview:recentFilesLimitField];
    _recentFilesLimitField = recentFilesLimitField;
    
    NSStepper *recentFilesLimitStepper = [[NSStepper alloc] initWithFrame:NSMakeRect(kLabelWidth + kPanelPadding + 70, yPos, 20, kControlHeight)];
    recentFilesLimitStepper.minValue = 5;
    recentFilesLimitStepper.maxValue = 50;
    recentFilesLimitStepper.increment = 1;
    [recentFilesLimitStepper setTarget:self];
    [recentFilesLimitStepper setAction:@selector(recentFilesLimitStepperChanged:)];
    [_filesPanel addSubview:recentFilesLimitStepper];
    _recentFilesLimitStepper = recentFilesLimitStepper;
    
    NSTabViewItem *item = [[NSTabViewItem alloc] initWithIdentifier:@"files"];
    item.label = @"Files";
    item.view = _filesPanel;
    [_tabView addTabViewItem:item];
}

- (void)setupAdvancedPanel {
    _advancedPanel = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, kWindowWidth - 40, kWindowHeight - 80)];
    
    CGFloat yPos = _advancedPanel.bounds.size.height - kPanelPadding - kControlHeight;
    
    // Auto-save
    NSButton *autoSaveCheckbox = [self createCheckboxWithTitle:@"Enable auto-save" atY:yPos];
    [_advancedPanel addSubview:autoSaveCheckbox];
    _autoSaveCheckbox = autoSaveCheckbox;
    yPos -= (kControlHeight + kControlSpacing);
    
    // Backup
    NSButton *backupCheckbox = [self createCheckboxWithTitle:@"Create backup files" atY:yPos];
    [_advancedPanel addSubview:backupCheckbox];
    _backupCheckbox = backupCheckbox;
    yPos -= (kControlHeight + kControlSpacing);
    
    // Session restore
    NSButton *sessionRestoreCheckbox = [self createCheckboxWithTitle:@"Restore previous session on startup" atY:yPos];
    [_advancedPanel addSubview:sessionRestoreCheckbox];
    _sessionRestoreCheckbox = sessionRestoreCheckbox;
    yPos -= (kControlHeight + kControlSpacing * 2);
    
    // Restore defaults button
    NSButton *restoreDefaultsButton = [[NSButton alloc] initWithFrame:NSMakeRect(kPanelPadding, yPos, 150, kControlHeight)];
    restoreDefaultsButton.title = @"Restore Defaults";
    restoreDefaultsButton.bezelStyle = NSBezelStyleRounded;
    [restoreDefaultsButton setTarget:self];
    [restoreDefaultsButton setAction:@selector(restoreDefaults:)];
    [_advancedPanel addSubview:restoreDefaultsButton];
    
    NSTabViewItem *item = [[NSTabViewItem alloc] initWithIdentifier:@"advanced"];
    item.label = @"Advanced";
    item.view = _advancedPanel;
    [_tabView addTabViewItem:item];
}

#pragma mark - Helper Methods

- (void)addLabel:(NSString *)text atY:(CGFloat)yPos toView:(NSView *)view {
    NSTextField *label = [[NSTextField alloc] initWithFrame:NSMakeRect(kPanelPadding, yPos, kLabelWidth, kControlHeight)];
    label.stringValue = text;
    label.editable = NO;
    label.bordered = NO;
    label.backgroundColor = [NSColor clearColor];
    label.alignment = NSTextAlignmentRight;
    [view addSubview:label];
}

- (NSPopUpButton *)createPopUpButtonAtY:(CGFloat)yPos {
    NSPopUpButton *popup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(kLabelWidth + kPanelPadding, yPos, kControlWidth, kControlHeight)];
    popup.pullsDown = NO;
    return popup;
}

- (NSButton *)createCheckboxWithTitle:(NSString *)title atY:(CGFloat)yPos {
    NSButton *checkbox = [[NSButton alloc] initWithFrame:NSMakeRect(kPanelPadding, yPos, kLabelWidth + kControlWidth, kControlHeight)];
    checkbox.title = title;
    [checkbox setButtonType:NSButtonTypeSwitch];
    return checkbox;
}

- (void)populateFontPopup:(NSPopUpButton *)popup {
    NSArray *fonts = @[@"Menlo", @"Monaco", @"Courier New", @"Courier", @"SF Mono", @"Andale Mono", @"Source Code Pro"];
    [popup addItemsWithTitles:fonts];
}

#pragma mark - Load/Save Preferences

- (void)loadPreferences {
    // General
    NSString *fontName = [_configManager fontName];
    [_fontPopup selectItemWithTitle:fontName];
    if (_fontPopup.indexOfSelectedItem == -1) {
        [_fontPopup selectItemAtIndex:0];
    }
    
    CGFloat fontSize = [_configManager fontSize];
    [_fontSizePopup selectItemWithTitle:[NSString stringWithFormat:@"%.0f", fontSize]];
    if (_fontSizePopup.indexOfSelectedItem == -1) {
        [_fontSizePopup selectItemAtIndex:4]; // Default to 13
    }
    
    NSString *theme = [_configManager preferenceForKey:kThemeKey];
    if (theme) {
        [_themePopup selectItemWithTitle:theme];
    } else {
        [_themePopup selectItemAtIndex:0]; // Default to Light
    }
    
    // Editor
    NSInteger tabSize = [_configManager tabSize];
    _tabSizeField.integerValue = tabSize;
    _tabSizeStepper.integerValue = tabSize;
    
    _useSpacesCheckbox.state = [_configManager useSpacesInsteadOfTabs] ? NSControlStateValueOn : NSControlStateValueOff;
    _showLineNumbersCheckbox.state = [_configManager showLineNumbers] ? NSControlStateValueOn : NSControlStateValueOff;
    _wordWrapCheckbox.state = [_configManager wordWrap] ? NSControlStateValueOn : NSControlStateValueOff;
    
    // Appearance
    BOOL showToolbar = [[_configManager preferenceForKey:kShowToolbarKey] boolValue];
    _showToolbarCheckbox.state = showToolbar ? NSControlStateValueOn : NSControlStateValueOff;
    
    BOOL showStatusBar = [[_configManager preferenceForKey:kShowStatusBarKey] boolValue];
    _showStatusBarCheckbox.state = showStatusBar ? NSControlStateValueOn : NSControlStateValueOff;
    
    // Files
    NSString *encoding = [_configManager preferenceForKey:kDefaultEncodingKey];
    if (encoding) {
        [_encodingPopup selectItemWithTitle:encoding];
    } else {
        [_encodingPopup selectItemAtIndex:0]; // Default to UTF-8
    }
    
    NSString *lineEnding = [_configManager preferenceForKey:kLineEndingKey];
    if (lineEnding) {
        [_lineEndingPopup selectItemWithTitle:lineEnding];
    } else {
        [_lineEndingPopup selectItemAtIndex:0]; // Default to Unix (LF)
    }
    
    NSInteger recentFilesLimit = [[_configManager preferenceForKey:kRecentFilesLimitKey] integerValue];
    if (recentFilesLimit == 0) {
        recentFilesLimit = 10; // Default
    }
    _recentFilesLimitField.integerValue = recentFilesLimit;
    _recentFilesLimitStepper.integerValue = recentFilesLimit;
    
    // Advanced
    BOOL autoSave = [[_configManager preferenceForKey:kAutoSaveKey] boolValue];
    _autoSaveCheckbox.state = autoSave ? NSControlStateValueOn : NSControlStateValueOff;
    
    BOOL backup = [[_configManager preferenceForKey:kBackupKey] boolValue];
    _backupCheckbox.state = backup ? NSControlStateValueOn : NSControlStateValueOff;
    
    BOOL sessionRestore = [[_configManager preferenceForKey:kSessionRestoreKey] boolValue];
    _sessionRestoreCheckbox.state = sessionRestore ? NSControlStateValueOn : NSControlStateValueOff;
}

- (void)savePreferences {
    // General
    NSString *fontName = _fontPopup.titleOfSelectedItem;
    if (fontName) {
        [_configManager setFontName:fontName];
    }
    
    NSString *fontSizeStr = _fontSizePopup.titleOfSelectedItem;
    if (fontSizeStr) {
        [_configManager setFontSize:[fontSizeStr doubleValue]];
    }
    
    NSString *theme = _themePopup.titleOfSelectedItem;
    if (theme) {
        [_configManager setPreference:theme forKey:kThemeKey];
    }
    
    // Editor
    [_configManager setTabSize:_tabSizeField.integerValue];
    [_configManager setUseSpacesInsteadOfTabs:(_useSpacesCheckbox.state == NSControlStateValueOn)];
    [_configManager setShowLineNumbers:(_showLineNumbersCheckbox.state == NSControlStateValueOn)];
    [_configManager setWordWrap:(_wordWrapCheckbox.state == NSControlStateValueOn)];
    
    // Appearance
    [_configManager setPreference:@(_showToolbarCheckbox.state == NSControlStateValueOn) forKey:kShowToolbarKey];
    [_configManager setPreference:@(_showStatusBarCheckbox.state == NSControlStateValueOn) forKey:kShowStatusBarKey];
    
    // Files
    NSString *encoding = _encodingPopup.titleOfSelectedItem;
    if (encoding) {
        [_configManager setPreference:encoding forKey:kDefaultEncodingKey];
    }
    
    NSString *lineEnding = _lineEndingPopup.titleOfSelectedItem;
    if (lineEnding) {
        [_configManager setPreference:lineEnding forKey:kLineEndingKey];
    }
    
    [_configManager setPreference:@(_recentFilesLimitField.integerValue) forKey:kRecentFilesLimitKey];
    
    // Advanced
    [_configManager setPreference:@(_autoSaveCheckbox.state == NSControlStateValueOn) forKey:kAutoSaveKey];
    [_configManager setPreference:@(_backupCheckbox.state == NSControlStateValueOn) forKey:kBackupKey];
    [_configManager setPreference:@(_sessionRestoreCheckbox.state == NSControlStateValueOn) forKey:kSessionRestoreKey];
    
    [_configManager synchronize];
}

#pragma mark - Actions

- (IBAction)restoreDefaults:(id)sender {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Restore Default Preferences";
    alert.informativeText = @"This will reset all preferences to their default values. Are you sure?";
    [alert addButtonWithTitle:@"Restore"];
    [alert addButtonWithTitle:@"Cancel"];
    alert.alertStyle = NSAlertStyleWarning;
    
    [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSAlertFirstButtonReturn) {
            [self restoreDefaultPreferences];
        }
    }];
}

- (void)restoreDefaultPreferences {
    // General
    [_configManager setFontName:@"Menlo"];
    [_configManager setFontSize:13.0];
    [_configManager setPreference:@"Light" forKey:kThemeKey];
    
    // Editor
    [_configManager setTabSize:4];
    [_configManager setUseSpacesInsteadOfTabs:YES];
    [_configManager setShowLineNumbers:YES];
    [_configManager setWordWrap:NO];
    
    // Appearance
    [_configManager setPreference:@YES forKey:kShowToolbarKey];
    [_configManager setPreference:@YES forKey:kShowStatusBarKey];
    
    // Files
    [_configManager setPreference:@"UTF-8" forKey:kDefaultEncodingKey];
    [_configManager setPreference:@"Unix (LF)" forKey:kLineEndingKey];
    [_configManager setPreference:@10 forKey:kRecentFilesLimitKey];
    
    // Advanced
    [_configManager setPreference:@NO forKey:kAutoSaveKey];
    [_configManager setPreference:@NO forKey:kBackupKey];
    [_configManager setPreference:@YES forKey:kSessionRestoreKey];
    
    [_configManager synchronize];
    [self loadPreferences];
}

- (IBAction)applyChanges:(id)sender {
    [self savePreferences];
}

- (void)tabSizeStepperChanged:(id)sender {
    _tabSizeField.integerValue = _tabSizeStepper.integerValue;
}

- (void)recentFilesLimitStepperChanged:(id)sender {
    _recentFilesLimitField.integerValue = _recentFilesLimitStepper.integerValue;
}

#pragma mark - Window Delegate

- (void)windowWillClose:(NSNotification *)notification {
    [self savePreferences];
}

- (void)showWindow:(id)sender {
    [self loadPreferences];
    [super showWindow:sender];
}

#pragma mark - Tab View Delegate

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem {
    // Save preferences when switching tabs
    [self savePreferences];
}

#pragma mark - Text Field Delegate

- (void)controlTextDidChange:(NSNotification *)notification {
    NSTextField *textField = notification.object;
    
    if (textField == _tabSizeField) {
        NSInteger value = textField.integerValue;
        if (value >= _tabSizeStepper.minValue && value <= _tabSizeStepper.maxValue) {
            _tabSizeStepper.integerValue = value;
        }
    } else if (textField == _recentFilesLimitField) {
        NSInteger value = textField.integerValue;
        if (value >= _recentFilesLimitStepper.minValue && value <= _recentFilesLimitStepper.maxValue) {
            _recentFilesLimitStepper.integerValue = value;
        }
    }
}

@end
