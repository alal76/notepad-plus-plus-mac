//
//  TabBarController.h
//  Notepad++ macOS
//
//  Copyright © 2024 Notepad++. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TabBarController;
@class TabItem;

NS_ASSUME_NONNULL_BEGIN

/**
 * Represents a single tab in the tab bar
 */
@interface TabItem : NSObject

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong, nullable) NSString *tooltip;
@property (nonatomic, strong, nullable) id representedObject;
@property (nonatomic, assign) BOOL isModified;
@property (nonatomic, assign) BOOL isSelected;
@property (nonatomic, assign) NSRect frame;

- (instancetype)initWithTitle:(NSString *)title;

@end

/**
 * Delegate protocol for TabBarController
 * Notifies about tab events like selection, closure, and reordering
 */
@protocol TabBarControllerDelegate <NSObject>

@optional

/**
 * Called when a tab is selected
 * @param controller The TabBarController instance
 * @param tabItem The selected tab item
 * @param index The index of the selected tab
 */
- (void)tabBarController:(TabBarController *)controller didSelectTab:(TabItem *)tabItem atIndex:(NSInteger)index;

/**
 * Called when a tab is about to close
 * @param controller The TabBarController instance
 * @param tabItem The tab item about to close
 * @param index The index of the tab
 * @return YES to allow closing, NO to prevent it
 */
- (BOOL)tabBarController:(TabBarController *)controller shouldCloseTab:(TabItem *)tabItem atIndex:(NSInteger)index;

/**
 * Called when a tab is closed
 * @param controller The TabBarController instance
 * @param tabItem The closed tab item
 * @param index The index of the closed tab
 */
- (void)tabBarController:(TabBarController *)controller didCloseTab:(TabItem *)tabItem atIndex:(NSInteger)index;

/**
 * Called when tabs are reordered
 * @param controller The TabBarController instance
 * @param fromIndex The original index
 * @param toIndex The new index
 */
- (void)tabBarController:(TabBarController *)controller didMoveTabFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex;

/**
 * Called when the close button is clicked
 * @param controller The TabBarController instance
 * @param tabItem The tab item
 * @param index The index of the tab
 */
- (void)tabBarController:(TabBarController *)controller closeButtonClickedForTab:(TabItem *)tabItem atIndex:(NSInteger)index;

@end

/**
 * Custom tab bar controller for managing document tabs in Notepad++
 * Provides native macOS appearance with support for light/dark mode
 */
@interface TabBarController : NSView

#pragma mark - Properties

@property (nonatomic, weak, nullable) id<TabBarControllerDelegate> delegate;
@property (nonatomic, strong, readonly) NSArray<TabItem *> *tabs;
@property (nonatomic, assign) NSInteger selectedIndex;

#pragma mark - Styling Properties

@property (nonatomic, strong) NSColor *backgroundColor;
@property (nonatomic, strong) NSColor *selectedTabColor;
@property (nonatomic, strong) NSColor *tabBorderColor;
@property (nonatomic, strong) NSColor *textColor;
@property (nonatomic, strong) NSColor *selectedTextColor;
@property (nonatomic, strong) NSFont *tabFont;
@property (nonatomic, assign) CGFloat tabHeight;
@property (nonatomic, assign) CGFloat tabMinWidth;
@property (nonatomic, assign) CGFloat tabMaxWidth;
@property (nonatomic, assign) CGFloat tabSpacing;
@property (nonatomic, assign) CGFloat closeButtonSize;

#pragma mark - Initialization

- (instancetype)initWithFrame:(NSRect)frameRect;

#pragma mark - Tab Management

/**
 * Adds a new tab to the tab bar
 * @param tabItem The tab item to add
 */
- (void)addTab:(TabItem *)tabItem;

/**
 * Inserts a tab at a specific index
 * @param tabItem The tab item to insert
 * @param index The index where to insert the tab
 */
- (void)insertTab:(TabItem *)tabItem atIndex:(NSInteger)index;

/**
 * Removes a tab from the tab bar
 * @param tabItem The tab item to remove
 */
- (void)removeTab:(TabItem *)tabItem;

/**
 * Removes a tab at a specific index
 * @param index The index of the tab to remove
 */
- (void)removeTabAtIndex:(NSInteger)index;

/**
 * Selects a tab
 * @param tabItem The tab item to select
 */
- (void)selectTab:(TabItem *)tabItem;

/**
 * Selects a tab at a specific index
 * @param index The index of the tab to select
 */
- (void)selectTabAtIndex:(NSInteger)index;

/**
 * Moves a tab from one index to another
 * @param fromIndex The original index
 * @param toIndex The destination index
 */
- (void)moveTabFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex;

/**
 * Removes all tabs
 */
- (void)removeAllTabs;

/**
 * Returns the tab at a specific index
 * @param index The index of the tab
 * @return The tab item at the index, or nil if out of bounds
 */
- (nullable TabItem *)tabAtIndex:(NSInteger)index;

/**
 * Returns the index of a specific tab
 * @param tabItem The tab item to find
 * @return The index of the tab, or NSNotFound if not found
 */
- (NSInteger)indexOfTab:(TabItem *)tabItem;

#pragma mark - Context Menu Actions

/**
 * Closes all tabs except the specified one
 * @param index The index of the tab to keep open
 */
- (void)closeOtherTabsAtIndex:(NSInteger)index;

/**
 * Closes all tabs to the right of the specified index
 * @param index The index after which to close tabs
 */
- (void)closeTabsToTheRightOfIndex:(NSInteger)index;

/**
 * Closes all tabs to the left of the specified index
 * @param index The index before which to close tabs
 */
- (void)closeTabsToTheLeftOfIndex:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END
