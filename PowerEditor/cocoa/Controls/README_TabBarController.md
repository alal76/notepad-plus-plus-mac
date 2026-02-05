# TabBarController - Document Tab Management for Notepad++ macOS

## Overview

`TabBarController` is a custom NSView subclass that provides native macOS-style tab management for document windows in Notepad++. It features a polished, native appearance with full support for light and dark modes, drag-to-reorder functionality, and comprehensive keyboard navigation.

## Features

### Core Functionality
- **Tab Management**: Add, remove, select, and reorder tabs programmatically
- **Visual States**: Active/inactive, hover, modified indicator (blue dot)
- **Close Buttons**: Per-tab close buttons with hover effects
- **Drag-to-Reorder**: Intuitive drag-and-drop tab reordering
- **Overflow Handling**: Automatic scroll buttons when tabs exceed available width
- **Context Menus**: Right-click menu with close operations

### User Interactions
- **Mouse Support**: Click to select, drag to reorder, hover effects
- **Keyboard Navigation**: Arrow keys for tab selection, Delete to close
- **Scroll Support**: Mouse wheel scrolling through tabs
- **Context Menu**: Close tab, close others, close left/right tabs

### Appearance
- **Native macOS Styling**: Matches system appearance guidelines
- **Light/Dark Mode**: Automatic color adaptation
- **Customizable**: Colors, fonts, spacing, and dimensions

## Architecture

### Class Structure

```objc
TabItem                    // Model class for individual tabs
TabBarController          // Main view controller
TabBarControllerDelegate  // Protocol for event handling
```

### TabItem

Represents a single tab with properties:
- `title`: Display text
- `tooltip`: Optional tooltip text
- `representedObject`: Associated data (e.g., document reference)
- `isModified`: Shows modified indicator
- `isSelected`: Current selection state
- `frame`: Layout rectangle

### TabBarController

Main controller class extending NSView with:
- Tab array management
- Custom Core Graphics rendering
- Mouse and keyboard event handling
- Delegate protocol for application integration

## Usage

### Basic Setup

```objc
#import "TabBarController.h"

// Create tab bar
TabBarController *tabBar = [[TabBarController alloc] initWithFrame:NSMakeRect(0, 0, 800, 28)];
tabBar.delegate = self;
[self.window.contentView addSubview:tabBar];

// Add tabs
TabItem *tab1 = [[TabItem alloc] initWithTitle:@"Document1.txt"];
[tabBar addTab:tab1];

TabItem *tab2 = [[TabItem alloc] initWithTitle:@"README.md"];
tab2.isModified = YES;
[tabBar addTab:tab2];

// Select a tab
[tabBar selectTabAtIndex:0];
```

### Implementing the Delegate

```objc
@interface MyWindowController : NSWindowController <TabBarControllerDelegate>
@end

@implementation MyWindowController

- (void)tabBarController:(TabBarController *)controller 
           didSelectTab:(TabItem *)tabItem 
                atIndex:(NSInteger)index {
    // Load document for selected tab
    [self loadDocument:tabItem.representedObject];
}

- (BOOL)tabBarController:(TabBarController *)controller 
          shouldCloseTab:(TabItem *)tabItem 
                 atIndex:(NSInteger)index {
    // Check if document has unsaved changes
    if (tabItem.isModified) {
        return [self confirmCloseModifiedDocument];
    }
    return YES;
}

- (void)tabBarController:(TabBarController *)controller 
            didCloseTab:(TabItem *)tabItem 
                atIndex:(NSInteger)index {
    // Clean up document resources
    [self closeDocument:tabItem.representedObject];
}

- (void)tabBarController:(TabBarController *)controller 
      didMoveTabFromIndex:(NSInteger)fromIndex 
                  toIndex:(NSInteger)toIndex {
    // Update internal document order
    [self.documents exchangeObjectAtIndex:fromIndex withObjectAtIndex:toIndex];
}

@end
```

### Tab Management

```objc
// Add tab
TabItem *newTab = [[TabItem alloc] initWithTitle:@"New Document"];
newTab.representedObject = document; // Associate with document
[tabBar addTab:newTab];

// Insert at specific position
[tabBar insertTab:newTab atIndex:2];

// Remove tab
[tabBar removeTabAtIndex:0];
[tabBar removeTab:newTab];

// Select tab
[tabBar selectTabAtIndex:3];
[tabBar selectTab:newTab];

// Move tab
[tabBar moveTabFromIndex:0 toIndex:5];

// Query tabs
TabItem *tab = [tabBar tabAtIndex:2];
NSInteger index = [tabBar indexOfTab:newTab];
NSArray<TabItem *> *allTabs = tabBar.tabs;
```

### Styling Customization

