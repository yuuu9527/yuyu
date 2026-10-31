include ../YsClock26Build.mk
include $(THEOS)/makefiles/common.mk

# 目录名必须保持 LiquidAssPrefs.bundle：引擎按这个路径加载可变数字字体
# (/Library/PreferenceBundles/LiquidAssPrefs.bundle/SFAdaptiveSoftNumeric-VF.otf)
BUNDLE_NAME = LiquidAssPrefs
LiquidAssPrefs_FILES = $(wildcard *.m)
LiquidAssPrefs_CFLAGS = -fobjc-arc
LiquidAssPrefs_FRAMEWORKS = UIKit Foundation CoreFoundation
LiquidAssPrefs_PRIVATE_FRAMEWORKS = Preferences
LiquidAssPrefs_INSTALL_PATH = /Library/PreferenceBundles

include $(THEOS_MAKE_PATH)/bundle.mk
