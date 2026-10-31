include ../AxsLiquidClockBuild.mk
include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = AxsLiquidClockPrefs
AxsLiquidClockPrefs_FILES = $(wildcard *.m)
AxsLiquidClockPrefs_CFLAGS = -fobjc-arc -I../Sources
AxsLiquidClockPrefs_FRAMEWORKS = UIKit Foundation CoreFoundation
AxsLiquidClockPrefs_PRIVATE_FRAMEWORKS = Preferences
AxsLiquidClockPrefs_INSTALL_PATH = /Library/PreferenceBundles

include $(THEOS_MAKE_PATH)/bundle.mk
