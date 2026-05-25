APP_NAME := SimpleSpritz
BUILD_DIR := build
APP_DIR := $(BUILD_DIR)/$(APP_NAME).app
PKG_ROOT := $(BUILD_DIR)/pkg-root
PKG_PATH := $(BUILD_DIR)/$(APP_NAME).pkg
INSTALL_DIR := /Applications
INSTALLED_APP := $(INSTALL_DIR)/$(APP_NAME).app
SIGN_IDENTITY ?= -
CONTENTS := $(APP_DIR)/Contents
MACOS := $(CONTENTS)/MacOS
RESOURCES := $(CONTENTS)/Resources

.PHONY: all build package install stop-installed print-signing-help clean

all: package

build:
	mkdir -p "$(MACOS)" "$(RESOURCES)"
	CLANG_MODULE_CACHE_PATH="$(BUILD_DIR)/ModuleCache" swiftc Sources/SimpleSpritz/main.swift -o "$(MACOS)/$(APP_NAME)" -framework AppKit -framework Carbon
	cp Info.plist "$(CONTENTS)/Info.plist"
	codesign --force --deep --sign "$(SIGN_IDENTITY)" "$(APP_DIR)"

package: build
	rm -rf "$(PKG_ROOT)"
	mkdir -p "$(PKG_ROOT)/Applications"
	cp -R "$(APP_DIR)" "$(PKG_ROOT)/Applications/"
	pkgbuild --root "$(PKG_ROOT)" --identifier "local.simplespritz" --version "0.1.0" --install-location "/" "$(PKG_PATH)"

install: build
	$(MAKE) stop-installed
	rm -rf "$(INSTALLED_APP)"
	cp -R "$(APP_DIR)" "$(INSTALL_DIR)/"

stop-installed:
	-osascript -e 'tell application "$(APP_NAME)" to quit'
	@sleep 1

print-signing-help:
	@echo "Default signing uses ad-hoc identity: make install"
	@echo "For more stable macOS Accessibility trust, create a local code-signing certificate named SimpleSpritz Local Dev in Keychain Access:"
	@echo "  Keychain Access > Certificate Assistant > Create a Certificate..."
	@echo "  Name: SimpleSpritz Local Dev"
	@echo "  Identity Type: Self Signed Root"
	@echo "  Certificate Type: Code Signing"
	@echo "Then install with:"
	@echo "  make install SIGN_IDENTITY=\"SimpleSpritz Local Dev\""

clean:
	rm -rf "$(BUILD_DIR)"
