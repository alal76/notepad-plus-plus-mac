# Quick Action Extension - Integration Guide

This document provides a quick reference for integrating the Quick Action extension into your existing Notepad++ Xcode project.

## Directory Structure

```
PowerEditor/cocoa/Extensions/QuickAction/
├── README.md                          # Main documentation
├── BUILD_CONFIGURATION.md             # Detailed Xcode setup guide
├── INTEGRATION_GUIDE.md              # This file
├── Info.plist                        # Extension configuration
├── ActionViewController.h            # Extension interface
├── ActionViewController.mm           # Extension implementation
├── Action.js                         # Web integration script
└── NotepadQuickAction.entitlements  # Security entitlements
```

## Quick Integration Steps

### For Existing Xcode Project

1. **Add Extension Target** (in Xcode):
   ```
   File → New → Target → Application Extension → Action Extension
   Name: NotepadQuickAction
   ```

2. **Add Files to Extension Target**:
   - Add all .h, .mm, .js files from this directory
   - Replace the default Info.plist with ours
   - Add NotepadQuickAction.entitlements to target

3. **Embed Extension**:
   - Select main app target
   - General → Embedded Binaries → Add NotepadQuickAction.appex

4. **Build and Test**:
   ```bash
   xcodebuild -scheme Notepad++ -configuration Debug
   ```

### For Command-Line/Makefile Builds

If you're building without Xcode, you'll need to:

1. Compile the extension separately:
   ```bash
   clang++ -framework Cocoa -framework Foundation \
     -o NotepadQuickAction \
     ActionViewController.mm \
     -mmacosx-version-min=10.15
   ```

2. Create the extension bundle structure:
   ```bash
   mkdir -p NotepadQuickAction.appex/Contents/{MacOS,Resources}
   cp NotepadQuickAction NotepadQuickAction.appex/Contents/MacOS/
   cp Info.plist NotepadQuickAction.appex/Contents/
   cp Action.js NotepadQuickAction.appex/Contents/Resources/
   ```

3. Embed in main app:
   ```bash
   mkdir -p Notepad++.app/Contents/PlugIns
   cp -R NotepadQuickAction.appex Notepad++.app/Contents/PlugIns/
   ```

## Build Configuration Files

### Xcode Build Settings

If you have a `.xcodeproj`, add these settings to the extension target:

**Info.plist Preprocessing**:
```
INFOPLIST_FILE = PowerEditor/cocoa/Extensions/QuickAction/Info.plist
INFOPLIST_PREPROCESS = YES
```

**Compiler Flags**:
```
OTHER_CPLUSPLUSFLAGS = -std=c++17
CLANG_CXX_LANGUAGE_STANDARD = c++17
GCC_C_LANGUAGE_STANDARD = c11
```

**Linking**:
```
FRAMEWORK_SEARCH_PATHS = $(inherited) $(SYSTEM_LIBRARY_DIR)/Frameworks
OTHER_LDFLAGS = -framework Cocoa -framework Foundation
```

**Entitlements**:
```
CODE_SIGN_ENTITLEMENTS = PowerEditor/cocoa/Extensions/QuickAction/NotepadQuickAction.entitlements
```

### CMake Configuration

If using CMake, add to your `CMakeLists.txt`:

```cmake
# Quick Action Extension
set(QUICKACTION_SOURCES
    PowerEditor/cocoa/Extensions/QuickAction/ActionViewController.mm
)

set(QUICKACTION_HEADERS
    PowerEditor/cocoa/Extensions/QuickAction/ActionViewController.h
)

set(QUICKACTION_RESOURCES
    PowerEditor/cocoa/Extensions/QuickAction/Action.js
    PowerEditor/cocoa/Extensions/QuickAction/Info.plist
)

# Create the extension bundle
add_library(NotepadQuickAction MODULE ${QUICKACTION_SOURCES})
target_sources(NotepadQuickAction PRIVATE ${QUICKACTION_HEADERS})

# Link frameworks
target_link_libraries(NotepadQuickAction
    "-framework Cocoa"
    "-framework Foundation"
)

# Set bundle properties
set_target_properties(NotepadQuickAction PROPERTIES
    BUNDLE TRUE
    BUNDLE_EXTENSION "appex"
    MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_SOURCE_DIR}/PowerEditor/cocoa/Extensions/QuickAction/Info.plist"
    MACOSX_BUNDLE_BUNDLE_NAME "NotepadQuickAction"
    MACOSX_BUNDLE_BUNDLE_VERSION "1.0"
    MACOSX_BUNDLE_SHORT_VERSION_STRING "1.0"
)

# Copy resources to bundle
add_custom_command(TARGET NotepadQuickAction POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy
        "${CMAKE_CURRENT_SOURCE_DIR}/PowerEditor/cocoa/Extensions/QuickAction/Action.js"
        "$<TARGET_BUNDLE_DIR:NotepadQuickAction>/Contents/Resources/Action.js"
)

# Install extension into main app bundle
install(TARGETS NotepadQuickAction
    BUNDLE DESTINATION Notepad++.app/Contents/PlugIns
)
```

### Makefile Configuration

For traditional Makefiles:

