# iOS26 时间样式（LiquidClock）

把锁屏时钟改成 iOS 26 液态玻璃风格：更大的字号、内置可变数字字体、半透明冷白与轻微柔光。

- 包名：`com.ys.liquidclock`
- 注入进程：`com.apple.springboard`
- 最低系统：iOS 15.0（Rootless / RootHide 打包由 CI 处理）
- 依赖：`mobilesubstrate`、`preferenceloader`

## 功能

| 设置项 | 说明 | 范围 / 默认 |
|---|---|---|
| 启用插件 | 总开关，关闭后还原系统原始时钟 | 默认关闭 |
| 字号倍数 | 整体字号倍数 | 1.0 ~ 2.4，默认 1.7 |
| 字形宽度 | 可变字体 wdth 轴，越大越舒展 | 60 ~ 100，默认 88 |
| 字形高度 | 可变字体 HGHT 轴，越大越修长 | 100 ~ 500，默认 220 |
| 播放音乐时收缩 | 播放带封面音乐时缩回原始大小 | 默认开启 |

面板底部署名 `by 鱼教兽`。

修改后立即生效，无需注销。

## 实现思路

锁屏时钟是私有的 `UILabel` 子类。这里不硬编码私有类名或私有属性名，而是在
`SBFLockScreenDateView` / `SBFLockScreenDateViewController` 布局时，从视图树里按
“纯数字或 `H:mm` 形态的文本”识别时钟 label，再套用字体与柔光。

- 首次套用记录原字体，之后都以它为基准换算，避免反复布局时字号叠加。
- 样式参数比对后跳过重复设置，避免 `layoutSubviews` 递归。
- 配置只有一个写入方（设置面板），Tweak 只读快照。

## 目录

```
Hooks/YsLiquidClockMain.xm              钩子与视图树识别
Sources/YsLiquidClockStyle.{h,m}        字体与柔光计算
Sources/YsLiquidClockConfig.{h,m}       配置快照
Sources/YsLiquidClockPreferences.h      单一读写通道
YsLiquidClockPrefs/                     PreferenceLoader 面板
.github/workflows/build.yml              构建并发布 deb
```

## 构建

推送到 `main` 或手动触发工作流，CI 会用 Theos（RootHide）+ iPhoneOS16.5 SDK 构建，
产物上传到 Actions artifacts，同时发布 GitHub Release。

本地构建需要 macOS + Theos：

```sh
sh build.sh rootless
```

## 已知验证范围

静态结构检查（`doctor.py`）通过，**真机效果尚未验收**。若安装后锁屏时钟外观无变化，
请确认系统版本下 `SBFLockScreenDateView` 是否仍为锁屏时钟的承载视图，并据此调整
`Hooks/YsLiquidClockMain.xm` 中的注入点。
