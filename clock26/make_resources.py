#!/usr/bin/env python3
import os, plistlib, shutil

ROOT = "/var/minis/workspace/yuyu/clock26"
RES = os.path.join(ROOT, "LiquidAssPrefs", "Resources")
LAYOUT = os.path.join(ROOT, "layout")
os.makedirs(RES, exist_ok=True)

DOMAIN = "dylv.liquidassprefs"
BUNDLE_DIR = "LiquidAssPrefs.bundle"

def slider(label, key, default, lo, hi, integer=False):
    spec = {"cell": "PSTitleValueCell", "cellClass": "YsClockSliderCell", "label": label,
            "key": key, "defaults": DOMAIN, "default": default, "min": lo, "max": hi}
    if integer:
        spec["integer"] = True
    return spec

def switch(label, key, default):
    return {"cell": "PSSwitchCell", "label": label, "key": key,
            "defaults": DOMAIN, "default": default}

def group(label=None, footer=None):
    d = {"cell": "PSGroupCell"}
    if label:
        d["label"] = label
    if footer:
        d["footerText"] = footer
    return d

root = {
    "title": "液态时钟",
    "items": [
        group("锁屏液态时钟",
              "只保留锁屏时钟渲染。以下开关控制时钟本身，其它功能（灵动岛、通知、键盘、控制中心等）已全部关闭。"),
        switch("启用插件", "Global.Enabled", True),
        switch("锁屏时钟", "Lockscreen.Clock", True),
        switch("时钟模糊", "Clock.Blur", True),

        group("液态合成", "帧率越高越顺滑、越耗电；边框宽度影响时钟玻璃边缘的厚度。"),
        slider("帧率", "Clock.FPS", 60, 30, 120, integer=True),
        slider("边框宽度", "Clock.BezelWidth", 2.0, 0.0, 8.0),

        group("可变数字字体",
              "字重越大笔画越粗，柔和度控制液态数字边缘的柔光过渡。"),
        switch("启用可变字体", "Clock.VariableFont.Enabled", True),
        slider("字号缩放", "Clock.VariableFont.SizeScale", 1.0, 0.5, 2.0),
        slider("字重", "Clock.VariableFont.Weight", 0.4, 0.0, 1.0),
        slider("柔和度", "Clock.VariableFont.Softness", 0.5, 0.0, 1.0),

        group(None, "改完点下面的「应用并注销」生效。"),
        {"cell": "PSButtonCell", "label": "应用并注销", "action": "applyAndRespring"},
        group(footer="by 鱼教兽"),
    ],
}
with open(os.path.join(RES, "YsClock26Root.plist"), "wb") as f:
    plistlib.dump(root, f, fmt=plistlib.FMT_XML)

info = {
    "CFBundleDevelopmentRegion": "zh_CN",
    "CFBundleDisplayName": "液态时钟",
    "CFBundleExecutable": "LiquidAssPrefs",
    "CFBundleIdentifier": "com.ys.liquidclock26.preferences",
    "CFBundleInfoDictionaryVersion": "6.0",
    "CFBundleName": "液态时钟",
    "CFBundlePackageType": "BNDL",
    "CFBundleShortVersionString": "1.0.0",
    "CFBundleVersion": "1.0.0",
    "MinimumOSVersion": "15.0",
    "NSPrincipalClass": "YsClock26RootListController",
}
with open(os.path.join(RES, "Info.plist"), "wb") as f:
    plistlib.dump(info, f, fmt=plistlib.FMT_BINARY)

# --- layout ---
loader = os.path.join(LAYOUT, "Library/PreferenceLoader/Preferences")
os.makedirs(loader, exist_ok=True)
entry = {
    "Filter": {"Bundles": ["com.apple.Preferences"]},
    "entry": {
        "bundle": "LiquidAssPrefs",
        "cell": "PSLinkCell",
        "detail": "YsClock26RootListController",
        "icon": "icon",
        "isController": True,
        "label": "液态时钟",
    },
}
with open(os.path.join(loader, "LiquidClock26.plist"), "wb") as f:
    plistlib.dump(entry, f, fmt=plistlib.FMT_XML)

bundle_layout = os.path.join(LAYOUT, "Library/PreferenceBundles", BUNDLE_DIR)
os.makedirs(bundle_layout, exist_ok=True)
src_font = "/var/minis/workspace/clk26/root/Library/PreferenceBundles/LiquidAssPrefs.bundle/SFAdaptiveSoftNumeric-VF.otf"
shutil.copy2(src_font, os.path.join(bundle_layout, "SFAdaptiveSoftNumeric-VF.otf"))

icon_src = "/var/minis/workspace/yuyu/YsLiquidClockPrefs/Resources/icon@2x.png"
if os.path.exists(icon_src):
    shutil.copy2(icon_src, os.path.join(RES, "icon@2x.png"))

print("root plist items:", len(root["items"]))
for p in ("YsClock26Root.plist", "Info.plist", "icon@2x.png"):
    print(p, os.path.exists(os.path.join(RES, p)))