```objc
// Customize appearance
tabBar.backgroundColor = [NSColor colorWithWhite:0.9 alpha:1.0];
tabBar.selectedTabColor = [NSColor whiteColor];
tabBar.textColor = [NSColor darkGrayColor];
tabBar.tabFont = [NSFont systemFontOfSize:13.0];

// Adjust dimensions
tabBar.tabHeight = 30.0;
tabBar.tabMinWidth = 80.0;
tabBar.tabMaxWidth = 250.0;
tabBar.tabSpacing = 2.0;
tabBar.closeButtonSize = 16.0;
```

## Delegate Protocol

### Required Methods
None - all delegate methods are optional

### Optional Methods

#### Selection Events
```objc
- (void)tabBarController:(TabBarController *)controller 
           didSelectTab:(TabItem *)tabItem 
                atIndex:(NSInteger)index;
```
Called when user selects a tab.

#### Close Events
```objc
- (BOOL)tabBarController:(TabBarController *)controller 
          shouldCloseTab:(TabItem *)tabItem 
                 atIndex:(NSInteger)index;
```
Called before closing a tab. Return NO to prevent closure.

```objc
- (void)tabBarController:(TabBarController *)controller 
            didCloseTab:(TabItem *)tabItem 
                atIndex:(NSInteger)index;
```
Called after a tab is closed.

```objc
- (void)tabBarController:(TabBarController *)controller 
 closeButtonClickedForTab:(TabItem *)tabItem 
                 atIndex:(NSInteger)index;
```
Called when close button is clicked (before shouldCloseTab).

#### Reorder Events
```objc
- (void)tabBarController:(TabBarController *)controller 
      didMoveTabFromIndex:(NSInteger)fromIndex 
                  toIndex:(NSInteger)toIndex;
```
Called after tabs are reordered.

## User Interactions

### Mouse Operations

| Action | Result |
|--------|--------|
| Click tab | Select tab |
| Click close button (×) | Close tab |
| Right-click tab | Show context menu |
| Drag tab | Reorder tabs |
| Click scroll button | Scroll tabs left/right |
| Scroll wheel | Scroll through tabs |

### Keyboard Operations

| Key | Action |
|-----|--------|
| ← (Left Arrow) | Select previous tab |
| → (Right Arrow) | Select next tab |
| Delete | Close selected tab |

### Context Menu

Right-click on a tab to access:
- **Close Tab**: Close the clicked tab
- **Close Other Tabs**: Close all except clicked tab
- **Close Tabs to the Right**: Close all tabs after this one
- **Close Tabs to the Left**: Close all tabs before this one

## Visual Design

### Tab States

1. **Normal**: Default appearance with subtle border
2. **Selected**: Highlighted background, darker text
3. **Hovered**: Slightly lighter background, shows close button
4. **Modified**: Blue dot indicator before title
5. **Dragging**: Visual feedback during reordering

### Layout

```
┌─────────────────────────────────────────────────────┐
│ [◄] [Tab 1] [● Tab 2] [Tab 3 ×] [Tab 4] [Tab 5] [►]│
└─────────────────────────────────────────────────────┘
     │      │       │        │                      │
     │      │       │        └─ Close button        │
     │      │       └─────────── Modified indicator │
     │      └──────────────────── Tabs              │
     └─────────────────────────── Scroll buttons    │
```

### Dimensions

| Property | Default Value | Description |
|----------|--------------|-------------|
| Tab Height | 28 pt | Fixed height of tab bar |
| Min Width | 60 pt | Minimum tab width |
| Max Width | 200 pt | Maximum tab width |
| Padding | 12 pt | Horizontal padding inside tab |
| Close Button | 14 pt | Size of close button |
| Corner Radius | 4 pt | Tab corner rounding |
| Modified Dot | 6 pt | Size of modified indicator |

### Color Scheme

#### Light Mode
- Background: #E0E0E0 (88% white)
- Selected Tab: #FAFAFA (98% white)
- Border: #BFBFBF (75% white)
- Text: #4D4D4D (30% white)
- Selected Text: #1A1A1A (10% white)

#### Dark Mode
- Background: #333333 (20% white)
- Selected Tab: #404040 (25% white)
- Border: #262626 (15% white)
- Text: #B3B3B3 (70% white)
- Selected Text: #F2F2F2 (95% white)

## Implementation Details

### Drawing Pipeline

1. **Background**: Fill entire view with background color
2. **Tabs**: Draw each visible tab (background, border, content)
3. **Text**: Render title with truncation if needed
4. **Indicators**: Draw modified dot and close button
5. **Scroll Buttons**: Draw overflow navigation if needed
6. **Bottom Border**: Draw separator line

### Layout Algorithm

1. Calculate total width needed for all tabs
2. Determine if scroll buttons are needed
3. Calculate available width after scroll buttons
4. Position tabs from left to right with spacing
5. Update scroll offset to keep selected tab visible
6. Clamp individual tab widths to min/max bounds

