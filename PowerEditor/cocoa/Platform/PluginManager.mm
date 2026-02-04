//
//  PluginManager.mm
//  Notepad++ macOS Plugin System
//
//  Copyright © 2024 Notepad++. All rights reserved.
//
//  Implementation of the plugin manager for macOS.
//  Uses dlopen/dlsym for dynamic loading and macOS Security framework
//  for code signature verification.
//

#import "PluginManager.h"
#import <dlfcn.h>
#import <Security/Security.h>

// Error domain
NSErrorDomain const PluginManagerErrorDomain = @"com.notepadpp.pluginmanager";

// ============================================================================
// PLUGIN DESCRIPTOR IMPLEMENTATION
// ============================================================================

@implementation PluginDescriptor

- (instancetype)init {
    self = [super init];
    if (self) {
        _state = PluginStateUnloaded;
        _handle = NULL;
        _menuItems = @[];
    }
    return self;
}

- (void)dealloc {
    // Ensure plugin is properly cleaned up
    if (_handle != NULL && _pluginCleanup != NULL) {
        _pluginCleanup();
    }
    if (_handle != NULL) {
        dlclose(_handle);
        _handle = NULL;
    }
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<PluginDescriptor: %@ v%@ (%@)>",
            self.name, self.version, @(self.state)];
}

@end

// ============================================================================
// PLUGIN MANAGER IMPLEMENTATION
// ============================================================================

@interface PluginManager ()

@property (strong, nonatomic) NSMutableDictionary<NSString *, PluginDescriptor *> *plugins;
@property (strong, nonatomic) NSMenu *pluginsMenu;
@property (nonatomic) BOOL codeSignatureVerificationEnabled;
@property (nonatomic) ScintillaInterface currentScintilla;
@property (nonatomic) BOOL hasScintilla;

@end

@implementation PluginManager

// ============================================================================
// SINGLETON PATTERN
// ============================================================================

+ (instancetype)sharedManager {
    static PluginManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _plugins = [NSMutableDictionary dictionary];
        _codeSignatureVerificationEnabled = YES; // Enabled by default for security
        _hasScintilla = NO;
        
        // Listen for application termination to clean up plugins
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationWillTerminate:)
                                                     name:NSApplicationWillTerminateNotification
                                                   object:nil];
        
        NSLog(@"[PluginManager] Initialized");
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self unloadAllPlugins];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    NSLog(@"[PluginManager] Application terminating, unloading all plugins");
    [self notifyPlugins:PN_SHUTDOWN data:NULL dataSize:0];
    [self unloadAllPlugins];
}

// ============================================================================
// PLUGIN DIRECTORY
// ============================================================================

+ (NSURL *)pluginDirectory {
    // Get Application Support directory
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,
                                                         NSUserDomainMask, YES);
    if (paths.count == 0) {
        return nil;
    }
    
    NSString *appSupport = paths[0];
    NSString *pluginPath = [appSupport stringByAppendingPathComponent:@"Notepad++/plugins"];
    NSURL *url = [NSURL fileURLWithPath:pluginPath isDirectory:YES];
    
    // Create directory if it doesn't exist
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:pluginPath]) {
        NSError *error = nil;
        [fm createDirectoryAtURL:url
     withIntermediateDirectories:YES
                      attributes:nil
                           error:&error];
        if (error) {
            NSLog(@"[PluginManager] Failed to create plugin directory: %@", error);
        }
    }
    
    return url;
}

// ============================================================================
// PLUGIN DISCOVERY
// ============================================================================

- (NSArray<NSURL *> *)discoverPluginsWithError:(NSError **)error {
    NSURL *pluginDir = [PluginManager pluginDirectory];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *localError = nil;
    
    // Get contents of plugin directory
    NSArray<NSURL *> *contents = [fm contentsOfDirectoryAtURL:pluginDir
                                   includingPropertiesForKeys:@[NSURLIsRegularFileKey]
                                                      options:NSDirectoryEnumerationSkipsHiddenFiles
                                                        error:&localError];
    
    if (localError) {
        NSLog(@"[PluginManager] Failed to read plugin directory: %@", localError);
        if (error) *error = localError;
        return nil;
    }
    
    // Filter for .dylib files
    NSMutableArray<NSURL *> *plugins = [NSMutableArray array];
    for (NSURL *url in contents) {
        if ([url.pathExtension isEqualToString:@"dylib"]) {
            [plugins addObject:url];
        }
    }
    
    NSLog(@"[PluginManager] Discovered %lu plugin(s)", (unsigned long)plugins.count);
    return [plugins copy];
}

