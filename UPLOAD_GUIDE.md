# Dynamic Stage 触发面板 - 上传和编译指南

## 📋 项目已准备完毕

你的 Theos 工程已完全设置好，包含：
- ✅ 完整的项目结构（Hooks, Sources, Headers, Resources）
- ✅ 预编译的 dylib 文件和媒体资源
- ✅ 编译配置（Makefile, control, build.mk）
- ✅ GitHub Actions 自动编译工作流
- ✅ 本地 Git 仓库

## 🚀 上传到 GitHub（推荐方式）

### 步骤 1：创建 GitHub 仓库

1. 访问 https://github.com/new
2. 创建新仓库，名称例如：`DynamicStageTriggerPanel`
3. **不要勾选** "Initialize this repository with..."（因为本地已有项目）
4. 点击 Create repository

### 步骤 2：连接本地仓库

```bash
# 进入项目目录
cd /var/minis/shared/DynamicStage-panels/trigger-panel-theos

# 添加远程仓库（替换 YOUR_USERNAME 和 REPO_NAME）
git remote add origin https://github.com/YOUR_USERNAME/REPO_NAME.git

# 重命名分支为 main（可选但推荐）
git branch -M main

# 推送代码到 GitHub
git push -u origin main
```

### 步骤 3：触发自动编译

推送完成后，工作流会自动触发：

1. 访问仓库的 **Actions** 标签页
2. 等待工作流完成（通常 2-5 分钟）
3. 在 **Artifacts** 中下载已编译的 `.deb` 包

**或者** 手动触发工作流：
1. 进入 Actions 标签页
2. 选择 "Build Dynamic Stage Trigger Panel" 工作流
3. 点击 "Run workflow" → "Run workflow"

## 💻 本地编译（如果你有 macOS）

```bash
cd /var/minis/shared/DynamicStage-panels/trigger-panel-theos

# 方法 1：使用 build.sh 脚本
./build.sh

# 方法 2：直接使用 make
make clean
make package

# 编译输出在 packages/ 目录中
ls -lah packages/
```

## 📦 编译输出

编译完成后你会得到：
- `com.yu.dynamicstagepan_1.0.0_iphoneos-arm.deb` - 完整的 deb 包
- 可直接在 iOS 设备上使用 Cydia/Sileo 安装

## 🔗 GitHub Actions 状态

你可以通过以下网址监视编译状态：
```
https://github.com/YOUR_USERNAME/REPO_NAME/actions
```

## ⚙️ 修改和更新

### 修改代码后编译

```bash
# 修改文件后
git add -A
git commit -m "修改描述"
git push

# 工作流会自动触发
```

### 更新版本号

编辑 `control` 文件中的 Version 字段：
```
Version: 1.0.1
```

然后推送，新版本 deb 包会自动生成。

## 📱 安装到设备

在已越狱的 iOS 设备上：

1. **使用 Cydia/Sileo**：添加自定义源或直接安装本地 deb
2. **使用 SSH**：
   ```bash
   scp com.yu.dynamicstagepan_*.deb root@device_ip:/tmp/
   ssh root@device_ip "dpkg -i /tmp/com.yu.dynamicstagepan_*.deb"
   ```

## ❓ 常见问题

**Q: 编译失败？**
A: 检查 GitHub Actions 日志，通常是 SDK 路径问题。确保使用 macOS runner。

**Q: 如何分发我的包？**
A: 
- 在 GitHub Release 页面手动上传
- 或通过 GitHub Actions 自动发布
- 或添加到越狱源

**Q: 能在 iSH/Linux 上编译吗？**
A: 不能。iOS 编译需要 Xcode 和 iOS SDK，只能在 macOS 上或通过 GitHub Actions。

**Q: 如何修改插件名称或包名？**
A: 编辑 `control` 和 `tweak.json` 文件中的相应字段。

## 📝 项目信息

- **包名**：`com.yu.dynamicstagepan`
- **显示名**：Dynamic Stage 触发面板
- **当前版本**：1.0.0
- **目标进程**：SpringBoard, UIKit
- **最低 iOS 版本**：14+

## 🎯 下一步

1. ✅ 准备好的项目：`/var/minis/shared/DynamicStage-panels/trigger-panel-theos`
2. → 创建 GitHub 仓库并推送
3. → 等待 GitHub Actions 编译
4. → 下载 deb 包安装到设备

---

**需要帮助？** 检查 README.md 或项目中的其他文档。
