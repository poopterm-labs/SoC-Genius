TARGET := iphone:clang:9.3:6.0
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
# The iOS 6.1.4 crash report shows startup entering ARMv7 code in ARM state.
# Keep the legacy binary in ARM mode so the entrypoint matches that state.
SoCGenius_CFLAGS = -fno-objc-arc -Wno-deprecated-declarations -marm
SoCGenius_USE_MODULES = 0
SoCGenius_INSTALL_PATH = /Applications

include $(THEOS_MAKE_PATH)/application.mk