```makefile
# Quick Action Extension
QUICKACTION_NAME = NotepadQuickAction
QUICKACTION_DIR = PowerEditor/cocoa/Extensions/QuickAction
QUICKACTION_BUNDLE = $(BUILD_DIR)/$(QUICKACTION_NAME).appex

# Source files
QUICKACTION_SOURCES = $(QUICKACTION_DIR)/ActionViewController.mm
QUICKACTION_HEADERS = $(QUICKACTION_DIR)/ActionViewController.h
QUICKACTION_RESOURCES = $(QUICKACTION_DIR)/Action.js

# Compiler flags
QUICKACTION_CXXFLAGS = -std=c++17 -ObjC++ -mmacosx-version-min=10.15
QUICKACTION_LDFLAGS = -framework Cocoa -framework Foundation

# Build extension
$(QUICKACTION_BUNDLE): $(QUICKACTION_SOURCES) $(QUICKACTION_HEADERS)
	@echo "Building Quick Action Extension..."
	@mkdir -p $(QUICKACTION_BUNDLE)/Contents/{MacOS,Resources}
	$(CXX) $(QUICKACTION_CXXFLAGS) $(QUICKACTION_LDFLAGS) \
		-o $(QUICKACTION_BUNDLE)/Contents/MacOS/$(QUICKACTION_NAME) \
		$(QUICKACTION_SOURCES)
	@cp $(QUICKACTION_DIR)/Info.plist $(QUICKACTION_BUNDLE)/Contents/
	@cp $(QUICKACTION_RESOURCES) $(QUICKACTION_BUNDLE)/Contents/Resources/
	@echo "Quick Action Extension built successfully"

# Embed in main app
embed-quickaction: $(QUICKACTION_BUNDLE)
	@mkdir -p $(APP_BUNDLE)/Contents/PlugIns
	@cp -R $(QUICKACTION_BUNDLE) $(APP_BUNDLE)/Contents/PlugIns/
	@echo "Quick Action Extension embedded in main app"

.PHONY: embed-quickaction
```

## Testing Integration

After building, verify the integration:

```bash
# Check if extension is embedded
ls -la Notepad++.app/Contents/PlugIns/

# Should see:
# NotepadQuickAction.appex/

# Verify bundle structure
find Notepad++.app/Contents/PlugIns/NotepadQuickAction.appex

# Should see:
# Contents/
#   Info.plist
#   MacOS/NotepadQuickAction
#   Resources/Action.js

# Register with system
pluginkit -a Notepad++.app/Contents/PlugIns/NotepadQuickAction.appex

# Verify registration
pluginkit -m -v | grep notepad
```

## Runtime Requirements

The extension requires:
- **macOS 10.15+** (Catalina or later)
- **Main app** must be installed with bundle ID `org.notepad-plus-plus`
- **App Sandbox** properly configured with entitlements
- **Code signing** (at least ad-hoc for development)

## Minimal Xcode-Free Build

For a minimal build without Xcode:

```bash
#!/bin/bash
# minimal-build.sh - Build Quick Action without Xcode

EXTENSION_NAME="NotepadQuickAction"
EXTENSION_DIR="PowerEditor/cocoa/Extensions/QuickAction"
BUILD_DIR="build"

# Compile
clang++ -c -std=c++17 -ObjC++ \
  -mmacosx-version-min=10.15 \
  -framework Cocoa -framework Foundation \
  -o "${BUILD_DIR}/${EXTENSION_NAME}.o" \
  "${EXTENSION_DIR}/ActionViewController.mm"

# Link
clang++ -mmacosx-version-min=10.15 \
  -framework Cocoa -framework Foundation \
  -o "${BUILD_DIR}/${EXTENSION_NAME}" \
  "${BUILD_DIR}/${EXTENSION_NAME}.o"

# Create bundle
BUNDLE="${BUILD_DIR}/${EXTENSION_NAME}.appex"
mkdir -p "${BUNDLE}/Contents/"{MacOS,Resources}
cp "${BUILD_DIR}/${EXTENSION_NAME}" "${BUNDLE}/Contents/MacOS/"
cp "${EXTENSION_DIR}/Info.plist" "${BUNDLE}/Contents/"
cp "${EXTENSION_DIR}/Action.js" "${BUNDLE}/Contents/Resources/"

# Update Info.plist placeholders
sed -i '' 's/$(EXECUTABLE_NAME)/'"${EXTENSION_NAME}"'/g' "${BUNDLE}/Contents/Info.plist"
sed -i '' 's/$(PRODUCT_NAME)/'"${EXTENSION_NAME}"'/g' "${BUNDLE}/Contents/Info.plist"

echo "Extension built at: ${BUNDLE}"
```

## Continuous Integration

### GitHub Actions

Add to your `.github/workflows/build.yml`:

```yaml
- name: Build Quick Action Extension
  run: |
    cd PowerEditor/cocoa/Extensions/QuickAction
    ./minimal-build.sh
    
- name: Integrate Extension
  run: |
    mkdir -p Notepad++.app/Contents/PlugIns
    cp -R build/NotepadQuickAction.appex Notepad++.app/Contents/PlugIns/
    
- name: Verify Extension
  run: |
    test -d Notepad++.app/Contents/PlugIns/NotepadQuickAction.appex
    test -f Notepad++.app/Contents/PlugIns/NotepadQuickAction.appex/Contents/Info.plist
```

## Next Steps

1. **Read** [BUILD_CONFIGURATION.md](BUILD_CONFIGURATION.md) for detailed Xcode setup
2. **Read** [README.md](README.md) for usage and troubleshooting
3. **Test** the extension with various file types
4. **Customize** activation rules and appearance as needed

## Support

For issues:
- Check [README.md](README.md) troubleshooting section
- Review [BUILD_CONFIGURATION.md](BUILD_CONFIGURATION.md) for build issues
- Open issue on GitHub with logs from Console.app
