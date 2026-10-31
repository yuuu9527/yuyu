# iOS26 时间样式（LiquidClock）

把锁屏时钟改成 iOS 26 风格：更大的字号、更粗的字重、SF Rounded 圆体字形，以及白色柔光外扩的玻璃质感。

- 包名：`com.axs.liquidclock`
- 注入进程：`com.apple.springboard`
- 最低系统：iOS 15.0（Rootless / RootHide 打包由 CI 处理）
- 依赖：`mobilesubstrate`、`preferenceloader`

## 功能

| 设置项 | 说明 | 范围 / 默认 |
|---|---|---|
| 启用插件 | 总开关，关闭后还原系统原始字体 | 默认关闭 |
| 字号倍数 | 相对系统原字号的倍数 | 0.8 ~ 2.2，默认 1.5 |
| 字重 | 由 Regular 到 Black 平滑映射 | 0 ~ 10，默认 5.0 |
| 字距 | 文字字距微调，负值收紧 | -2.0 ~ 2.0，默认 -0.3 |
| 圆体字形 | 使用 SF Rounded 字族 | 默认开启 |
| 液态数字字体 | 读取设备上已安装的可变数字字体（SFAdaptiveSoftNumeric） | 默认开启，缺失时退回系统字体 |
| 通透度 | 文字不透明度，越低越像玻璃 | 0.3 ~ 1.0，默认 0.8 |
| 发光强度 | 白色柔光半径与不透明度，0 为关闭 | 0 ~ 1，默认 0.25 |

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
Hooks/AxsLiquidClockMain.xm              钩子与视图树识别
Sources/AxsLiquidClockStyle.{h,m}        字体与柔光计算
Sources/AxsLiquidClockConfig.{h,m}       配置快照
Sources/AxsLiquidClockPreferences.h      单一读写通道
AxsLiquidClockPrefs/                     PreferenceLoader 面板
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
`Hooks/AxsLiquidClockMain.xm` 中的注入点。
