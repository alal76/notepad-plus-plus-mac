//
//  TabBarController.mm
//  Notepad++ macOS
//
//  Copyright © 2024 Notepad++. All rights reserved.
//

#import "TabBarController.h"

#pragma mark - TabItem Implementation

@implementation TabItem

- (instancetype)initWithTitle:(NSString *)title {
    self = [super init];
    if (self) {
        _title = title;
        _isModified = NO;
        _isSelected = NO;
        _frame = NSZeroRect;
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<TabItem: %@ (modified: %@, selected: %@)>", 
            self.title, self.isModified ? @"YES" : @"NO", self.isSelected ? @"YES" : @"NO"];
}

@end

#pragma mark - Private Interface

@interface TabBarController ()

@property (nonatomic, strong) NSMutableArray<TabItem *> *mutableTabs;
@property (nonatomic, assign) NSInteger hoveredTabIndex;
@property (nonatomic, assign) NSInteger hoveredCloseButtonIndex;
@property (nonatomic, strong, nullable) NSTrackingArea *trackingArea;
@property (nonatomic, assign) BOOL isDragging;
@property (nonatomic, assign) NSInteger draggedTabIndex;
@property (nonatomic, assign) NSPoint dragStartPoint;
@property (nonatomic, assign) NSInteger dragTargetIndex;
@property (nonatomic, assign) CGFloat scrollOffset;
@property (nonatomic, assign) BOOL showLeftScrollButton;
@property (nonatomic, assign) BOOL showRightScrollButton;
@property (nonatomic, assign) NSRect leftScrollButtonRect;
@property (nonatomic, assign) NSRect rightScrollButtonRect;
@property (nonatomic, assign) BOOL isLeftScrollButtonHovered;
@property (nonatomic, assign) BOOL isRightScrollButtonHovered;

@end

#pragma mark - TabBarController Implementation

@implementation TabBarController

#pragma mark - Constants

static const CGFloat kDefaultTabHeight = 28.0;
static const CGFloat kDefaultTabMinWidth = 60.0;
static const CGFloat kDefaultTabMaxWidth = 200.0;
static const CGFloat kDefaultTabSpacing = 0.0;
static const CGFloat kDefaultCloseButtonSize = 14.0;
static const CGFloat kTabPadding = 12.0;
static const CGFloat kCloseButtonPadding = 8.0;
static const CGFloat kModifiedIndicatorSize = 6.0;
static const CGFloat kScrollButtonWidth = 24.0;
static const CGFloat kTabCornerRadius = 4.0;

#pragma mark - Initialization

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    _mutableTabs = [NSMutableArray array];
    _selectedIndex = -1;
    _hoveredTabIndex = -1;
    _hoveredCloseButtonIndex = -1;
    _isDragging = NO;
    _draggedTabIndex = -1;
    _dragTargetIndex = -1;
    _scrollOffset = 0.0;
    _showLeftScrollButton = NO;
    _showRightScrollButton = NO;
    _isLeftScrollButtonHovered = NO;
    _isRightScrollButtonHovered = NO;
    
    // Set default styling
    _tabHeight = kDefaultTabHeight;
    _tabMinWidth = kDefaultTabMinWidth;
    _tabMaxWidth = kDefaultTabMaxWidth;
    _tabSpacing = kDefaultTabSpacing;
    _closeButtonSize = kDefaultCloseButtonSize;
    
    [self updateColorsForAppearance];
    [self updateTrackingAreas];
}

