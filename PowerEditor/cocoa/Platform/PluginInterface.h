//
//  PluginInterface.h
//  Notepad++ macOS Plugin System
//
//  Copyright © 2024 Notepad++. All rights reserved.
//
//  This file defines the public C interface that all Notepad++ plugins must implement.
//  Plugins are dynamically loaded shared libraries (.dylib) that extend the editor's functionality.
//

#ifndef PluginInterface_h
#define PluginInterface_h

#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

// Plugin API version - increment when breaking changes are made
#define PLUGIN_API_VERSION 1

// Maximum lengths for plugin metadata
#define MAX_PLUGIN_NAME_LENGTH 64
#define MAX_FUNCTION_NAME_LENGTH 64
#define MAX_MENU_ITEM_COUNT 32

// Forward declarations for Scintilla integration
typedef void* ScintillaObject;
typedef intptr_t (*SciFnDirect)(void*, unsigned int, uintptr_t, intptr_t);

/**
 * Plugin notification codes.
 * These are sent to plugins via the beNotified() callback to inform them
 * of various events occurring in the editor.
 */
typedef enum {
    PN_READY = 1,                    // Plugin system is initialized
    PN_SHUTDOWN,                     // Application is shutting down
    PN_FILE_OPENED,                  // A file was opened
    PN_FILE_CLOSED,                  // A file was closed
    PN_FILE_SAVED,                   // A file was saved
    PN_FILE_BEFORE_SAVE,            // About to save a file (can cancel)
    PN_BUFFER_ACTIVATED,            // User switched to a different buffer
    PN_LANGUAGE_CHANGED,            // Document language/syntax changed
    PN_DOCUMENT_MODIFIED,           // Document content was modified
    PN_SELECTION_CHANGED,           // Text selection changed
    PN_SCINTILLA_NOTIFY             // Scintilla notification (see notifyData)
} PluginNotification;

/**
 * Plugin notification data structure.
 * Contains information about the notification being sent to the plugin.
 */
typedef struct {
    PluginNotification notification;  // Type of notification
    void *data;                       // Additional data (notification-specific)
    size_t dataSize;                  // Size of data in bytes
    bool canCancel;                   // Whether this notification can be cancelled
    bool cancelled;                   // Set to true to cancel the operation
} NotificationData;

/**
 * Menu item function callback.
 * This function is called when the user selects the menu item.
 */
typedef void (*PluginMenuCallback)(void);

/**
 * Menu item definition.
 * Each plugin can register multiple menu items that appear in the Plugins menu.
 */
typedef struct {
    char itemName[MAX_FUNCTION_NAME_LENGTH];  // Display name in menu
    PluginMenuCallback callback;               // Function to call when selected
    int shortcutKey;                          // Keyboard shortcut (0 = none)
    bool shiftKey;                            // Requires Shift modifier
    bool cmdKey;                              // Requires Command modifier
    bool altKey;                              // Requires Option/Alt modifier
    bool separator;                           // Show separator after this item
} PluginMenuItem;

/**
 * Plugin function array.
 * Contains all menu items that this plugin provides.
 */
typedef struct {
    int count;                                     // Number of menu items
    PluginMenuItem items[MAX_MENU_ITEM_COUNT];   // Array of menu items
} PluginFunctionArray;

/**
 * Plugin information structure.
 * Contains metadata about the plugin.
 */
typedef struct {
    int apiVersion;                           // Plugin API version (use PLUGIN_API_VERSION)
    char name[MAX_PLUGIN_NAME_LENGTH];       // Plugin name
    char version[32];                         // Plugin version string
    char author[64];                          // Plugin author
    char description[256];                    // Short description
    char website[128];                        // Plugin website URL
} PluginInfo;

/**
 * Scintilla editor interface.
 * Provides access to the Scintilla editor for direct manipulation.
 */
typedef struct {
    ScintillaObject scintilla;     // Opaque Scintilla object handle
    SciFnDirect directFunction;    // Direct function pointer for message passing
    void *directPointer;           // Direct pointer for message passing
} ScintillaInterface;

// ============================================================================
// REQUIRED PLUGIN EXPORTS
// All plugins MUST export these functions for the plugin manager to load them.
// ============================================================================

/**
 * Get plugin information.
 * Called immediately after the plugin is loaded to retrieve metadata.
 * 
 * @param info Pointer to PluginInfo structure to fill
 */
void pluginGetInfo(PluginInfo *info);

