DEBUG = 0
FINALPACKAGE = 1

ARCHS = arm64 arm64e

# Share the SDK and deployment targets with the PreferenceBundle.
include AxsLiquidClockBuild.mk
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AxsLiquidClock
AxsLiquidClock_FILES = $(wildcard Hooks/*.xm Sources/*.m)
AxsLiquidClock_CFLAGS = -fobjc-arc -I./Headers -I./Sources
AxsLiquidClock_FRAMEWORKS = UIKit Foundation CoreFoundation
AxsLiquidClock_LIBRARIES = substrate

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += AxsLiquidClockPrefs
include $(THEOS_MAKE_PATH)/aggregate.mk