- (void)updateColorsForAppearance {
    NSAppearance *appearance = self.effectiveAppearance;
    NSString *appearanceName = appearance.name;
    
    BOOL isDarkMode = [appearanceName isEqualToString:NSAppearanceNameDarkAqua] ||
                      [appearanceName isEqualToString:NSAppearanceNameVibrantDark];
    
    if (isDarkMode) {
        _backgroundColor = [NSColor colorWithWhite:0.2 alpha:1.0];
        _selectedTabColor = [NSColor colorWithWhite:0.25 alpha:1.0];
        _tabBorderColor = [NSColor colorWithWhite:0.15 alpha:1.0];
        _textColor = [NSColor colorWithWhite:0.7 alpha:1.0];
        _selectedTextColor = [NSColor colorWithWhite:0.95 alpha:1.0];
    } else {
        _backgroundColor = [NSColor colorWithWhite:0.88 alpha:1.0];
        _selectedTabColor = [NSColor colorWithWhite:0.98 alpha:1.0];
        _tabBorderColor = [NSColor colorWithWhite:0.75 alpha:1.0];
        _textColor = [NSColor colorWithWhite:0.3 alpha:1.0];
        _selectedTextColor = [NSColor colorWithWhite:0.1 alpha:1.0];
    }
    
    _tabFont = [NSFont systemFontOfSize:12.0];
}

- (void)viewDidChangeEffectiveAppearance {
    [super viewDidChangeEffectiveAppearance];
    [self updateColorsForAppearance];
    [self setNeedsDisplay:YES];
}

#pragma mark - Properties

- (NSArray<TabItem *> *)tabs {
    return [_mutableTabs copy];
}

#pragma mark - Tab Management

- (void)addTab:(TabItem *)tabItem {
    [self insertTab:tabItem atIndex:_mutableTabs.count];
}

- (void)insertTab:(TabItem *)tabItem atIndex:(NSInteger)index {
    if (index < 0 || index > _mutableTabs.count) {
        return;
    }
    
    [_mutableTabs insertObject:tabItem atIndex:index];
    [self layoutTabs];
    [self setNeedsDisplay:YES];
}

- (void)removeTab:(TabItem *)tabItem {
    NSInteger index = [_mutableTabs indexOfObject:tabItem];
    if (index != NSNotFound) {
        [self removeTabAtIndex:index];
    }
}

- (void)removeTabAtIndex:(NSInteger)index {
    if (index < 0 || index >= _mutableTabs.count) {
        return;
    }
    
    TabItem *tabItem = _mutableTabs[index];
    
    // Ask delegate if we should close
    if ([self.delegate respondsToSelector:@selector(tabBarController:shouldCloseTab:atIndex:)]) {
        if (![self.delegate tabBarController:self shouldCloseTab:tabItem atIndex:index]) {
            return;
        }
    }
    
    [_mutableTabs removeObjectAtIndex:index];
    
    // Notify delegate
    if ([self.delegate respondsToSelector:@selector(tabBarController:didCloseTab:atIndex:)]) {
        [self.delegate tabBarController:self didCloseTab:tabItem atIndex:index];
    }
    
    // Adjust selection
    if (_selectedIndex == index) {
        if (_mutableTabs.count > 0) {
            _selectedIndex = MIN(index, _mutableTabs.count - 1);
            [self selectTabAtIndex:_selectedIndex];
        } else {
            _selectedIndex = -1;
        }
    } else if (_selectedIndex > index) {
        _selectedIndex--;
    }
    
    [self layoutTabs];
    [self setNeedsDisplay:YES];
}

- (void)selectTab:(TabItem *)tabItem {
    NSInteger index = [_mutableTabs indexOfObject:tabItem];
    if (index != NSNotFound) {
        [self selectTabAtIndex:index];
    }
}

- (void)selectTabAtIndex:(NSInteger)index {
    if (index < 0 || index >= _mutableTabs.count) {
        return;
    }
    
    if (_selectedIndex == index) {
        return;
    }
    
    // Deselect old tab
    if (_selectedIndex >= 0 && _selectedIndex < _mutableTabs.count) {
        _mutableTabs[_selectedIndex].isSelected = NO;
    }
    
    // Select new tab
    _selectedIndex = index;
    _mutableTabs[index].isSelected = YES;
    
    // Ensure tab is visible
    [self scrollToMakeTabVisible:index];
    
    // Notify delegate
    if ([self.delegate respondsToSelector:@selector(tabBarController:didSelectTab:atIndex:)]) {
        [self.delegate tabBarController:self didSelectTab:_mutableTabs[index] atIndex:index];
    }
    
    [self setNeedsDisplay:YES];
}

