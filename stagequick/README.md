# StageQuick 快捷启动（RootHide）
独立重写，不依赖原版 Dynamic Stage，不包含它的 dylib、后台服务或分屏逻辑。在已解锁状态，从右下角靠内、距底边约 15–35 pt 处向左上方划，松手打开面板。点击应用后通过系统正常前台打开。面板支持按名称或包 ID 搜索，以及当前 SpringBoard 会话内从此面板打开的最近 6 个应用。点空白处收起。

参考：原作者 [Dynamic Stage](https://havoc.app/package/dynamicstage) 对右下角激活手势的说明与随包 `open.mp4` 的搜索/最近/应用列表布局。交互为独立近似：没有系统手势劫持、拖拽分屏、缩放当前 App、常驻应用、原版收藏管理、原版二进制或素材。与原版声明冲突以避免同一热区被多个手势争抢。锁屏禁用；搜索键盘出现时暂停触发窗。不同系统对 SpringBoard 窗口层级和手势仲裁的处理须真机验证。

目标 iOS 15+，原生 RootHide Theos scheme；仅 SpringBoard 进程。不要与普通 rootless 包混装。静态打包检查不代表已真机测试。