// ============================================================================
// CODE SIGNATURE VERIFICATION
// ============================================================================

- (BOOL)verifyCodeSignatureAtURL:(NSURL *)url error:(NSError **)error {
    if (!self.codeSignatureVerificationEnabled) {
        NSLog(@"[PluginManager] Code signature verification disabled (development mode)");
        return YES;
    }
    
    // Create static code object from the file
    SecStaticCodeRef staticCode = NULL;
    OSStatus status = SecStaticCodeCreateWithPath((__bridge CFURLRef)url,
                                                   kSecCSDefaultFlags,
                                                   &staticCode);
    
    if (status != errSecSuccess) {
        NSLog(@"[PluginManager] Failed to create static code reference: %d", status);
        if (error) {
            *error = [NSError errorWithDomain:PluginManagerErrorDomain
                                        code:PluginManagerErrorCodeSignatureInvalid
                                    userInfo:@{NSLocalizedDescriptionKey: @"Failed to read code signature"}];
        }
        return NO;
    }
    
    // Verify the signature
    SecCSFlags flags = kSecCSDefaultFlags | kSecCSCheckAllArchitectures;
    status = SecStaticCodeCheckValidity(staticCode, flags, NULL);
    
    CFRelease(staticCode);
    
    if (status != errSecSuccess) {
        NSLog(@"[PluginManager] Code signature verification failed: %d", status);
        if (error) {
            NSString *message = [NSString stringWithFormat:
                               @"Code signature is invalid or missing (error %d). "
                               @"Only install plugins from trusted sources.", status];
            *error = [NSError errorWithDomain:PluginManagerErrorDomain
                                        code:PluginManagerErrorCodeSignatureInvalid
                                    userInfo:@{NSLocalizedDescriptionKey: message}];
        }
        return NO;
    }
    
    NSLog(@"[PluginManager] Code signature verification passed for %@", url.lastPathComponent);
    return YES;
}

- (void)setCodeSignatureVerificationEnabled:(BOOL)enabled {
    _codeSignatureVerificationEnabled = enabled;
    NSLog(@"[PluginManager] Code signature verification %@",
          enabled ? @"enabled" : @"disabled");
}

- (BOOL)isCodeSignatureVerificationEnabled {
    return _codeSignatureVerificationEnabled;
}

// ============================================================================
// PLUGIN LOADING
// ============================================================================

