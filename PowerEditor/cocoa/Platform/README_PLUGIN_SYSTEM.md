# Notepad++ macOS Plugin System

## Overview

The Notepad++ macOS plugin system provides a robust, extensible architecture for adding functionality through dynamically loaded plugins. The system is designed with security, stability, and ease of use in mind.

## Architecture

### Component Overview

```
┌─────────────────────────────────────────────────────────┐
│                    Notepad++ macOS                      │
│  ┌───────────────────────────────────────────────────┐  │
│  │              PluginManager (Singleton)            │  │
│  │  - Discovery & Loading                            │  │
│  │  - Code Signature Verification                    │  │
│  │  - Lifecycle Management                           │  │
│  │  - Menu Integration                               │  │
│  │  - Notification Dispatch                          │  │
│  └───────────────────────────────────────────────────┘  │
│                          │                              │
│          ┌───────────────┼───────────────┐              │
│          │               │               │              │
│  ┌───────▼──────┐ ┌──────▼──────┐ ┌─────▼──────┐      │
│  │   Plugin 1   │ │   Plugin 2  │ │  Plugin N  │      │
│  │   (.dylib)   │ │   (.dylib)  │ │  (.dylib)  │      │
│  └──────────────┘ └─────────────┘ └────────────┘      │
└─────────────────────────────────────────────────────────┘
```

### Key Components

1. **PluginInterface.h** - C API definition for plugins
   - Defines all structures, callbacks, and constants
   - Provides helper macros for plugin development
   - Platform-independent interface

2. **PluginManager.h** - Singleton manager interface
   - Discovery and loading APIs
   - Lifecycle management
   - Security verification
   - Menu integration

3. **PluginManager.mm** - Implementation
   - Dynamic loading using `dlopen`/`dlsym`
   - Code signature verification using Security framework
   - Thread-safe operations
   - Error handling and logging

## Plugin Lifecycle

```
┌─────────────┐
│  Discovery  │  Scan ~/Library/Application Support/Notepad++/plugins/
└──────┬──────┘
       │
       ▼
┌─────────────┐
│Verification │  Validate code signature (macOS Security.framework)
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   Loading   │  dlopen() - Load the .dylib into memory
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   Symbol    │  dlsym() - Resolve function pointers
│ Resolution  │  (pluginInit, pluginGetInfo, etc.)
└──────┬──────┘
       │
       ▼
┌─────────────┐
│    Init     │  Call pluginInit() - Let plugin initialize
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ Integration │  Add menu items, register callbacks
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  Operation  │  Plugin is active, receives notifications
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   Cleanup   │  pluginCleanup() + dlclose() on shutdown
└─────────────┘
```

## Plugin Directory Structure

Plugins are loaded from:
```
~/Library/Application Support/Notepad++/plugins/
├── MyPlugin.dylib
├── AnotherPlugin.dylib
└── ThirdPlugin.dylib
```

## Security Model

### Code Signature Verification

All plugins **must** be code-signed to be loaded (can be disabled for development):

```objective-c
// Enable/disable verification
[[PluginManager sharedManager] setCodeSignatureVerificationEnabled:YES];

// Check status
BOOL enabled = [[PluginManager sharedManager] isCodeSignatureVerificationEnabled];
```

### Verification Process

1. Uses macOS `Security.framework` (`SecStaticCode` APIs)
2. Validates code signature before loading
3. Checks all architectures (`kSecCSCheckAllArchitectures`)
4. Rejects tampered or unsigned plugins

### Developer Signing

For development:

```bash
# Self-sign your plugin
codesign -s "My Developer ID" MyPlugin.dylib

# Verify signature
codesign -v MyPlugin.dylib
```

### Production Signing

For distribution:
- Use Apple Developer ID certificate
- Notarize plugin bundles
- Consider team ID verification for enterprise

## Creating a Plugin

### Minimal Plugin Example

```c
#include "PluginInterface.h"
#include <string.h>

// Define plugin metadata
DEFINE_PLUGIN_INFO(
    "Hello World",                    // Name
    "1.0",                           // Version
    "Your Name",                     // Author
    "A simple hello world plugin",   // Description
    "https://example.com"            // Website
);

// Initialize plugin
bool pluginInit(const PluginInfo *info) {
    // Perform initialization
    return true;
}

// Cleanup plugin
void pluginCleanup(void) {
    // Free resources
}

// Menu callback
void sayHello(void) {
    printf("Hello from plugin!\n");
}

// Define menu items
void pluginGetFunctions(PluginFunctionArray *funcs) {
    funcs->count = 1;
    
    strcpy(funcs->items[0].itemName, "Say Hello");
    funcs->items[0].callback = sayHello;
    funcs->items[0].shortcutKey = 'h';
    funcs->items[0].cmdKey = true;
    funcs->items[0].shiftKey = false;
    funcs->items[0].altKey = false;
    funcs->items[0].separator = false;
}

// Handle notifications
void pluginBeNotified(NotificationData *notification) {
    switch (notification->notification) {
        case PN_READY:
            printf("Plugin system ready!\n");
            break;
        case PN_FILE_OPENED:
            printf("File was opened\n");
            break;
        case PN_SHUTDOWN:
            printf("Shutting down\n");
            break;
        default:
            break;
    }
}
```