- (void)moveTabFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex {
    if (fromIndex < 0 || fromIndex >= _mutableTabs.count ||
        toIndex < 0 || toIndex >= _mutableTabs.count ||
        fromIndex == toIndex) {
        return;
    }
    
    TabItem *tabItem = _mutableTabs[fromIndex];
    [_mutableTabs removeObjectAtIndex:fromIndex];
    [_mutableTabs insertObject:tabItem atIndex:toIndex];
    
    // Adjust selected index
    if (_selectedIndex == fromIndex) {
        _selectedIndex = toIndex;
    } else if (_selectedIndex > fromIndex && _selectedIndex <= toIndex) {
        _selectedIndex--;
    } else if (_selectedIndex < fromIndex && _selectedIndex >= toIndex) {
        _selectedIndex++;
    }
    
    // Notify delegate
    if ([self.delegate respondsToSelector:@selector(tabBarController:didMoveTabFromIndex:toIndex:)]) {
        [self.delegate tabBarController:self didMoveTabFromIndex:fromIndex toIndex:toIndex];
    }
    
    [self layoutTabs];
    [self setNeedsDisplay:YES];
}

- (void)removeAllTabs {
    [_mutableTabs removeAllObjects];
    _selectedIndex = -1;
    [self setNeedsDisplay:YES];
}

- (nullable TabItem *)tabAtIndex:(NSInteger)index {
    if (index >= 0 && index < _mutableTabs.count) {
        return _mutableTabs[index];
    }
    return nil;
}

- (NSInteger)indexOfTab:(TabItem *)tabItem {
    return [_mutableTabs indexOfObject:tabItem];
}

#pragma mark - Context Menu Actions

- (void)closeOtherTabsAtIndex:(NSInteger)index {
    if (index < 0 || index >= _mutableTabs.count) {
        return;
    }
    
    TabItem *keepTab = _mutableTabs[index];
    NSMutableArray *tabsToRemove = [NSMutableArray array];
    
    for (NSInteger i = _mutableTabs.count - 1; i >= 0; i--) {
        if (i != index) {
            [tabsToRemove addObject:@(i)];
        }
    }
    
    for (NSNumber *indexNum in tabsToRemove) {
        [self removeTabAtIndex:[indexNum integerValue]];
    }
}

- (void)closeTabsToTheRightOfIndex:(NSInteger)index {
    if (index < 0 || index >= _mutableTabs.count) {
        return;
    }
    
    for (NSInteger i = _mutableTabs.count - 1; i > index; i--) {
        [self removeTabAtIndex:i];
    }
}

- (void)closeTabsToTheLeftOfIndex:(NSInteger)index {
    if (index < 0 || index >= _mutableTabs.count) {
        return;
    }
    
    for (NSInteger i = index - 1; i >= 0; i--) {
        [self removeTabAtIndex:i];
    }
}

#pragma mark - Layout

- (void)layoutTabs {
    if (_mutableTabs.count == 0) {
        _showLeftScrollButton = NO;
        _showRightScrollButton = NO;
        return;
    }
    
    CGFloat availableWidth = self.bounds.size.width;
    CGFloat scrollButtonSpace = 0.0;
    
    // Calculate total width needed
    CGFloat totalTabsWidth = 0.0;
    for (TabItem *tab in _mutableTabs) {
        totalTabsWidth += [self calculateTabWidth:tab];
    }
    
    // Determine if we need scroll buttons
    _showLeftScrollButton = _scrollOffset > 0;
    _showRightScrollButton = totalTabsWidth - _scrollOffset > availableWidth - scrollButtonSpace;
    
    if (_showLeftScrollButton) {
        scrollButtonSpace += kScrollButtonWidth;
        _leftScrollButtonRect = NSMakeRect(0, 0, kScrollButtonWidth, _tabHeight);
    }
    
    if (_showRightScrollButton) {
        scrollButtonSpace += kScrollButtonWidth;
        _rightScrollButtonRect = NSMakeRect(availableWidth - kScrollButtonWidth, 0, 
                                           kScrollButtonWidth, _tabHeight);
    }
    
    // Update available width after scroll buttons
    availableWidth -= scrollButtonSpace;
    
    // Layout tabs
    CGFloat x = (_showLeftScrollButton ? kScrollButtonWidth : 0) - _scrollOffset;
    
    for (TabItem *tab in _mutableTabs) {
        CGFloat tabWidth = [self calculateTabWidth:tab];
        tab.frame = NSMakeRect(x, 0, tabWidth, _tabHeight);
        x += tabWidth + _tabSpacing;
    }
    
    // Clamp scroll offset
    CGFloat maxScroll = MAX(0, totalTabsWidth - availableWidth);
    _scrollOffset = MIN(MAX(0, _scrollOffset), maxScroll);
}

