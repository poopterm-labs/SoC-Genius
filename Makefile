TARGET := iphone:clang:9.3:4.0
ARCHS := armv7

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = SoCGenius
SoCGenius_FILES = SoCGenius/main.m
SoCGenius_RESOURCE_FILES = SoCGenius/Resources/Info.plist SoCGenius/Resources/Apple_SoC_S5L8920.jpg SoCGenius/Resources/S5L8922.jpg SoCGenius/Resources/Apple_A4_Chip.jpg SoCGenius/Resources/Apple_A5_Chip.jpg SoCGenius/Resources/Apple_A5X_Chip.jpg SoCGenius/Resources/Apple_A6_Chip.jpg SoCGenius/Resources/Apple_A6X_chip.jpg SoCGenius/Resources/Default-568h@2x.png
SoCGenius_RESOURCE_FILES += SoCGenius/Resources/Icon.png SoCGenius/Resources/Icon@2x.png SoCGenius/Resources/Icon-72.png SoCGenius/Resources/Icon-72@2x.png SoCGenius/Resources/Icon-60@2x.png SoCGenius/Resources/Icon-76.png SoCGenius/Resources/Icon-76@2x.png SoCGenius/Resources/Icon-60@3x.png
SoCGenius_FRAMEWORKS = UIKit QuartzCore CoreGraphics OpenGLES
SoCGenius_CFLAGS = -fno-objc-arc
SoCGenius_USE_MODULES = 0
SoCGenius_INSTALL_PATH = /Applications

include $(THEOS_MAKE_PATH)/application.mk
