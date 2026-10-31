DEBUG = 0
FINALPACKAGE = 1

ARCHS = arm64 arm64e

# Share the SDK and deployment targets with the PreferenceBundle.
include YsLiquidClockBuild.mk
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = YsLiquidClock
YsLiquidClock_FILES = $(wildcard Hooks/*.xm Sources/*.m)
YsLiquidClock_CFLAGS = -fobjc-arc -I./Headers -I./Sources
YsLiquidClock_FRAMEWORKS = UIKit Foundation CoreFoundation CoreText
YsLiquidClock_LIBRARIES = substrate

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += YsLiquidClockPrefs
include $(THEOS_MAKE_PATH)/aggregate.mk
