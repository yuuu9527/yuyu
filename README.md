# Dynamic Stage 触发面板

Dynamic Stage 是一个强大的 iOS 越狱插件，提供快速应用启动面板，通过边缘拖拽或长按手势打开。

## 功能特性

- 🚀 通过手势快速启动应用
- 📱 支持最近使用应用和收藏应用
- ⚙️ 灵活的手势配置选项
- 🎨 毛玻璃设计，视觉效果优秀
- 🔄 支持分屏和多窗口模式

## 技术细节

此项目包含预编译的 dylib 文件：
- `DynamicStage.dylib` (1.9 MB) - SpringBoard 注入，负责 UI 和手势处理
- `StageDaemon.dylib` (166 KB) - UIKit 注入，负责应用窗口调整

更多实现细节请参考 `trigger-panel/NOTES.md`

## 编译与安装

### 方法 1：GitHub Actions（推荐）

1. Fork 本仓库到你的 GitHub 账户
2. Push 任何提交或手动触发工作流
3. 在 Actions 标签页查看编译进度
4. 从 Artifacts 下载已编译的 .deb 包

### 方法 2：本地编译（macOS）

```bash
# 安装 Theos
bash -c "$(curl -fsSL https://raw.githubusercontent.com/theos/theos/master/bin/install-theos)"

# 编译
make clean
make package

# 编译输出在 packages/ 目录
```

### 方法 3：本地编译（Linux）

```bash
# 需要交叉编译工具链
make THEOS_PLATFORM_SDK_PATH=<path-to-ios-sdk> clean
make THEOS_PLATFORM_SDK_PATH=<path-to-ios-sdk> package
```

## 文件结构

```
├── Hooks/              # Tweak hook 源代码
├── Sources/            # 配置和工具类
├── Headers/            # 头文件
├── Resources/          # 预编译 dylib 和媒体资源
├── Makefile            # 编译配置
├── control             # Debian 包信息
└── .github/workflows/  # GitHub Actions 工作流
```

## 配置

通过 Mobilesubstrate 或其他越狱工具的设置面板配置：

- **enabled** - 启用/禁用插件
- **useModernGesture** - 使用系统原生手势或传统 Pan 手势
- **selectedApplications** - 选择需要支持的应用
- **pinnedApplications** - 收藏的应用列表
- **showOpenAppIcon** - 显示当前运行的应用图标
- **disableOnHomeScreen** - 在主屏幕上禁用
- **appearance** - 外观模式（浅色/深色/自动）

## 依赖

- iOS 14+
- mobilesubstrate
- Cydiasubstrate（某些系统版本）

## 许可证

遵循原作者许可，此项目为提取和重新打包版本。

## 致谢

- 原作者：tomt000
- Theos 编译框架

## 问题反馈

遇到问题？请提交 Issue 或联系维护者。

---

**注意**：此为越狱工具，仅用于学习研究目的。使用需遵守当地法律。
