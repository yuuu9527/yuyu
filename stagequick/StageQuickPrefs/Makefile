include ../StageQuickBuild.mk
include $(THEOS)/makefiles/common.mk

BUNDLE_NAME := StageQuickPrefs
StageQuickPrefs_FILES := ../SQRootListController.m
StageQuickPrefs_CFLAGS := -fobjc-arc -I..
StageQuickPrefs_RESOURCE_FILES := ../Resources/SQRoot.plist ../StageQuickPrefs/Info.plist
StageQuickPrefs_FRAMEWORKS := UIKit Foundation CoreFoundation
StageQuickPrefs_PRIVATE_FRAMEWORKS := Preferences
StageQuickPrefs_INSTALL_PATH := /Library/PreferenceBundles

include $(THEOS_MAKE_PATH)/bundle.mk
