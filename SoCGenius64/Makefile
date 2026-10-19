TARGET := iphone:clang:latest:7.0
ARCHS := arm64
THEOS_PACKAGE_DIR ?= ../packages/64

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = SoCGenius64
SoCGenius64_FILES = main.m
SoCGenius64_RESOURCE_FILES = Resources/Info.plist $(wildcard Resources/*.jpg)
SoCGenius64_RESOURCE_FILES += Resources/Default-568h@2x.png
SoCGenius64_RESOURCE_FILES += Resources/Icon.png Resources/Icon@2x.png Resources/Icon-72.png Resources/Icon-72@2x.png Resources/Icon-60@2x.png Resources/Icon-76.png Resources/Icon-76@2x.png Resources/Icon-60@3x.png
SoCGenius64_FRAMEWORKS = UIKit QuartzCore CoreGraphics OpenGLES CoreMotion
SoCGenius64_CFLAGS = -fno-objc-arc
SoCGenius64_USE_MODULES = 0
SoCGenius64_INSTALL_PATH = /Applications

.PHONY: package32 package-all clean32 clean-all

package32:
	$(MAKE) -C SoCGenius32 package THEOS_PROJECT_DIR=$(CURDIR)/SoCGenius32 THEOS_PACKAGE_DIR=../packages/32

package-all: package package32

clean32:
	$(MAKE) -C SoCGenius32 clean THEOS_PROJECT_DIR=$(CURDIR)/SoCGenius32 THEOS_PACKAGE_DIR=../packages/32

clean-all: clean clean32

include $(THEOS_MAKE_PATH)/application.mk
