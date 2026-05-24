APP_NAME := SimpleSpritz
BUILD_DIR := build
APP_DIR := $(BUILD_DIR)/$(APP_NAME).app
CONTENTS := $(APP_DIR)/Contents
MACOS := $(CONTENTS)/MacOS
RESOURCES := $(CONTENTS)/Resources

.PHONY: all build run clean

all: build

build:
	mkdir -p "$(MACOS)" "$(RESOURCES)"
	CLANG_MODULE_CACHE_PATH="$(BUILD_DIR)/ModuleCache" swiftc Sources/SimpleSpritz/main.swift -o "$(MACOS)/$(APP_NAME)" -framework AppKit -framework Carbon
	cp Info.plist "$(CONTENTS)/Info.plist"

run: build
	open "$(APP_DIR)"

clean:
	rm -rf "$(BUILD_DIR)"
