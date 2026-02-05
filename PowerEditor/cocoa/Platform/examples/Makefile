# Makefile for Hello World Plugin Example
# Build with: make
# Install with: make install
# Clean with: make clean

PLUGIN_NAME = HelloWorld
PLUGIN_FILE = $(PLUGIN_NAME).dylib
SOURCE_FILE = HelloWorldPlugin.c

# Compiler settings
CC = clang
CFLAGS = -Wall -Wextra -O2 -fvisibility=default
INCLUDES = -I..
FRAMEWORKS = -framework Cocoa -framework Foundation

# Installation directory
INSTALL_DIR = $(HOME)/Library/Application\ Support/Notepad++/plugins

# Default target
all: $(PLUGIN_FILE)

# Build the plugin
$(PLUGIN_FILE): $(SOURCE_FILE)
	$(CC) -dynamiclib $(CFLAGS) $(INCLUDES) $(FRAMEWORKS) \
		-o $(PLUGIN_FILE) $(SOURCE_FILE)
	@echo "Plugin built successfully: $(PLUGIN_FILE)"

# Sign the plugin (requires Developer ID certificate)
sign: $(PLUGIN_FILE)
	@if command -v codesign >/dev/null 2>&1; then \
		codesign -s - $(PLUGIN_FILE); \
		echo "Plugin signed (ad-hoc)"; \
	else \
		echo "codesign not available"; \
	fi

# Install the plugin
install: $(PLUGIN_FILE) sign
	@mkdir -p "$(INSTALL_DIR)"
	cp $(PLUGIN_FILE) "$(INSTALL_DIR)/"
	@echo "Plugin installed to: $(INSTALL_DIR)/$(PLUGIN_FILE)"

# Uninstall the plugin
uninstall:
	rm -f "$(INSTALL_DIR)/$(PLUGIN_FILE)"
	@echo "Plugin uninstalled"

# Clean build artifacts
clean:
	rm -f $(PLUGIN_FILE) *.o
	@echo "Build artifacts cleaned"

# Verify the plugin
verify: $(PLUGIN_FILE)
	@echo "=== Plugin Information ==="
	file $(PLUGIN_FILE)
	@echo ""
	@echo "=== Exported Symbols ==="
	nm -g $(PLUGIN_FILE) | grep plugin
	@echo ""
	@echo "=== Code Signature ==="
	codesign -dv $(PLUGIN_FILE) 2>&1 || echo "Not signed or signature invalid"

# Development target: build, sign, and install
dev: all sign install
	@echo "Development build complete"

.PHONY: all sign install uninstall clean verify dev
