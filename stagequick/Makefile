THEOS_PACKAGE_SCHEME := roothide
ARCHS := arm64 arm64e
TARGET := iphone:clang:16.5:15.0
INSTALL_TARGET_PROCESSES := SpringBoard
FINALPACKAGE := 1
include $(THEOS)/makefiles/common.mk
TWEAK_NAME := StageQuick
StageQuick_FILES := StageQuickTrigger.xm StageQuickPanel.m
StageQuick_CFLAGS := -fobjc-arc
StageQuick_FRAMEWORKS := UIKit Foundation QuartzCore CoreGraphics CoreFoundation
StageQuick_LIBRARIES := substrate
include $(THEOS_MAKE_PATH)/tweak.mk