- (PluginDescriptor *)loadPluginAtURL:(NSURL *)url error:(NSError **)error {
    NSString *pluginPath = url.path;
    NSString *pluginFilename = url.lastPathComponent;
    
    NSLog(@"[PluginManager] Loading plugin: %@", pluginFilename);
    
    // Check if file exists
    if (![[NSFileManager defaultManager] fileExistsAtPath:pluginPath]) {
        NSLog(@"[PluginManager] Plugin file not found: %@", pluginPath);
        if (error) {
            *error = [NSError errorWithDomain:PluginManagerErrorDomain
                                        code:PluginManagerErrorCodeNotFound
                                    userInfo:@{NSLocalizedDescriptionKey: @"Plugin file not found"}];
        }
        return nil;
    }
    
    // Verify code signature
    NSError *verifyError = nil;
    if (![self verifyCodeSignatureAtURL:url error:&verifyError]) {
        if (error) *error = verifyError;
        return nil;
    }
    
    // Create plugin descriptor
    PluginDescriptor *plugin = [[PluginDescriptor alloc] init];
    plugin.bundlePath = url;
    plugin.state = PluginStateUnloaded;
    
    // Load the dynamic library
    void *handle = dlopen([pluginPath UTF8String], RTLD_NOW | RTLD_LOCAL);
    if (!handle) {
        const char *errorMsg = dlerror();
        NSLog(@"[PluginManager] dlopen failed: %s", errorMsg);
        if (error) {
            NSString *message = [NSString stringWithFormat:@"Failed to load plugin: %s",
                               errorMsg ? errorMsg : "unknown error"];
            *error = [NSError errorWithDomain:PluginManagerErrorDomain
                                        code:PluginManagerErrorCodeLoadFailed
                                    userInfo:@{NSLocalizedDescriptionKey: message}];
        }
        return nil;
    }
    
    plugin.handle = handle;
    plugin.state = PluginStateLoaded;
    
    // Resolve required function symbols
    BOOL success = [self resolveSymbolsForPlugin:plugin error:error];
    if (!success) {
        dlclose(handle);
        plugin.handle = NULL;
        return nil;
    }
    
    // Get plugin information
    if (plugin.pluginGetInfo) {
        plugin.pluginGetInfo(&plugin->_info);
        
        // Validate API version
        if (plugin.info.apiVersion != PLUGIN_API_VERSION) {
            NSLog(@"[PluginManager] Plugin API version mismatch: expected %d, got %d",
                  PLUGIN_API_VERSION, plugin.info.apiVersion);
            if (error) {
                NSString *message = [NSString stringWithFormat:
                                   @"Plugin API version %d is not compatible with version %d",
                                   plugin.info.apiVersion, PLUGIN_API_VERSION];
                *error = [NSError errorWithDomain:PluginManagerErrorDomain
                                            code:PluginManagerErrorCodeVersionMismatch
                                        userInfo:@{NSLocalizedDescriptionKey: message}];
            }
            dlclose(handle);
            plugin.handle = NULL;
            return nil;
        }
        
        // Copy strings to Objective-C properties
        plugin.name = [NSString stringWithUTF8String:plugin.info.name];
        plugin.version = [NSString stringWithUTF8String:plugin.info.version];
        plugin.author = [NSString stringWithUTF8String:plugin.info.author];
        plugin.pluginDescription = [NSString stringWithUTF8String:plugin.info.description];
        plugin.website = [NSString stringWithUTF8String:plugin.info.website];
    }
    
    // Check if already loaded
    if (self.plugins[plugin.name]) {
        NSLog(@"[PluginManager] Plugin already loaded: %@", plugin.name);
        if (error) {
            *error = [NSError errorWithDomain:PluginManagerErrorDomain
                                        code:PluginManagerErrorCodeAlreadyLoaded
                                    userInfo:@{NSLocalizedDescriptionKey:
                                             @"A plugin with this name is already loaded"}];
        }
        dlclose(handle);
        plugin.handle = NULL;
        return nil;
    }
    
    // Initialize the plugin
    if (plugin.pluginInit) {
        bool initResult = plugin.pluginInit(&plugin->_info);
        if (!initResult) {
            NSLog(@"[PluginManager] Plugin initialization failed: %@", plugin.name);
            if (error) {
                *error = [NSError errorWithDomain:PluginManagerErrorDomain
                                            code:PluginManagerErrorCodeInitializationFailed
                                        userInfo:@{NSLocalizedDescriptionKey:
                                                 @"Plugin initialization returned false"}];
            }
            dlclose(handle);
            plugin.handle = NULL;
            return nil;
        }
    }
    
    plugin.state = PluginStateInitialized;
    
    // Get plugin functions (menu items)
    if (plugin.pluginGetFunctions) {
        plugin.pluginGetFunctions(&plugin->_functions);
    }
    
    // Set Scintilla interface if available
    if (self.hasScintilla && plugin.pluginSetScintilla) {
        plugin.pluginSetScintilla(&_currentScintilla);
    }
    
    // Add to loaded plugins
    self.plugins[plugin.name] = plugin;
    
    NSLog(@"[PluginManager] Successfully loaded plugin: %@ v%@ by %@",
          plugin.name, plugin.version, plugin.author);
    
    return plugin;
}

/**
 * Resolve all required and optional function symbols from the plugin.
 */
- (BOOL)resolveSymbolsForPlugin:(PluginDescriptor *)plugin error:(NSError **)error {
    // Required functions
    plugin.pluginGetInfo = dlsym(plugin.handle, "pluginGetInfo");
    plugin.pluginInit = dlsym(plugin.handle, "pluginInit");
    plugin.pluginCleanup = dlsym(plugin.handle, "pluginCleanup");
    plugin.pluginGetFunctions = dlsym(plugin.handle, "pluginGetFunctions");
    plugin.pluginBeNotified = dlsym(plugin.handle, "pluginBeNotified");
    
    // Check required functions
    if (!plugin.pluginGetInfo || !plugin.pluginInit || !plugin.pluginCleanup ||
        !plugin.pluginGetFunctions || !plugin.pluginBeNotified) {
        
        const char *missing = !plugin.pluginGetInfo ? "pluginGetInfo" :
                             !plugin.pluginInit ? "pluginInit" :
                             !plugin.pluginCleanup ? "pluginCleanup" :
                             !plugin.pluginGetFunctions ? "pluginGetFunctions" :
                             "pluginBeNotified";
        
        NSLog(@"[PluginManager] Missing required symbol: %s", missing);
        if (error) {
            NSString *message = [NSString stringWithFormat:
                               @"Plugin is missing required function: %s", missing];
            *error = [NSError errorWithDomain:PluginManagerErrorDomain
                                        code:PluginManagerErrorCodeMissingSymbol
                                    userInfo:@{NSLocalizedDescriptionKey: message}];
        }
        return NO;
    }
    
    // Optional functions (don't fail if missing)
    plugin.pluginSetScintilla = dlsym(plugin.handle, "pluginSetScintilla");
    plugin.pluginShowSettings = dlsym(plugin.handle, "pluginShowSettings");
    
    return YES;
}

