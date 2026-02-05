//
//  PluginManager.h
//  Notepad++ macOS Plugin System
//
//  Copyright © 2024 Notepad++. All rights reserved.
//
//  PluginManager is the central component of the plugin system. It handles:
//  - Discovery and loading of plugins from the filesystem
//  - Code signature verification for security
//  - Plugin lifecycle management (initialization, cleanup)
//  - Menu integration for plugin commands
//  - Notification dispatch to loaded plugins
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#include "PluginInterface.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Plugin load state enumeration.
 * Tracks the current state of each plugin in the system.
 */
typedef NS_ENUM(NSInteger, PluginState) {
    PluginStateUnloaded = 0,      // Not loaded
    PluginStateLoaded,            // Loaded but not initialized
    PluginStateInitialized,       // Fully initialized and active
    PluginStateFailed,            // Failed to load or initialize
    PluginStateDisabled           // Disabled by user
};

/**
 * Plugin descriptor class.
 * Encapsulates all information about a loaded plugin including its
 * function pointers, metadata, and current state.
 */
@interface PluginDescriptor : NSObject

@property (strong, nonatomic) NSString *name;              // Plugin name
@property (strong, nonatomic) NSString *version;           // Version string
@property (strong, nonatomic) NSString *author;            // Author name
@property (strong, nonatomic) NSString *pluginDescription; // Description
@property (strong, nonatomic) NSString *website;           // Website URL
@property (strong, nonatomic) NSURL *bundlePath;          // Path to .dylib file
@property (nonatomic) PluginState state;                   // Current state
@property (nonatomic) void *handle;                        // dlopen handle
@property (nonatomic) PluginInfo info;                     // C struct info
@property (nonatomic) PluginFunctionArray functions;       // Menu items
@property (strong, nonatomic) NSArray<NSMenuItem *> *menuItems; // Cocoa menu items
@property (strong, nonatomic, nullable) NSError *lastError; // Last error that occurred

// Function pointers to plugin's exported functions
@property (nonatomic) void (*pluginGetInfo)(PluginInfo *);
@property (nonatomic) bool (*pluginInit)(const PluginInfo *);
@property (nonatomic) void (*pluginCleanup)(void);
@property (nonatomic) void (*pluginGetFunctions)(PluginFunctionArray *);
@property (nonatomic) void (*pluginBeNotified)(NotificationData *);
@property (nonatomic, nullable) void (*pluginSetScintilla)(const ScintillaInterface *);
@property (nonatomic, nullable) void (*pluginShowSettings)(void);

@end

/**
 * PluginManager - Singleton class managing the plugin system.
 * 
 * ARCHITECTURE OVERVIEW:
 * ----------------------
 * The plugin system follows a classic dynamic loading architecture:
 * 
 * 1. DISCOVERY: Scans ~/Library/Application Support/Notepad++/plugins/ for .dylib files
 * 2. VERIFICATION: Validates code signatures to prevent malicious plugins
 * 3. LOADING: Uses dlopen() to dynamically load the plugin library
 * 4. SYMBOL RESOLUTION: Uses dlsym() to find required function exports
 * 5. INITIALIZATION: Calls pluginInit() to let the plugin set itself up
 * 6. INTEGRATION: Adds plugin's menu items to the Plugins menu
 * 7. OPERATION: Dispatches notifications to plugins as events occur
 * 8. CLEANUP: Calls pluginCleanup() and dlclose() when unloading
 * 
 * SECURITY:
 * ---------
 * - Plugins must be code-signed by a valid developer certificate
 * - Optional: Can require specific team ID or certificate for enterprise use
 * - Sandboxing is not applied to plugins (they have full app privileges)
 * - Users should only install plugins from trusted sources
 * 
 * THREAD SAFETY:
 * --------------
 * - All plugin operations occur on the main thread
 * - Plugins should use GCD or NSOperationQueue for background work
 * - Plugin callbacks are synchronous and block the main thread
 */
@interface PluginManager : NSObject

// ============================================================================
// SINGLETON ACCESS
// ============================================================================

/**
 * Get the shared plugin manager instance.
 * This is the only way to access the plugin manager (singleton pattern).
 * 
 * @return The shared PluginManager instance
 */
+ (instancetype)sharedManager;

// ============================================================================
// PLUGIN DISCOVERY AND LOADING
// ============================================================================

/**
 * Get the standard plugin directory path.
 * Default: ~/Library/Application Support/Notepad++/plugins/
 * 
 * @return URL to the plugin directory
 */
+ (NSURL *)pluginDirectory;

/**
 * Discover all plugins in the plugin directory.
 * Scans for .dylib files and returns their paths without loading them.
 * 
 * @param error Output parameter for error information
 * @return Array of NSURL objects pointing to plugin bundles, or nil on error
 */
- (nullable NSArray<NSURL *> *)discoverPluginsWithError:(NSError **)error;

/**
 * Load a single plugin from the specified path.
 * Performs verification, dynamic loading, and initialization.
 * 
 * @param url Path to the .dylib plugin file
 * @param error Output parameter for error information
 * @return Plugin descriptor if successful, nil otherwise
 */
- (nullable PluginDescriptor *)loadPluginAtURL:(NSURL *)url error:(NSError **)error;

/**
 * Load all plugins from the plugin directory.
 * Discovers and loads all valid plugins, skipping those that fail verification.
 * 
 * @param error Output parameter for error information (first failure only)
 * @return Number of successfully loaded plugins
 */
- (NSInteger)loadAllPluginsWithError:(NSError **)error;

/**
 * Unload a specific plugin.
 * Calls cleanup function and removes from active plugin list.
 * 
 * @param pluginName Name of the plugin to unload
 * @return YES if successful, NO otherwise
 */