### Drag-to-Reorder

1. **Mouse Down**: Detect click on tab, store drag state
2. **Mouse Dragged**: Calculate delta, find target index
3. **Reorder**: Move tab to new position, update indices
4. **Mouse Up**: Clear drag state, finalize position

### Overflow Handling

When total tab width exceeds available space:
1. Show scroll buttons on left and/or right
2. Reduce available width for tabs
3. Allow horizontal scrolling with buttons or wheel
4. Auto-scroll to keep selected tab visible

## Performance Considerations

- **Lazy Drawing**: Only visible tabs are rendered
- **Efficient Layout**: Cached tab frames, recalculated on changes
- **Minimal Redraws**: Only affected areas marked for redisplay
- **Tracking Areas**: Single tracking area for entire view

## Integration with Notepad++

### Typical Integration Points

1. **Document Manager**: Connect tabs to document instances
2. **Window Controller**: Handle delegate callbacks
3. **Menu Commands**: New Tab, Close Tab, Select Next/Previous
4. **File Operations**: Update modified state on changes
5. **Preferences**: Apply user-customized styling

### Example Document Integration

```objc
@interface DocumentWindowController : NSWindowController <TabBarControllerDelegate>
@property (nonatomic, strong) TabBarController *tabBar;
@property (nonatomic, strong) NSMutableArray *documents;
@end

@implementation DocumentWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Setup tab bar
    self.tabBar = [[TabBarController alloc] initWithFrame:NSMakeRect(0, 
        self.window.contentView.bounds.size.height - 28, 
        self.window.contentView.bounds.size.width, 28)];
    self.tabBar.autoresizingMask = NSViewWidthSizable | NSViewMinYMargin;
    self.tabBar.delegate = self;
    [self.window.contentView addSubview:self.tabBar];
}

- (void)openDocument:(NSURL *)url {
    Document *doc = [[Document alloc] initWithURL:url];
    [self.documents addObject:doc];
    
    TabItem *tab = [[TabItem alloc] initWithTitle:url.lastPathComponent];
    tab.representedObject = doc;
    [self.tabBar addTab:tab];
    [self.tabBar selectTab:tab];
}

- (void)documentDidChange:(Document *)document {
    NSInteger index = [self.documents indexOfObject:document];
    if (index != NSNotFound) {
        TabItem *tab = [self.tabBar tabAtIndex:index];
        tab.isModified = document.hasUnsavedChanges;
        [self.tabBar setNeedsDisplay:YES];
    }
}

@end
```

## Future Enhancements

Potential improvements for future versions:

1. **Tab Preview**: Thumbnail preview on hover
2. **Tab Groups**: Color-coded or separated tab groups
3. **Pinned Tabs**: Small, fixed-position tabs that can't be closed
4. **Tab Search**: Quick search/filter for many open tabs
5. **Custom Indicators**: Additional status icons beyond modified
6. **Animations**: Smooth transitions for add/remove/reorder
7. **Accessibility**: Full VoiceOver and keyboard navigation support
8. **Drop Targets**: Drag files onto tab bar to open

## Testing Recommendations

### Manual Testing Checklist

- [ ] Add/remove tabs
- [ ] Select tabs with mouse and keyboard
- [ ] Drag-to-reorder tabs
- [ ] Close tabs with close button
- [ ] Close tabs with context menu
- [ ] Verify modified indicator appears/disappears
- [ ] Test overflow scrolling with many tabs
- [ ] Switch between light and dark mode
- [ ] Test keyboard navigation (arrows, delete)
- [ ] Test all context menu options
- [ ] Verify delegate callbacks fire correctly
- [ ] Test with single tab
- [ ] Test with maximum number of tabs

### Edge Cases

- Empty tab bar (no tabs)
- Single tab
- Many tabs (100+)
- Very long tab titles
- Rapid add/remove operations
- Drag tab to same position
- Close last tab
- Close selected tab
- Reorder while scrolled

## Troubleshooting

### Common Issues

**Issue**: Tabs not drawing
- Check frame is set correctly with non-zero dimensions
- Verify superview hierarchy
- Ensure `setNeedsDisplay:` is called after changes

**Issue**: Click events not working
- Verify view is in responder chain
- Check tracking areas are properly set up
- Ensure frame intersects mouse location

**Issue**: Delegate methods not called
- Confirm delegate is set and not nil
- Verify delegate implements protocol methods
- Check method signatures match protocol

**Issue**: Colors look wrong
- Verify appearance is set correctly
- Check custom colors aren't overriding defaults
- Test in both light and dark modes

## License

Copyright © 2024 Notepad++. All rights reserved.

## Related Files

- `TabBarController.h` - Public interface
- `TabBarController.mm` - Implementation
- `FindReplaceController.h/mm` - Similar control pattern
