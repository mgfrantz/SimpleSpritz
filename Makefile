APP_NAME := SimpleSpritz
BUILD_DIR := build
APP_DIR := $(BUILD_DIR)/$(APP_NAME).app
PKG_ROOT := $(BUILD_DIR)/pkg-root
PKG_PATH := $(BUILD_DIR)/$(APP_NAME).pkg
CONTENTS := $(APP_DIR)/Contents
MACOS := $(CONTENTS)/MacOS
RESOURCES := $(CONTENTS)/Resources

.PHONY: all build package install clean

all: package

build:
	mkdir -p "$(MACOS)" "$(RESOURCES)"
	CLANG_MODULE_CACHE_PATH="$(BUILD_DIR)/ModuleCache" swiftc Sources/SimpleSpritz/main.swift -o "$(MACOS)/$(APP_NAME)" -framework AppKit -framework Carbon
	cp Info.plist "$(CONTENTS)/Info.plist"

package: build
	rm -rf "$(PKG_ROOT)"
	mkdir -p "$(PKG_ROOT)/Applications"
	cp -R "$(APP_DIR)" "$(PKG_ROOT)/Applications/"
	pkgbuild --root "$(PKG_ROOT)" --identifier "local.simplespritz" --version "0.1.0" --install-location "/" "$(PKG_PATH)"

install: build
	rm -rf "/Applications/$(APP_NAME).app"
	cp -R "$(APP_DIR)" "/Applications/"

clean:
	rm -rf "$(BUILD_DIR)"
