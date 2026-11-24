DEBUG = 0
FINALPACKAGE = 1

ARCHS = arm64 arm64e

# Share the SDK and deployment targets with the PreferenceBundle.
include YuDynamicstagepanBuild.mk
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = YuDynamicstagepan
YuDynamicstagepan_FILES = $(wildcard Hooks/*.xm Sources/*.m)
YuDynamicstagepan_CFLAGS = -fobjc-arc -I./Headers -I./Sources
YuDynamicstagepan_FRAMEWORKS = UIKit Foundation CoreFoundation
YuDynamicstagepan_LIBRARIES = substrate

# Package binary dylibs and resources
YuDynamicstagepan_RESOURCES = Resources/DynamicStage.dylib Resources/StageDaemon.dylib Resources/setup.jpg Resources/setupfinal.jpg Resources/*.mp4

include $(THEOS_MAKE_PATH)/tweak.mk

# Post-install to ensure dylib permissions
after-install::
	@find $(THEOS_STAGING_DIR) -name "*.dylib" -exec chmod 755 {} \;