- (CGFloat)calculateTabWidth:(TabItem *)tab {
    NSString *displayTitle = tab.title;
    NSDictionary *attributes = @{NSFontAttributeName: _tabFont};
    CGFloat textWidth = [displayTitle sizeWithAttributes:attributes].width;
    
    // Add padding for text, close button, and modified indicator
    CGFloat width = textWidth + (kTabPadding * 2) + _closeButtonSize + kCloseButtonPadding;
    if (tab.isModified) {
        width += kModifiedIndicatorSize + 4.0;
    }
    
    // Clamp to min/max
    width = MAX(_tabMinWidth, MIN(_tabMaxWidth, width));
    return width;
}

- (void)scrollToMakeTabVisible:(NSInteger)index {
    if (index < 0 || index >= _mutableTabs.count) {
        return;
    }
    
    TabItem *tab = _mutableTabs[index];
    CGFloat tabLeft = tab.frame.origin.x + _scrollOffset;
    CGFloat tabRight = tabLeft + tab.frame.size.width;
    
    CGFloat visibleLeft = _showLeftScrollButton ? kScrollButtonWidth : 0;
    CGFloat visibleRight = self.bounds.size.width - (_showRightScrollButton ? kScrollButtonWidth : 0);
    
    if (tabLeft < visibleLeft) {
        _scrollOffset -= (visibleLeft - tabLeft);
    } else if (tabRight > visibleRight) {
        _scrollOffset += (tabRight - visibleRight);
    }
    
    [self layoutTabs];
}

#pragma mark - Drawing

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Draw background
    [_backgroundColor setFill];
    NSRectFill(dirtyRect);
    
    // Draw tabs
    for (NSInteger i = 0; i < _mutableTabs.count; i++) {
        [self drawTab:_mutableTabs[i] atIndex:i];
    }
    
    // Draw scroll buttons if needed
    if (_showLeftScrollButton) {
        [self drawScrollButton:_leftScrollButtonRect isLeft:YES];
    }
    
    if (_showRightScrollButton) {
        [self drawScrollButton:_rightScrollButtonRect isLeft:NO];
    }
    
    // Draw bottom border
    [_tabBorderColor setStroke];
    NSBezierPath *bottomBorder = [NSBezierPath bezierPath];
    [bottomBorder moveToPoint:NSMakePoint(0, 0)];
    [bottomBorder lineToPoint:NSMakePoint(self.bounds.size.width, 0)];
    [bottomBorder setLineWidth:1.0];
    [bottomBorder stroke];
}

