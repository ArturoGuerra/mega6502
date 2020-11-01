#BOARD=MiniCore:avr:328:bootloader=true,variant=modelP,BOD=1v8,LTO=Os,clock=8MHz_external
#BOARD = esp8266:esp8266:d1_mini:CpuFrequency=80,VTable=flash,FlashSize=4M1M,LwIPVariant=v2mss536,Debug=Disabled,DebugLevel=None____,FlashErase=sdk,UploadSpeed=921600

#LIBRARIES := ../libraries

#--------
# include this file in your sketch Makefile

INO_FILE ?= $(shell basename $(CURDIR)).ino

ARDUINO_IDE_VERSION ?= 1.8.6
ARDUINO_DIR ?= $(HOME)/opt/arduino-$(ARDUINO_IDE_VERSION)
BUILD_PATH ?= $(CURDIR)/.build
CACHE_PATH ?= $(CURDIR)/.cache

SOURCES := $(wildcard *.c *.cpp *.h *.ino *.pde)

.DEFAULT_GOAL:=$(BUILD_PATH)/$(INO_FILE).elf

$(BUILD_PATH)/$(INO_FILE).elf: $(SOURCES)
	mkdir -p $(BUILD_PATH) $(CACHE_PATH)
	$(ARDUINO_DIR)/arduino-builder \
		-compile \
		$(ARDUINO_BUILDER_OPT) \
		-logger=human \
		-build-path $(BUILD_PATH) --prefs=build.path=$(BUILD_PATH) \
		-build-cache $(CACHE_PATH) \
		-hardware $(ARDUINO_DIR)/hardware \
		-hardware $(HOME)/.arduino15/packages \
		-tools $(ARDUINO_DIR)/tools-builder \
		-tools $(ARDUINO_DIR)/hardware/tools/avr \
		-tools $(HOME)/.arduino15/packages \
		-built-in-libraries $(ARDUINO_DIR)/libraries \
		-libraries $(LIBRARIES) \
		-fqbn=$(BOARD) \
		-ide-version=10806 \
		-prefs=build.warn_data_percentage=75 \
		$(INO_FILE)

clean:
	rm -rf $(BUILD_PATH) $(CACHE_PATH)

.PHONY: clean
