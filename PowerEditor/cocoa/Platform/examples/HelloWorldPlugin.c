//
//  HelloWorldPlugin.c
//  Example plugin for Notepad++ macOS
//
//  Copyright © 2024 Notepad++. All rights reserved.
//
//  This is a minimal example showing how to create a plugin.
//  Build with: clang -dynamiclib -o HelloWorld.dylib HelloWorldPlugin.c -I..
//

#include "../PluginInterface.h"
#include <stdio.h>
#include <string.h>

// ============================================================================
// PLUGIN METADATA
// ============================================================================

DEFINE_PLUGIN_INFO(
    "Hello World",                              // Plugin name
    "1.0.0",                                    // Version
    "Notepad++ Team",                           // Author
    "A simple example plugin that demonstrates the plugin API", // Description
    "https://notepad-plus-plus.org"            // Website
);

// ============================================================================
// PLUGIN STATE
// ============================================================================

static int callCount = 0;
static ScintillaInterface scintilla = {0};
static bool hasScintilla = false;

// ============================================================================
// PLUGIN LIFECYCLE
// ============================================================================

/**
 * Initialize the plugin.
 * Called once when the plugin is loaded.
 */
bool pluginInit(const PluginInfo *info) {
    printf("[HelloWorld] Plugin initialized: %s v%s\n", info->name, info->version);
    callCount = 0;
    return true;
}

/**
 * Cleanup the plugin.
 * Called when the plugin is unloaded or app is shutting down.
 */
void pluginCleanup(void) {
    printf("[HelloWorld] Plugin cleanup (called %d times)\n", callCount);
}

// ============================================================================
// MENU CALLBACKS
// ============================================================================

/**
 * Say hello - simple callback that prints a message.
 */
void sayHello(void) {
    callCount++;
    printf("[HelloWorld] Hello from plugin! (call #%d)\n", callCount);
}

/**
 * Insert text - demonstrates Scintilla integration.
 */
void insertText(void) {
    if (!hasScintilla) {
        printf("[HelloWorld] Scintilla interface not available\n");
        return;
    }
    
    const char *text = "Hello from plugin!\n";
    SCI_SEND(&scintilla, SCI_APPENDTEXT, strlen(text), (intptr_t)text);
    printf("[HelloWorld] Text inserted into document\n");
}

/**
 * Get document info - demonstrates reading from Scintilla.
 */
void getDocInfo(void) {
    if (!hasScintilla) {
        printf("[HelloWorld] Scintilla interface not available\n");
        return;
    }
    
    intptr_t length = SCI_SEND(&scintilla, SCI_GETLENGTH, 0, 0);
    intptr_t lines = SCI_SEND(&scintilla, SCI_GETLINECOUNT, 0, 0);
    intptr_t selStart = SCI_SEND(&scintilla, SCI_GETSELECTIONSTART, 0, 0);
    intptr_t selEnd = SCI_SEND(&scintilla, SCI_GETSELECTIONEND, 0, 0);
    
    printf("[HelloWorld] Document info:\n");
    printf("  Length: %ld bytes\n", (long)length);
    printf("  Lines: %ld\n", (long)lines);
    printf("  Selection: %ld to %ld (%ld bytes)\n",
           (long)selStart, (long)selEnd, (long)(selEnd - selStart));
}

/**
 * About - show plugin information.
 */
void showAbout(void) {
    printf("[HelloWorld] About:\n");
    printf("  Name: Hello World Plugin\n");
    printf("  Version: 1.0.0\n");
    printf("  Author: Notepad++ Team\n");
    printf("  API Version: %d\n", PLUGIN_API_VERSION);
}

// ============================================================================
// MENU DEFINITION
// ============================================================================

/**
 * Get the plugin's menu items.
 * These will appear in the Plugins menu.
 */