### Building a Plugin

```bash
# Compile as shared library
clang -dynamiclib \
      -o MyPlugin.dylib \
      MyPlugin.c \
      -I/path/to/PowerEditor/cocoa/Platform \
      -fvisibility=default \
      -framework Cocoa

# Sign the plugin
codesign -s "Developer ID" MyPlugin.dylib

# Install plugin
cp MyPlugin.dylib ~/Library/Application\ Support/Notepad++/plugins/
```

### Using Scintilla API

For direct editor manipulation:

```c
// Optional: Receive Scintilla interface
void pluginSetScintilla(const ScintillaInterface *sci) {
    // Get document length
    intptr_t length = SCI_SEND(sci, SCI_GETLENGTH, 0, 0);
    
    // Get text
    char *text = malloc(length + 1);
    SCI_SEND(sci, SCI_GETTEXT, length + 1, (intptr_t)text);
    
    // Modify text
    SCI_SEND(sci, SCI_SETTEXT, 0, (intptr_t)"New text");
    
    free(text);
}
```

## Loading Plugins Programmatically

### From Application Code

```objective-c
#import "PluginManager.h"

// Get shared instance
PluginManager *manager = [PluginManager sharedManager];

// Load all plugins from standard directory
NSError *error = nil;
NSInteger count = [manager loadAllPluginsWithError:&error];
if (error) {
    NSLog(@"Failed to load plugins: %@", error);
}

// Load specific plugin
NSURL *pluginURL = [NSURL fileURLWithPath:@"/path/to/plugin.dylib"];
PluginDescriptor *plugin = [manager loadPluginAtURL:pluginURL error:&error];

// Get loaded plugins
NSArray<PluginDescriptor *> *plugins = [manager loadedPlugins];
for (PluginDescriptor *p in plugins) {
    NSLog(@"Loaded: %@ v%@ by %@", p.name, p.version, p.author);
}

// Unload a plugin
[manager unloadPlugin:@"MyPlugin"];
```

### Sending Notifications

```objective-c
// Notify all plugins of an event
[[PluginManager sharedManager] notifyPlugins:PN_FILE_OPENED
                                        data:NULL
                                    dataSize:0];

// Cancellable notification
BOOL proceed = [[PluginManager sharedManager] 
                notifyPluginsCancellable:PN_FILE_BEFORE_SAVE
                                    data:NULL
                                dataSize:0];
if (!proceed) {
    // Plugin cancelled the save operation
}

// Notify specific plugin
[[PluginManager sharedManager] notifyPlugin:@"MyPlugin"
                               notification:PN_DOCUMENT_MODIFIED
                                       data:NULL
                                   dataSize:0];
```

### Setting Scintilla Interface

```objective-c
ScintillaInterface sci = {
    .scintilla = scintillaObject,
    .directFunction = directFunc,
    .directPointer = directPtr
};

[[PluginManager sharedManager] setScintillaInterface:&sci];
```

## API Reference

### Required Plugin Exports

Every plugin **must** export these functions:

- `void pluginGetInfo(PluginInfo *info)` - Return plugin metadata
- `bool pluginInit(const PluginInfo *info)` - Initialize plugin
- `void pluginCleanup(void)` - Clean up resources
- `void pluginGetFunctions(PluginFunctionArray *funcs)` - Return menu items
- `void pluginBeNotified(NotificationData *notification)` - Handle notifications

### Optional Plugin Exports

- `void pluginSetScintilla(const ScintillaInterface *sci)` - Receive Scintilla access
- `void pluginShowSettings(void)` - Display settings UI

### Notification Types

| Notification | Description | Data |
|--------------|-------------|------|
| `PN_READY` | Plugin system initialized | NULL |
| `PN_SHUTDOWN` | Application shutting down | NULL |
| `PN_FILE_OPENED` | File was opened | File path (char*) |
| `PN_FILE_CLOSED` | File was closed | File path (char*) |
| `PN_FILE_SAVED` | File was saved | File path (char*) |
| `PN_FILE_BEFORE_SAVE` | About to save (cancellable) | File path (char*) |
| `PN_BUFFER_ACTIVATED` | User switched buffers | Buffer ID (int*) |
| `PN_LANGUAGE_CHANGED` | Syntax language changed | Language name (char*) |
| `PN_DOCUMENT_MODIFIED` | Content was modified | NULL |
| `PN_SELECTION_CHANGED` | Selection changed | NULL |
| `PN_SCINTILLA_NOTIFY` | Scintilla notification | SCNotification* |

## Thread Safety

- All plugin callbacks execute on the **main thread**
- Plugins should not block the main thread
- Use GCD or NSOperationQueue for background work:

```c
void myCallback(void) {
    // Quick UI update - OK on main thread
    
    // Long operation - dispatch to background
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Do heavy work here
        
        dispatch_async(dispatch_get_main_queue(), ^{
            // Update UI on main thread
        });
    });
}
```

