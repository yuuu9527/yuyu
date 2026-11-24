THEOS_PACKAGE_SCHEME := roothide
ARCHS := arm64 arm64e
TARGET := iphone:clang:16.5:15.0
INSTALL_TARGET_PROCESSES := SpringBoard
FINALPACKAGE := 1
STAGEQUICK_COMPANION_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
include $(THEOS)/makefiles/common.mk
TWEAK_NAME := StageQuickCompanion
StageQuickCompanion_FILES := StageQuickCompanion.m
StageQuickCompanion_CFLAGS := -fobjc-arc
StageQuickCompanion_FRAMEWORKS := UIKit Foundation
StageQuickCompanion_LIBRARIES := substrate
include $(THEOS_MAKE_PATH)/tweak.mk

# Replace only the original Misc.plist; the original preference bundle and
# every other saved setting remain installed by Dynamic Stage 1.2.
after-stage::
	@mkdir -p "$(THEOS_STAGING_DIR)/Library/PreferenceBundles/stageduoprefs.bundle"
	@cp "$(STAGEQUICK_COMPANION_DIR)/Misc.plist" "$(THEOS_STAGING_DIR)/Library/PreferenceBundles/stageduoprefs.bundle/Misc.plist"