- (void)drawTab:(TabItem *)tab atIndex:(NSInteger)index {
    NSRect tabRect = tab.frame;
    
    // Skip if not visible
    if (NSMaxX(tabRect) < 0 || NSMinX(tabRect) > self.bounds.size.width) {
        return;
    }
    
    BOOL isSelected = tab.isSelected;
    BOOL isHovered = (index == _hoveredTabIndex);
    
    // Draw tab background
    NSColor *bgColor = isSelected ? _selectedTabColor : _backgroundColor;
    if (isHovered && !isSelected) {
        bgColor = [bgColor blendedColorWithFraction:0.1 ofColor:[NSColor whiteColor]];
    }
    
    NSBezierPath *tabPath = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(tabRect, 1, 0)
                                                          xRadius:kTabCornerRadius
                                                          yRadius:kTabCornerRadius];
    [bgColor setFill];
    [tabPath fill];
    
    // Draw tab border
    if (!isSelected) {
        [_tabBorderColor setStroke];
        [tabPath setLineWidth:0.5];
        [tabPath stroke];
    }
    
    // Calculate text area
    CGFloat contentX = tabRect.origin.x + kTabPadding;
    CGFloat availableWidth = tabRect.size.width - (kTabPadding * 2) - _closeButtonSize - kCloseButtonPadding;
    
    // Draw modified indicator
    if (tab.isModified) {
        NSRect dotRect = NSMakeRect(contentX, 
                                   NSMidY(tabRect) - kModifiedIndicatorSize / 2,
                                   kModifiedIndicatorSize, 
                                   kModifiedIndicatorSize);
        NSBezierPath *dotPath = [NSBezierPath bezierPathWithOvalInRect:dotRect];
        [[NSColor colorWithRed:0.2 green:0.5 blue:0.9 alpha:1.0] setFill];
        [dotPath fill];
        
        contentX += kModifiedIndicatorSize + 4.0;
        availableWidth -= kModifiedIndicatorSize + 4.0;
    }
    
    // Draw title
    NSColor *textColor = isSelected ? _selectedTextColor : _textColor;
    NSDictionary *textAttributes = @{
        NSFontAttributeName: _tabFont,
        NSForegroundColorAttributeName: textColor
    };
    
    NSString *title = tab.title;
    CGFloat textWidth = [title sizeWithAttributes:textAttributes].width;
    
    // Truncate title if needed
    if (textWidth > availableWidth) {
        NSMutableString *truncatedTitle = [title mutableCopy];
        while (textWidth > availableWidth && truncatedTitle.length > 1) {
            [truncatedTitle deleteCharactersInRange:NSMakeRange(truncatedTitle.length - 1, 1)];
            NSString *testString = [truncatedTitle stringByAppendingString:@"..."];
            textWidth = [testString sizeWithAttributes:textAttributes].width;
        }
        title = [truncatedTitle stringByAppendingString:@"..."];
    }
    
    NSRect textRect = NSMakeRect(contentX,
                                NSMidY(tabRect) - (_tabFont.pointSize / 2) - 1,
                                availableWidth,
                                _tabFont.pointSize + 4);
    [title drawInRect:textRect withAttributes:textAttributes];
    
    // Draw close button
    NSRect closeButtonRect = [self closeButtonRectForTab:tab];
    if (isHovered || isSelected) {
        [self drawCloseButton:closeButtonRect isHovered:(index == _hoveredCloseButtonIndex)];
    }
}

- (void)drawCloseButton:(NSRect)rect isHovered:(BOOL)isHovered {
    // Draw circle background if hovered
    if (isHovered) {
        [[NSColor colorWithWhite:0.5 alpha:0.2] setFill];
        NSBezierPath *circlePath = [NSBezierPath bezierPathWithOvalInRect:rect];
        [circlePath fill];
    }
    
    // Draw X
    NSColor *xColor = isHovered ? [NSColor colorWithWhite:0.2 alpha:1.0] : 
                                  [NSColor colorWithWhite:0.5 alpha:1.0];
    [xColor setStroke];
    
    CGFloat inset = rect.size.width * 0.3;
    NSBezierPath *xPath = [NSBezierPath bezierPath];
    [xPath moveToPoint:NSMakePoint(NSMinX(rect) + inset, NSMinY(rect) + inset)];
    [xPath lineToPoint:NSMakePoint(NSMaxX(rect) - inset, NSMaxY(rect) - inset)];
    [xPath moveToPoint:NSMakePoint(NSMaxX(rect) - inset, NSMinY(rect) + inset)];
    [xPath lineToPoint:NSMakePoint(NSMinX(rect) + inset, NSMaxY(rect) - inset)];
    [xPath setLineWidth:1.5];
    [xPath stroke];
}