- (BOOL)unloadPlugin:(NSString *)pluginName;

/**
 * Unload all plugins.
 * Called during application shutdown.
 */
- (void)unloadAllPlugins;

/**
 * Reload a specific plugin.
 * Unloads and then reloads the plugin (useful for development).
 * 
 * @param pluginName Name of the plugin to reload
 * @param error Output parameter for error information
 * @return YES if successful, NO otherwise
 */
- (BOOL)reloadPlugin:(NSString *)pluginName error:(NSError **)error;

// ============================================================================
// PLUGIN INFORMATION
// ============================================================================

/**
 * Get all loaded plugins.
 * 
 * @return Array of PluginDescriptor objects for all loaded plugins
 */
- (NSArray<PluginDescriptor *> *)loadedPlugins;

/**
 * Get a specific plugin by name.
 * 
 * @param name The plugin name
 * @return PluginDescriptor for the plugin, or nil if not found
 */
- (nullable PluginDescriptor *)pluginNamed:(NSString *)name;

/**
 * Check if a plugin is loaded.
 * 
 * @param name The plugin name
 * @return YES if the plugin is loaded, NO otherwise
 */
- (BOOL)isPluginLoaded:(NSString *)name;

/**
 * Get the number of loaded plugins.
 * 
 * @return Count of loaded plugins
 */
- (NSInteger)pluginCount;

// ============================================================================
// SECURITY AND VERIFICATION
// ============================================================================

/**
 * Verify code signature of a plugin bundle.
 * Checks that the plugin is properly signed and not tampered with.
 * 
 * @param url Path to the plugin file
 * @param error Output parameter for error information
 * @return YES if signature is valid, NO otherwise
 */
- (BOOL)verifyCodeSignatureAtURL:(NSURL *)url error:(NSError **)error;

/**
 * Enable/disable code signature verification.
 * Default is YES. Only disable for development/testing.
 * 
 * @param enabled YES to require valid signatures, NO to skip verification
 */
- (void)setCodeSignatureVerificationEnabled:(BOOL)enabled;

/**
 * Check if code signature verification is enabled.
 * 
 * @return YES if verification is enabled, NO otherwise
 */
- (BOOL)isCodeSignatureVerificationEnabled;

// ============================================================================
// MENU INTEGRATION
// ============================================================================

/**
 * Get or create the Plugins menu.
 * Returns the Plugins submenu from the main menu bar.
 * Creates it if it doesn't exist.
 * 
 * @return The Plugins NSMenu object
 */
- (NSMenu *)pluginsMenu;

/**
 * Update the Plugins menu with all loaded plugins.
 * Rebuilds the menu with items from all loaded plugins.
 */
- (void)updatePluginsMenu;

/**
 * Add a plugin's menu items to the Plugins menu.
 * 
 * @param plugin The plugin descriptor
 */
- (void)addMenuItemsForPlugin:(PluginDescriptor *)plugin;

/**
 * Remove a plugin's menu items from the Plugins menu.
 * 
 * @param plugin The plugin descriptor
 */
- (void)removeMenuItemsForPlugin:(PluginDescriptor *)plugin;

// ============================================================================
// NOTIFICATION DISPATCH
// ============================================================================

/**
 * Send a notification to all loaded plugins.
 * Calls each plugin's beNotified() callback with the specified notification.
 * 
 * @param notification The notification type
 * @param data Additional data (may be NULL)
 * @param dataSize Size of data in bytes
 */
- (void)notifyPlugins:(PluginNotification)notification 
                 data:(nullable void *)data 
             dataSize:(size_t)dataSize;

/**
 * Send a notification to a specific plugin.
 * 
 * @param notification The notification type
 * @param pluginName Name of the plugin to notify
 * @param data Additional data (may be NULL)
 * @param dataSize Size of data in bytes
 */
- (void)notifyPlugin:(NSString *)pluginName
        notification:(PluginNotification)notification
                data:(nullable void *)data
            dataSize:(size_t)dataSize;

/**
 * Send a cancellable notification to all plugins.
 * Stops if any plugin cancels the operation.
 * 
 * @param notification The notification type
 * @param data Additional data (may be NULL)
 * @param dataSize Size of data in bytes
 * @return YES if operation should proceed, NO if cancelled by a plugin
 */
- (BOOL)notifyPluginsCancellable:(PluginNotification)notification
                            data:(nullable void *)data
                        dataSize:(size_t)dataSize;

// ============================================================================
// SCINTILLA INTEGRATION
// ============================================================================

/**
 * Set the current Scintilla interface.
 * Called when the active editor changes. Forwards to all plugins
 * that implement pluginSetScintilla().
 * 
 * @param sci Pointer to ScintillaInterface structure
 */
- (void)setScintillaInterface:(const ScintillaInterface *)sci;

// ============================================================================
// ERROR HANDLING
// ============================================================================

/**
 * Error domain for plugin-related errors.
 */
extern NSErrorDomain const PluginManagerErrorDomain;

/**
 * Error codes for plugin operations.
 */
typedef NS_ENUM(NSInteger, PluginManagerErrorCode) {
    PluginManagerErrorCodeNotFound = 1000,        // Plugin file not found
    PluginManagerErrorCodeInvalidFormat,          // Not a valid plugin format
    PluginManagerErrorCodeSignatureInvalid,       // Code signature verification failed
    PluginManagerErrorCodeMissingSymbol,          // Required function not exported
    PluginManagerErrorCodeInitializationFailed,   // pluginInit() returned false
    PluginManagerErrorCodeAlreadyLoaded,          // Plugin is already loaded
    PluginManagerErrorCodeVersionMismatch,        // API version incompatible
    PluginManagerErrorCodeLoadFailed              // dlopen() failed
};

@end

NS_ASSUME_NONNULL_END