- (NSInteger)loadAllPluginsWithError:(NSError **)error {
    NSArray<NSURL *> *pluginURLs = [self discoverPluginsWithError:error];
    if (!pluginURLs) {
        return 0;
    }
    
    NSInteger loadedCount = 0;
    NSError *firstError = nil;
    
    for (NSURL *url in pluginURLs) {
        NSError *loadError = nil;
        PluginDescriptor *plugin = [self loadPluginAtURL:url error:&loadError];
        
        if (plugin) {
            loadedCount++;
            [self addMenuItemsForPlugin:plugin];
        } else {
            // Save first error but continue loading other plugins
            if (!firstError) {
                firstError = loadError;
            }
        }
    }
    
    if (error && firstError && loadedCount == 0) {
        *error = firstError;
    }
    
    // Notify plugins that system is ready
    [self notifyPlugins:PN_READY data:NULL dataSize:0];
    
    [self updatePluginsMenu];
    
    NSLog(@"[PluginManager] Loaded %ld of %lu plugin(s)",
          (long)loadedCount, (unsigned long)pluginURLs.count);
    
    return loadedCount;
}

// ============================================================================
// PLUGIN UNLOADING
// ============================================================================

- (BOOL)unloadPlugin:(NSString *)pluginName {
    PluginDescriptor *plugin = self.plugins[pluginName];
    if (!plugin) {
        NSLog(@"[PluginManager] Plugin not found: %@", pluginName);
        return NO;
    }
    
    NSLog(@"[PluginManager] Unloading plugin: %@", pluginName);
    
    // Remove menu items
    [self removeMenuItemsForPlugin:plugin];
    
    // Call cleanup
    if (plugin.pluginCleanup) {
        plugin.pluginCleanup();
    }
    
    // Close library
    if (plugin.handle) {
        dlclose(plugin.handle);
        plugin.handle = NULL;
    }
    
    plugin.state = PluginStateUnloaded;
    
    // Remove from loaded plugins
    [self.plugins removeObjectForKey:pluginName];
    
    [self updatePluginsMenu];
    
    return YES;
}

- (void)unloadAllPlugins {
    NSLog(@"[PluginManager] Unloading all plugins");
    
    NSArray<NSString *> *pluginNames = [self.plugins.allKeys copy];
    for (NSString *name in pluginNames) {
        [self unloadPlugin:name];
    }
}

- (BOOL)reloadPlugin:(NSString *)pluginName error:(NSError **)error {
    PluginDescriptor *plugin = self.plugins[pluginName];
    if (!plugin) {
        if (error) {
            *error = [NSError errorWithDomain:PluginManagerErrorDomain
                                        code:PluginManagerErrorCodeNotFound
                                    userInfo:@{NSLocalizedDescriptionKey:
                                             @"Plugin not found"}];
        }
        return NO;
    }
    
    NSURL *url = plugin.bundlePath;
    
    // Unload
    [self unloadPlugin:pluginName];
    
    // Reload
    PluginDescriptor *newPlugin = [self loadPluginAtURL:url error:error];
    if (newPlugin) {
        [self addMenuItemsForPlugin:newPlugin];
        [self updatePluginsMenu];
        return YES;
    }
    
    return NO;
}

// ============================================================================
// PLUGIN INFORMATION
// ============================================================================

- (NSArray<PluginDescriptor *> *)loadedPlugins {
    return [self.plugins.allValues copy];
}

- (PluginDescriptor *)pluginNamed:(NSString *)name {
    return self.plugins[name];
}

- (BOOL)isPluginLoaded:(NSString *)name {
    return self.plugins[name] != nil;
}