- (void)drawScrollButton:(NSRect)rect isLeft:(BOOL)isLeft {
    BOOL isHovered = isLeft ? _isLeftScrollButtonHovered : _isRightScrollButtonHovered;
    
    // Draw background
    NSColor *bgColor = isHovered ? [_backgroundColor blendedColorWithFraction:0.1 ofColor:[NSColor whiteColor]] :
                                   _backgroundColor;
    [bgColor setFill];
    NSRectFill(rect);
    
    // Draw border
    [_tabBorderColor setStroke];
    NSBezierPath *border = [NSBezierPath bezierPath];
    if (isLeft) {
        [border moveToPoint:NSMakePoint(NSMaxX(rect), NSMinY(rect))];
        [border lineToPoint:NSMakePoint(NSMaxX(rect), NSMaxY(rect))];
    } else {
        [border moveToPoint:NSMakePoint(NSMinX(rect), NSMinY(rect))];
        [border lineToPoint:NSMakePoint(NSMinX(rect), NSMaxY(rect))];
    }
    [border setLineWidth:0.5];
    [border stroke];
    
    // Draw arrow
    [_textColor setFill];
    NSBezierPath *arrow = [NSBezierPath bezierPath];
    CGFloat centerX = NSMidX(rect);
    CGFloat centerY = NSMidY(rect);
    CGFloat arrowSize = 5.0;
    
    if (isLeft) {
        [arrow moveToPoint:NSMakePoint(centerX + arrowSize/2, centerY - arrowSize)];
        [arrow lineToPoint:NSMakePoint(centerX - arrowSize/2, centerY)];
        [arrow lineToPoint:NSMakePoint(centerX + arrowSize/2, centerY + arrowSize)];
    } else {
        [arrow moveToPoint:NSMakePoint(centerX - arrowSize/2, centerY - arrowSize)];
        [arrow lineToPoint:NSMakePoint(centerX + arrowSize/2, centerY)];
        [arrow lineToPoint:NSMakePoint(centerX - arrowSize/2, centerY + arrowSize)];
    }
    [arrow closePath];
    [arrow fill];
}

- (NSRect)closeButtonRectForTab:(TabItem *)tab {
    NSRect tabRect = tab.frame;
    CGFloat x = NSMaxX(tabRect) - kTabPadding - _closeButtonSize;
    CGFloat y = NSMidY(tabRect) - _closeButtonSize / 2;
    return NSMakeRect(x, y, _closeButtonSize, _closeButtonSize);
}

#pragma mark - Mouse Events

- (void)mouseDown:(NSEvent *)event {
    NSPoint location = [self convertPoint:event.locationInWindow fromView:nil];
    
    // Check scroll buttons
    if (_showLeftScrollButton && NSPointInRect(location, _leftScrollButtonRect)) {
        [self scrollLeft];
        return;
    }
    
    if (_showRightScrollButton && NSPointInRect(location, _rightScrollButtonRect)) {
        [self scrollRight];
        return;
    }
    
    // Check tabs
    for (NSInteger i = 0; i < _mutableTabs.count; i++) {
        TabItem *tab = _mutableTabs[i];
        if (NSPointInRect(location, tab.frame)) {
            // Check close button
            NSRect closeButtonRect = [self closeButtonRectForTab:tab];
            if (NSPointInRect(location, closeButtonRect)) {
                if ([self.delegate respondsToSelector:@selector(tabBarController:closeButtonClickedForTab:atIndex:)]) {
                    [self.delegate tabBarController:self closeButtonClickedForTab:tab atIndex:i];
                }
                [self removeTabAtIndex:i];
                return;
            }
            
            // Select tab and prepare for drag
            [self selectTabAtIndex:i];
            _isDragging = YES;
            _draggedTabIndex = i;
            _dragStartPoint = location;
            _dragTargetIndex = i;
            return;
        }
    }
}

- (void)mouseDragged:(NSEvent *)event {
    if (!_isDragging || _draggedTabIndex < 0) {
        return;
    }
    
    NSPoint location = [self convertPoint:event.locationInWindow fromView:nil];
    CGFloat deltaX = location.x - _dragStartPoint.x;
    
    // Check if we should reorder
    if (fabs(deltaX) > 10.0) {
        NSInteger newIndex = _draggedTabIndex;
        
        // Find target index based on mouse position
        for (NSInteger i = 0; i < _mutableTabs.count; i++) {
            TabItem *tab = _mutableTabs[i];
            if (NSPointInRect(location, tab.frame)) {
                newIndex = i;
                break;
            }
        }
        
        if (newIndex != _draggedTabIndex) {
            [self moveTabFromIndex:_draggedTabIndex toIndex:newIndex];
            _draggedTabIndex = newIndex;
            _dragStartPoint = location;
        }
    }
}

