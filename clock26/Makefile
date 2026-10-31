DEBUG = 0
FINALPACKAGE = 1

include YsClock26Build.mk
include $(THEOS)/makefiles/common.mk

# 主体是预编译的液态引擎（layout/Library/MobileSubstrate 下两个 dylib），
# 本工程只编译设置面板，其余文件由 layout 直接打包。
SUBPROJECTS += LiquidAssPrefs
include $(THEOS_MAKE_PATH)/aggregate.mk