/**
 * Initialize the plugin.
 * Called once when the plugin is loaded. Perform all initialization here.
 * 
 * @param info Plugin information filled by pluginGetInfo()
 * @return true if initialization succeeded, false otherwise
 */
bool pluginInit(const PluginInfo *info);

/**
 * Cleanup the plugin.
 * Called when the plugin is being unloaded or application is shutting down.
 * Free all resources allocated by the plugin.
 */
void pluginCleanup(void);

/**
 * Get the plugin's menu items.
 * Called to populate the Plugins menu with this plugin's commands.
 * 
 * @param funcs Pointer to PluginFunctionArray to fill
 */
void pluginGetFunctions(PluginFunctionArray *funcs);

/**
 * Notification callback.
 * Called when events occur in the editor that the plugin may want to respond to.
 * 
 * @param notification Pointer to notification data structure
 */
void pluginBeNotified(NotificationData *notification);

// ============================================================================
// OPTIONAL PLUGIN EXPORTS
// Plugins may export these functions for additional functionality.
// ============================================================================

/**
 * Set Scintilla editor interface.
 * Called to provide the plugin with direct access to the Scintilla editor.
 * This is optional - only implement if your plugin needs direct editor access.
 * 
 * @param sci Pointer to ScintillaInterface structure
 */
void pluginSetScintilla(const ScintillaInterface *sci);

/**
 * Display plugin settings/preferences dialog.
 * Called when user selects "Configure" for this plugin.
 * This is optional - only implement if your plugin has configurable settings.
 */
void pluginShowSettings(void);

// ============================================================================
// HELPER MACROS FOR PLUGIN DEVELOPMENT
// ============================================================================

/**
 * Convenience macro to send a Scintilla message.
 * Usage: SCI_SEND(sci, SCI_GETLENGTH, 0, 0)
 */
#define SCI_SEND(sci, msg, wParam, lParam) \
    ((sci)->directFunction((sci)->directPointer, (msg), (wParam), (lParam)))

/**
 * Macro to declare a plugin with proper exports.
 * Use this at the beginning of your plugin source file.
 */
#define DECLARE_PLUGIN(name) \
    __attribute__((visibility("default"))) \
    static const char* _plugin_name = name;

/**
 * Macro to define plugin information.
 * Automatically implements pluginGetInfo() with provided metadata.
 */
#define DEFINE_PLUGIN_INFO(name, ver, auth, desc, url) \
    void pluginGetInfo(PluginInfo *info) { \
        info->apiVersion = PLUGIN_API_VERSION; \
        strncpy(info->name, name, MAX_PLUGIN_NAME_LENGTH - 1); \
        strncpy(info->version, ver, 31); \
        strncpy(info->author, auth, 63); \
        strncpy(info->description, desc, 255); \
        strncpy(info->website, url, 127); \
    }

// ============================================================================
// COMMON SCINTILLA MESSAGE CODES
// Include a subset of frequently used Scintilla messages for convenience.
// For complete list, see Scintilla documentation.
// ============================================================================

// Text retrieval and modification
#define SCI_GETTEXT 2182
#define SCI_SETTEXT 2181
#define SCI_GETLENGTH 2006
#define SCI_GETSELTEXT 2161
#define SCI_REPLACESEL 2170
#define SCI_APPENDTEXT 2282

// Selection and cursor
#define SCI_GETSELECTIONSTART 2143
#define SCI_GETSELECTIONEND 2145
#define SCI_SETSELECTIONSTART 2142
#define SCI_SETSELECTIONEND 2144
#define SCI_GETCURRENTPOS 2008
#define SCI_SETCURRENTPOS 2141

// File operations
#define SCI_GETMODIFY 2159
#define SCI_SETSAVEPOINT 2014

// Undo/Redo
#define SCI_UNDO 2176
#define SCI_REDO 2011
#define SCI_CANUNDO 2174
#define SCI_CANREDO 2016
#define SCI_EMPTYUNDOBUFFER 2175

// Line operations
#define SCI_GETLINECOUNT 2154
#define SCI_LINEFROMPOSITION 2166
#define SCI_POSITIONFROMLINE 2167
#define SCI_GETLINE 2153
#define SCI_GETLINEENDPOSITION 2136

// Search
#define SCI_SEARCHNEXT 2367
#define SCI_SEARCHPREV 2368
#define SCI_FINDTEXT 2150
#define SCI_REPLACETARGET 2194

#ifdef __cplusplus
}
#endif

#endif /* PluginInterface_h */
