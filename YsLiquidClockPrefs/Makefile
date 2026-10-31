include ../YsLiquidClockBuild.mk
include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = YsLiquidClockPrefs
YsLiquidClockPrefs_FILES = $(wildcard *.m)
YsLiquidClockPrefs_CFLAGS = -fobjc-arc -I../Sources
YsLiquidClockPrefs_FRAMEWORKS = UIKit Foundation CoreFoundation
YsLiquidClockPrefs_PRIVATE_FRAMEWORKS = Preferences
YsLiquidClockPrefs_INSTALL_PATH = /Library/PreferenceBundles

include $(THEOS_MAKE_PATH)/bundle.mk