void pluginGetFunctions(PluginFunctionArray *funcs) {
    funcs->count = 4;
    
    // Menu item 1: Say Hello
    strcpy(funcs->items[0].itemName, "Say Hello");
    funcs->items[0].callback = sayHello;
    funcs->items[0].shortcutKey = 'h';        // Cmd+H
    funcs->items[0].cmdKey = true;
    funcs->items[0].shiftKey = false;
    funcs->items[0].altKey = false;
    funcs->items[0].separator = false;
    
    // Menu item 2: Insert Text
    strcpy(funcs->items[1].itemName, "Insert Hello");
    funcs->items[1].callback = insertText;
    funcs->items[1].shortcutKey = 'i';        // Cmd+I
    funcs->items[1].cmdKey = true;
    funcs->items[1].shiftKey = false;
    funcs->items[1].altKey = false;
    funcs->items[1].separator = false;
    
    // Menu item 3: Get Document Info
    strcpy(funcs->items[2].itemName, "Document Info");
    funcs->items[2].callback = getDocInfo;
    funcs->items[2].shortcutKey = 0;          // No shortcut
    funcs->items[2].cmdKey = false;
    funcs->items[2].shiftKey = false;
    funcs->items[2].altKey = false;
    funcs->items[2].separator = true;         // Separator after this item
    
    // Menu item 4: About
    strcpy(funcs->items[3].itemName, "About Hello World");
    funcs->items[3].callback = showAbout;
    funcs->items[3].shortcutKey = 0;          // No shortcut
    funcs->items[3].cmdKey = false;
    funcs->items[3].shiftKey = false;
    funcs->items[3].altKey = false;
    funcs->items[3].separator = false;
}

// ============================================================================
// NOTIFICATION HANDLER
// ============================================================================

/**
 * Handle notifications from the editor.
 * Called when various events occur.
 */
void pluginBeNotified(NotificationData *notification) {
    switch (notification->notification) {
        case PN_READY:
            printf("[HelloWorld] Plugin system ready\n");
            break;
            
        case PN_SHUTDOWN:
            printf("[HelloWorld] Application shutting down\n");
            break;
            
        case PN_FILE_OPENED:
            if (notification->data) {
                printf("[HelloWorld] File opened: %s\n", (const char*)notification->data);
            }
            break;
            
        case PN_FILE_CLOSED:
            if (notification->data) {
                printf("[HelloWorld] File closed: %s\n", (const char*)notification->data);
            }
            break;
            
        case PN_FILE_SAVED:
            if (notification->data) {
                printf("[HelloWorld] File saved: %s\n", (const char*)notification->data);
            }
            break;
            
        case PN_FILE_BEFORE_SAVE:
            if (notification->data) {
                printf("[HelloWorld] About to save: %s\n", (const char*)notification->data);
            }
            // Could set notification->cancelled = true to prevent save
            break;
            
        case PN_BUFFER_ACTIVATED:
            printf("[HelloWorld] Buffer activated\n");
            break;
            
        case PN_LANGUAGE_CHANGED:
            if (notification->data) {
                printf("[HelloWorld] Language changed to: %s\n", (const char*)notification->data);
            }
            break;
            
        case PN_DOCUMENT_MODIFIED:
            printf("[HelloWorld] Document was modified\n");
            break;
            
        case PN_SELECTION_CHANGED:
            printf("[HelloWorld] Selection changed\n");
            break;
            
        case PN_SCINTILLA_NOTIFY:
            // Handle Scintilla notifications if needed
            break;
            
        default:
            break;
    }
}

// ============================================================================
// OPTIONAL: SCINTILLA INTEGRATION
// ============================================================================

/**
 * Receive Scintilla interface.
 * This is optional - only implement if you need direct editor access.
 */
void pluginSetScintilla(const ScintillaInterface *sci) {
    if (sci) {
        scintilla = *sci;
        hasScintilla = true;
        printf("[HelloWorld] Scintilla interface received\n");
    } else {
        hasScintilla = false;
        printf("[HelloWorld] Scintilla interface cleared\n");
    }
}

// ============================================================================
// OPTIONAL: SETTINGS UI
// ============================================================================

/**
 * Show settings dialog.
 * This is optional - only implement if your plugin has settings.
 */
void pluginShowSettings(void) {
    printf("[HelloWorld] Settings dialog (not implemented)\n");
    printf("  This plugin has no configurable settings.\n");
}
