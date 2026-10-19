TARGET := iphone:clang:10.3:6.0
ARCHS := armv7
THEOS_PACKAGE_DIR ?= ../packages/32

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = SoCGenius
SoCGenius_FILES = main.m
SoCGenius_RESOURCE_FILES = Resources/Info.plist $(wildcard Resources/*.jpg)
SoCGenius_RESOURCE_FILES += Resources/Default-568h@2x.png
SoCGenius_RESOURCE_FILES += Resources/Icon.png Resources/Icon@2x.png Resources/Icon-72.png Resources/Icon-72@2x.png Resources/Icon-60@2x.png Resources/Icon-76.png Resources/Icon-76@2x.png Resources/Icon-60@3x.png
SoCGenius_FRAMEWORKS = UIKit QuartzCore CoreGraphics OpenGLES
# The original iOS 6 sensor screen uses UIAccelerometer, the API available to it.
SoCGenius_CFLAGS = -fno-objc-arc -Wno-deprecated-declarations
SoCGenius_USE_MODULES = 0
SoCGenius_INSTALL_PATH = /Applications

include $(THEOS_MAKE_PATH)/application.mk
