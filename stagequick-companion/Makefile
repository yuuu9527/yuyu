THEOS_PACKAGE_SCHEME := roothide
ARCHS := arm64 arm64e
TARGET := iphone:clang:16.5:15.0
INSTALL_TARGET_PROCESSES := SpringBoard
FINALPACKAGE := 1
include $(THEOS)/makefiles/common.mk
TWEAK_NAME := StageQuickCompanion
StageQuickCompanion_FILES := StageQuickCompanion.m
StageQuickCompanion_CFLAGS := -fobjc-arc
StageQuickCompanion_FRAMEWORKS := UIKit Foundation
StageQuickCompanion_LIBRARIES := substrate
include $(THEOS_MAKE_PATH)/tweak.mk
