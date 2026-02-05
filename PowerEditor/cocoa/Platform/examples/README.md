# Plugin Examples

This directory contains example plugins demonstrating the Notepad++ macOS plugin system.

## Available Examples

### HelloWorldPlugin.c

A minimal plugin that demonstrates:
- Basic plugin structure and lifecycle
- Menu item registration
- Keyboard shortcuts
- Notification handling
- Scintilla editor integration
- Plugin settings (stub)

## Building the Examples

### Prerequisites

- Xcode Command Line Tools (for clang compiler)
- macOS 10.14 or later

Install command line tools:
```bash
xcode-select --install
```

### Build

```bash
cd examples
make
```

This will create `HelloWorld.dylib` in the current directory.

### Sign (Optional but Recommended)

Ad-hoc signing (for development):
```bash
make sign
```

Or sign with your Developer ID:
```bash
codesign -s "Developer ID Application: Your Name (TEAMID)" HelloWorld.dylib
```

### Install

```bash
make install
```

This copies the plugin to `~/Library/Application Support/Notepad++/plugins/`

### Verify

Check that the plugin is valid:
```bash
make verify
```

Output should show:
- File type (Mach-O dynamic library)
- Exported symbols (pluginInit, pluginGetInfo, etc.)
- Code signature status

### Clean

Remove build artifacts:
```bash
make clean
```

### Development Workflow

Build, sign, and install in one command:
```bash
make dev
```

## Using the Plugin

1. Build and install the plugin (see above)
2. Launch Notepad++ macOS
3. Check the Plugins menu - you should see "Hello World" submenu
4. Select menu items to test functionality:
   - **Say Hello** (⌘H) - Prints to console
   - **Insert Hello** (⌘I) - Inserts text into document
   - **Document Info** - Shows document statistics
   - **About Hello World** - Shows plugin info

## Debugging

### Console Output

View plugin messages in Console.app:
```bash
# Filter for plugin messages
log stream --predicate 'process == "Notepad++"' --level debug
```

Or run Notepad++ from Terminal to see output:
```bash
/Applications/Notepad++.app/Contents/MacOS/Notepad++
```

### Common Issues

**Plugin not loading:**
- Check code signature: `codesign -v HelloWorld.dylib`
- Verify it's in the correct directory
- Check Console.app for error messages
- Try disabling signature verification in development

**Missing symbols:**
- Verify exports: `nm -g HelloWorld.dylib | grep plugin`
- Make sure all required functions are implemented
- Check function signatures match exactly

**Crashes:**
- Run in debugger (lldb)
- Check for memory errors
- Verify all callbacks are implemented correctly
- Make sure plugin cleans up resources properly

## Extending the Example

### Add More Menu Items

Increase count and add items to `pluginGetFunctions()`:

```c
void pluginGetFunctions(PluginFunctionArray *funcs) {
    funcs->count = 5;  // Increase count
    
    // ... existing items ...
    
    // New item
    strcpy(funcs->items[4].itemName, "My New Command");
    funcs->items[4].callback = myNewCallback;
    funcs->items[4].shortcutKey = 'n';
    funcs->items[4].cmdKey = true;
    // ... etc ...
}
```

### Handle More Notifications

Add cases to `pluginBeNotified()`:

```c
void pluginBeNotified(NotificationData *notification) {
    switch (notification->notification) {
        case PN_FILE_OPENED:
            // Your code here
            break;
        // ... etc ...
    }
}
```

### Use Scintilla API

Access the editor directly:

```c
void myEditorFunction(void) {
    if (!hasScintilla) return;
    
    // Get text length
    intptr_t len = SCI_SEND(&scintilla, SCI_GETLENGTH, 0, 0);
    
    // Allocate buffer
    char *text = malloc(len + 1);
    
    // Get all text
    SCI_SEND(&scintilla, SCI_GETTEXT, len + 1, (intptr_t)text);
    
    // Do something with text...
    
    free(text);
}
```

### Add Settings

Implement `pluginShowSettings()`:

```c
void pluginShowSettings(void) {
    // Display settings UI using Cocoa
    // Save settings using NSUserDefaults
}
```

## Next Steps

- Read the main [Plugin System README](../README_PLUGIN_SYSTEM.md)
- Study the [PluginInterface.h](../PluginInterface.h) API
- Check [Scintilla documentation](https://www.scintilla.org/ScintillaDoc.html) for editor API
- Create your own plugin!

## License

These examples are part of Notepad++ and follow the same license.
Copyright © 2024 Notepad++. All rights reserved.