- (NSInteger)pluginCount {
    return self.plugins.count;
}

// ============================================================================
// MENU INTEGRATION
// ============================================================================

- (NSMenu *)pluginsMenu {
    if (_pluginsMenu) {
        return _pluginsMenu;
    }
    
    // Find or create Plugins menu in main menu bar
    NSMenu *mainMenu = [NSApp mainMenu];
    
    // Look for existing Plugins menu
    for (NSMenuItem *item in mainMenu.itemArray) {
        if ([item.title isEqualToString:@"Plugins"]) {
            _pluginsMenu = item.submenu;
            return _pluginsMenu;
        }
    }
    
    // Create new Plugins menu
    NSMenuItem *pluginsMenuItem = [[NSMenuItem alloc] initWithTitle:@"Plugins"
                                                             action:nil
                                                      keyEquivalent:@""];
    _pluginsMenu = [[NSMenu alloc] initWithTitle:@"Plugins"];
    pluginsMenuItem.submenu = _pluginsMenu;
    
    // Insert before Help menu (usually last)
    NSInteger insertIndex = mainMenu.itemArray.count - 1;
    if (insertIndex < 0) insertIndex = 0;
    [mainMenu insertItem:pluginsMenuItem atIndex:insertIndex];
    
    return _pluginsMenu;
}

- (void)updatePluginsMenu {
    NSMenu *menu = [self pluginsMenu];
    [menu removeAllItems];
    
    if (self.plugins.count == 0) {
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:@"No Plugins Loaded"
                                                      action:nil
                                               keyEquivalent:@""];
        item.enabled = NO;
        [menu addItem:item];
        return;
    }
    
    // Add menu items for each plugin
    NSArray<PluginDescriptor *> *sortedPlugins =
        [self.plugins.allValues sortedArrayUsingComparator:^NSComparisonResult(PluginDescriptor *a, PluginDescriptor *b) {
            return [a.name compare:b.name];
        }];
    
    for (PluginDescriptor *plugin in sortedPlugins) {
        if (plugin.menuItems.count > 0) {
            for (NSMenuItem *item in plugin.menuItems) {
                [menu addItem:item];
            }
            [menu addItem:[NSMenuItem separatorItem]];
        }
    }
    
    // Add Plugin Manager section
    [menu addItem:[NSMenuItem separatorItem]];
    
    NSMenuItem *manageItem = [[NSMenuItem alloc] initWithTitle:@"Plugin Manager..."
                                                        action:@selector(showPluginManager:)
                                                 keyEquivalent:@""];
    manageItem.target = self;
    [menu addItem:manageItem];
}

- (void)addMenuItemsForPlugin:(PluginDescriptor *)plugin {
    NSMutableArray<NSMenuItem *> *menuItems = [NSMutableArray array];
    
    // Create Cocoa menu items from plugin's function array
    for (int i = 0; i < plugin.functions.count && i < MAX_MENU_ITEM_COUNT; i++) {
        PluginMenuItem *funcItem = &plugin.functions.items[i];
        
        NSString *title = [NSString stringWithUTF8String:funcItem->itemName];
        NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:title
                                                          action:@selector(pluginMenuItemSelected:)
                                                   keyEquivalent:@""];
        
        // Store callback pointer in represented object (wrapped in NSValue)
        menuItem.representedObject = [NSValue valueWithPointer:funcItem->callback];
        menuItem.target = self;
        
        // Set keyboard shortcut if specified
        if (funcItem->shortcutKey != 0) {
            unichar key = (unichar)funcItem->shortcutKey;
            menuItem.keyEquivalent = [NSString stringWithCharacters:&key length:1];
            
            NSEventModifierFlags modifiers = 0;
            if (funcItem->cmdKey) modifiers |= NSEventModifierFlagCommand;
            if (funcItem->shiftKey) modifiers |= NSEventModifierFlagShift;
            if (funcItem->altKey) modifiers |= NSEventModifierFlagOption;
            menuItem.keyEquivalentModifierMask = modifiers;
        }
        
        [menuItems addObject:menuItem];
        
        // Add separator after this item if requested
        if (funcItem->separator) {
            [menuItems addObject:[NSMenuItem separatorItem]];
        }
    }
    
    plugin.menuItems = [menuItems copy];
}

- (void)removeMenuItemsForPlugin:(PluginDescriptor *)plugin {
    NSMenu *menu = [self pluginsMenu];
    
    for (NSMenuItem *item in plugin.menuItems) {
        [menu removeItem:item];
    }
    
    plugin.menuItems = @[];
}