- (void)mouseUp:(NSEvent *)event {
    _isDragging = NO;
    _draggedTabIndex = -1;
    _dragTargetIndex = -1;
}

- (void)mouseMoved:(NSEvent *)event {
    [self updateHoverState:event];
}

- (void)mouseExited:(NSEvent *)event {
    _hoveredTabIndex = -1;
    _hoveredCloseButtonIndex = -1;
    _isLeftScrollButtonHovered = NO;
    _isRightScrollButtonHovered = NO;
    [self setNeedsDisplay:YES];
}

- (void)updateHoverState:(NSEvent *)event {
    NSPoint location = [self convertPoint:event.locationInWindow fromView:nil];
    NSInteger oldHoveredTab = _hoveredTabIndex;
    NSInteger oldHoveredCloseButton = _hoveredCloseButtonIndex;
    BOOL oldLeftHovered = _isLeftScrollButtonHovered;
    BOOL oldRightHovered = _isRightScrollButtonHovered;
    
    _hoveredTabIndex = -1;
    _hoveredCloseButtonIndex = -1;
    _isLeftScrollButtonHovered = NO;
    _isRightScrollButtonHovered = NO;
    
    // Check scroll buttons
    if (_showLeftScrollButton && NSPointInRect(location, _leftScrollButtonRect)) {
        _isLeftScrollButtonHovered = YES;
    }
    
    if (_showRightScrollButton && NSPointInRect(location, _rightScrollButtonRect)) {
        _isRightScrollButtonHovered = YES;
    }
    
    // Check tabs
    for (NSInteger i = 0; i < _mutableTabs.count; i++) {
        TabItem *tab = _mutableTabs[i];
        if (NSPointInRect(location, tab.frame)) {
            _hoveredTabIndex = i;
            
            NSRect closeButtonRect = [self closeButtonRectForTab:tab];
            if (NSPointInRect(location, closeButtonRect)) {
                _hoveredCloseButtonIndex = i;
            }
            break;
        }
    }
    
    if (_hoveredTabIndex != oldHoveredTab || 
        _hoveredCloseButtonIndex != oldHoveredCloseButton ||
        _isLeftScrollButtonHovered != oldLeftHovered ||
        _isRightScrollButtonHovered != oldRightHovered) {
        [self setNeedsDisplay:YES];
    }
}

- (void)rightMouseDown:(NSEvent *)event {
    NSPoint location = [self convertPoint:event.locationInWindow fromView:nil];
    
    for (NSInteger i = 0; i < _mutableTabs.count; i++) {
        TabItem *tab = _mutableTabs[i];
        if (NSPointInRect(location, tab.frame)) {
            [self showContextMenuForTabAtIndex:i event:event];
            return;
        }
    }
}

#pragma mark - Context Menu

- (void)showContextMenuForTabAtIndex:(NSInteger)index event:(NSEvent *)event {
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@""];
    
    NSMenuItem *closeItem = [[NSMenuItem alloc] initWithTitle:@"Close Tab"
                                                       action:@selector(contextMenuCloseTab:)
                                                keyEquivalent:@""];
    closeItem.tag = index;
    closeItem.target = self;
    [menu addItem:closeItem];
    
    if (_mutableTabs.count > 1) {
        NSMenuItem *closeOthersItem = [[NSMenuItem alloc] initWithTitle:@"Close Other Tabs"
                                                                 action:@selector(contextMenuCloseOtherTabs:)
                                                          keyEquivalent:@""];
        closeOthersItem.tag = index;
        closeOthersItem.target = self;
        [menu addItem:closeOthersItem];
        
        if (index < _mutableTabs.count - 1) {
            NSMenuItem *closeRightItem = [[NSMenuItem alloc] initWithTitle:@"Close Tabs to the Right"
                                                                    action:@selector(contextMenuCloseTabsToRight:)
                                                             keyEquivalent:@""];
            closeRightItem.tag = index;
            closeRightItem.target = self;
            [menu addItem:closeRightItem];
        }
        
        if (index > 0) {
            NSMenuItem *closeLeftItem = [[NSMenuItem alloc] initWithTitle:@"Close Tabs to the Left"
                                                                   action:@selector(contextMenuCloseTabsToLeft:)
                                                            keyEquivalent:@""];
            closeLeftItem.tag = index;
            closeLeftItem.target = self;
            [menu addItem:closeLeftItem];
        }
    }
    
    [NSMenu popUpContextMenu:menu withEvent:event forView:self];
}

