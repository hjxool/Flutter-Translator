import Cocoa
import FlutterMacOS

// 程序的主入口标记：恢复为 Flutter 官方标准的 AppKit 委托入口
@main
class AppDelegate: FlutterAppDelegate {

  override func applicationDidFinishLaunching(_ notification: Notification) {
    // 因为存在托盘图标因此可能被改成辅助/托盘应用 不会在启动时打开主界面 因此这里防御性修改下
    NSApp.setActivationPolicy(.regular)

    // 推迟到下一个 RunLoop 周期再初始化状态栏：
    // super.applicationDidFinishLaunching 会异步触发 Flutter 引擎加载与 MainFlutterWindow 的创建，
    // 若此时立即创建 NSStatusItem，可能因激活策略尚未完全生效而导致图标不显示
    DispatchQueue.main.async {
      // 初始化状态栏图标与浮窗（AppKit 为底，SwiftUI 填充）
      StatusBarMenuManager.shared.setup()
    }
  }

  // 从 macOS 12 / iOS 15 开始，如果应用没有显式实现此方法，系统控制台或编译运行期就会打印一条告警（Warning），提示开发者未明确声明安全状态恢复策略
  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false  // 关闭主窗口后应用不退出，状态栏小组件继续常驻
  }

  /// 供状态栏浮窗等外部调用的快捷方法：激活并展示 Flutter 主窗口
  func showMainWindow() {
    // 遍历当前已有的窗口实例，找到 MainFlutterWindow 并调至前台
    if let window = NSApp.windows.first(where: { $0 is MainFlutterWindow }) {
      window.makeKeyAndOrderFront(nil)
      NSApp.activate(ignoringOtherApps: true)
    }
  }
}