## Error Handling

### Error Codes

- `PluginManagerErrorCodeNotFound` - Plugin file not found
- `PluginManagerErrorCodeInvalidFormat` - Invalid plugin format
- `PluginManagerErrorCodeSignatureInvalid` - Code signature verification failed
- `PluginManagerErrorCodeMissingSymbol` - Required function not exported
- `PluginManagerErrorCodeInitializationFailed` - pluginInit() returned false
- `PluginManagerErrorCodeAlreadyLoaded` - Plugin already loaded
- `PluginManagerErrorCodeVersionMismatch` - Incompatible API version
- `PluginManagerErrorCodeLoadFailed` - dlopen() failed

### Handling Errors

```objective-c
NSError *error = nil;
PluginDescriptor *plugin = [manager loadPluginAtURL:url error:&error];

if (!plugin) {
    switch (error.code) {
        case PluginManagerErrorCodeSignatureInvalid:
            // Handle signature error
            break;
        case PluginManagerErrorCodeVersionMismatch:
            // Handle version mismatch
            break;
        default:
            NSLog(@"Failed to load plugin: %@", error.localizedDescription);
    }
}
```

## Best Practices

### Plugin Development

1. **Always validate inputs** - Don't trust external data
2. **Handle errors gracefully** - Don't crash the host app
3. **Clean up resources** - Free memory in pluginCleanup()
4. **Use versioning** - Update version string for each release
5. **Document features** - Provide clear descriptions
6. **Test thoroughly** - Test with multiple Notepad++ versions

### Performance

1. **Keep callbacks fast** - Don't block the main thread
2. **Cache expensive computations** - Store results when possible
3. **Lazy initialize** - Only allocate resources when needed
4. **Profile your plugin** - Use Instruments to find bottlenecks

### Security

1. **Validate file paths** - Check for path traversal attacks
2. **Sanitize user input** - Prevent injection attacks
3. **Use secure APIs** - Avoid deprecated/unsafe functions
4. **Sign your plugins** - Use valid developer certificate

## Debugging

### Enable Verbose Logging

```objective-c
// Development mode - disable signature verification
[[PluginManager sharedManager] setCodeSignatureVerificationEnabled:NO];
```

### Check Plugin State

```objective-c
PluginDescriptor *plugin = [manager pluginNamed:@"MyPlugin"];
NSLog(@"State: %ld", (long)plugin.state);
NSLog(@"Error: %@", plugin.lastError);
```

### Console Output

Check Console.app for plugin system logs:
```
[PluginManager] Initialized
[PluginManager] Discovered 3 plugin(s)
[PluginManager] Loading plugin: MyPlugin.dylib
[PluginManager] Code signature verification passed
[PluginManager] Successfully loaded plugin: MyPlugin v1.0 by Author
```

## Migration from Windows Plugins

Windows Notepad++ plugins use a different API. Key differences:

| Windows | macOS |
|---------|-------|
| DLL (.dll) | Dynamic Library (.dylib) |
| Windows API | Cocoa/Foundation |
| TCHAR* strings | char* (UTF-8) |
| HWND handles | Opaque pointers |
| Registry for settings | NSUserDefaults |

### Porting Checklist

- [ ] Replace Windows API calls with POSIX/macOS equivalents
- [ ] Convert TCHAR strings to UTF-8 char*
- [ ] Replace registry access with NSUserDefaults
- [ ] Update build system for macOS (clang, frameworks)
- [ ] Add code signing
- [ ] Test on macOS (Big Sur, Monterey, Ventura, Sonoma)

## Examples

See the `examples/` directory for complete plugin examples:

- **HelloWorld** - Minimal plugin
- **TextTools** - Scintilla integration
- **FileWatcher** - Notification handling
- **Preferences** - Settings dialog

## Troubleshooting

### Plugin Not Loading

1. Check code signature: `codesign -v MyPlugin.dylib`
2. Check for missing symbols: `nm -g MyPlugin.dylib | grep plugin`
3. Check Console.app for error messages
4. Verify plugin is in correct directory
5. Try disabling signature verification (development only)

### Crashes

1. Run in debugger (Xcode)
2. Check for memory issues (leaks, use-after-free)
3. Verify all callbacks are implemented
4. Check thread safety (main thread only)

### API Version Mismatch

```
Plugin API version 2 is not compatible with version 1
```

Update your plugin to use the current API version:
```c
info->apiVersion = PLUGIN_API_VERSION; // Use macro, not hardcoded value
```

## Contributing

Contributions welcome! Please:

1. Follow the coding style
2. Add tests for new features
3. Update documentation
4. Submit pull requests to the main repository

## License

Copyright © 2024 Notepad++. All rights reserved.

Plugin system is part of Notepad++ macOS and follows the same license as the main application.

## Support

- **Documentation**: This file and header comments
- **Issues**: GitHub Issues
- **Discussions**: GitHub Discussions
- **Website**: https://notepad-plus-plus.org