- (void)pluginMenuItemSelected:(NSMenuItem *)sender {
    // Extract callback from represented object
    NSValue *value = sender.representedObject;
    if (!value) return;
    
    PluginMenuCallback callback = (PluginMenuCallback)[value pointerValue];
    if (callback) {
        // Call the plugin's menu callback
        callback();
    }
}

- (void)showPluginManager:(id)sender {
    // Display plugin manager window (to be implemented)
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Plugin Manager";
    
    NSMutableString *info = [NSMutableString string];
    [info appendFormat:@"Loaded Plugins: %ld\n\n", (long)self.plugins.count];
    
    for (PluginDescriptor *plugin in [self loadedPlugins]) {
        [info appendFormat:@"%@ v%@\n", plugin.name, plugin.version];
        [info appendFormat:@"Author: %@\n", plugin.author];
        [info appendFormat:@"Description: %@\n\n", plugin.pluginDescription];
    }
    
    alert.informativeText = info;
    [alert addButtonWithTitle:@"OK"];
    [alert runModal];
}

// ============================================================================
// NOTIFICATION DISPATCH
// ============================================================================

- (void)notifyPlugins:(PluginNotification)notification
                 data:(void *)data
             dataSize:(size_t)dataSize {
    
    NotificationData notifyData = {
        .notification = notification,
        .data = data,
        .dataSize = dataSize,
        .canCancel = false,
        .cancelled = false
    };
    
    for (PluginDescriptor *plugin in self.plugins.allValues) {
        if (plugin.pluginBeNotified && plugin.state == PluginStateInitialized) {
            @try {
                plugin.pluginBeNotified(&notifyData);
            } @catch (NSException *exception) {
                NSLog(@"[PluginManager] Exception in plugin %@: %@",
                      plugin.name, exception);
            }
        }
    }
}

- (void)notifyPlugin:(NSString *)pluginName
        notification:(PluginNotification)notification
                data:(void *)data
            dataSize:(size_t)dataSize {
    
    PluginDescriptor *plugin = self.plugins[pluginName];
    if (!plugin || !plugin.pluginBeNotified || plugin.state != PluginStateInitialized) {
        return;
    }
    
    NotificationData notifyData = {
        .notification = notification,
        .data = data,
        .dataSize = dataSize,
        .canCancel = false,
        .cancelled = false
    };
    
    @try {
        plugin.pluginBeNotified(&notifyData);
    } @catch (NSException *exception) {
        NSLog(@"[PluginManager] Exception in plugin %@: %@",
              plugin.name, exception);
    }
}

- (BOOL)notifyPluginsCancellable:(PluginNotification)notification
                            data:(void *)data
                        dataSize:(size_t)dataSize {
    
    NotificationData notifyData = {
        .notification = notification,
        .data = data,
        .dataSize = dataSize,
        .canCancel = true,
        .cancelled = false
    };
    
    for (PluginDescriptor *plugin in self.plugins.allValues) {
        if (plugin.pluginBeNotified && plugin.state == PluginStateInitialized) {
            @try {
                plugin.pluginBeNotified(&notifyData);
                
                // Stop if plugin cancelled the operation
                if (notifyData.cancelled) {
                    NSLog(@"[PluginManager] Operation cancelled by plugin: %@",
                          plugin.name);
                    return NO;
                }
            } @catch (NSException *exception) {
                NSLog(@"[PluginManager] Exception in plugin %@: %@",
                      plugin.name, exception);
            }
        }
    }
    
    return YES; // Not cancelled
}

// ============================================================================
// SCINTILLA INTEGRATION
// ============================================================================

- (void)setScintillaInterface:(const ScintillaInterface *)sci {
    if (!sci) {
        _hasScintilla = NO;
        return;
    }
    
    // Store the current Scintilla interface
    _currentScintilla = *sci;
    _hasScintilla = YES;
    
    // Forward to all plugins that support it
    for (PluginDescriptor *plugin in self.plugins.allValues) {
        if (plugin.pluginSetScintilla && plugin.state == PluginStateInitialized) {
            @try {
                plugin.pluginSetScintilla(sci);
            } @catch (NSException *exception) {
                NSLog(@"[PluginManager] Exception setting Scintilla in plugin %@: %@",
                      plugin.name, exception);
            }
        }
    }
}

@end