- (void)contextMenuCloseTab:(NSMenuItem *)sender {
    [self removeTabAtIndex:sender.tag];
}

- (void)contextMenuCloseOtherTabs:(NSMenuItem *)sender {
    [self closeOtherTabsAtIndex:sender.tag];
}

- (void)contextMenuCloseTabsToRight:(NSMenuItem *)sender {
    [self closeTabsToTheRightOfIndex:sender.tag];
}

- (void)contextMenuCloseTabsToLeft:(NSMenuItem *)sender {
    [self closeTabsToTheLeftOfIndex:sender.tag];
}

#pragma mark - Scrolling

- (void)scrollLeft {
    _scrollOffset = MAX(0, _scrollOffset - 100.0);
    [self layoutTabs];
    [self setNeedsDisplay:YES];
}

- (void)scrollRight {
    _scrollOffset += 100.0;
    [self layoutTabs];
    [self setNeedsDisplay:YES];
}

- (void)scrollWheel:(NSEvent *)event {
    CGFloat deltaX = event.scrollingDeltaX;
    
    if (event.hasPreciseScrollingDeltas) {
        _scrollOffset -= deltaX;
    } else {
        _scrollOffset -= deltaX * 10.0;
    }
    
    [self layoutTabs];
    [self setNeedsDisplay:YES];
}

#pragma mark - Keyboard Support

- (BOOL)acceptsFirstResponder {
    return YES;
}

- (void)keyDown:(NSEvent *)event {
    NSString *characters = event.charactersIgnoringModifiers;
    
    if (characters.length == 0) {
        [super keyDown:event];
        return;
    }
    
    unichar key = [characters characterAtIndex:0];
    
    switch (key) {
        case NSLeftArrowFunctionKey:
            [self selectPreviousTab];
            break;
            
        case NSRightArrowFunctionKey:
            [self selectNextTab];
            break;
            
        case NSDeleteCharacter:
        case NSDeleteFunctionKey:
            if (_selectedIndex >= 0) {
                [self removeTabAtIndex:_selectedIndex];
            }
            break;
            
        default:
            [super keyDown:event];
            break;
    }
}

- (void)selectPreviousTab {
    if (_selectedIndex > 0) {
        [self selectTabAtIndex:_selectedIndex - 1];
    }
}

- (void)selectNextTab {
    if (_selectedIndex < _mutableTabs.count - 1) {
        [self selectTabAtIndex:_selectedIndex + 1];
    }
}

#pragma mark - Tracking Areas

- (void)updateTrackingAreas {
    if (_trackingArea) {
        [self removeTrackingArea:_trackingArea];
    }
    
    NSTrackingAreaOptions options = NSTrackingMouseMoved | 
                                    NSTrackingMouseEnteredAndExited |
                                    NSTrackingActiveInKeyWindow;
    
    _trackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds
                                                 options:options
                                                   owner:self
                                                userInfo:nil];
    [self addTrackingArea:_trackingArea];
}

- (void)setFrame:(NSRect)frame {
    [super setFrame:frame];
    [self layoutTabs];
    [self updateTrackingAreas];
}

- (void)setBounds:(NSRect)bounds {
    [super setBounds:bounds];
    [self layoutTabs];
    [self updateTrackingAreas];
}

@end
