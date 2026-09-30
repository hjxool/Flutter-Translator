import FlutterMacOS
import SwiftUI

// 自定义一个继承自 FlutterViewController 的控制器类，
// 目的是为了借用 macOS 视图控制器自带的生命周期方法
class MainFlutterViewController: FlutterViewController {
    // 记录是否已经处理过首次聚焦，防止窗口在多次显示/隐藏时重复触发激活逻辑
    private var hasHandledInitialFocus = false
    
    // 这个方法会在 Flutter 视图真正挂载到窗口并在屏幕上完全显示（渲染出第一帧）时自动被系统调用
    override func viewDidAppear(){
        super.viewDidAppear() // 先执行系统默认的显示逻辑
        // 只有第一次冷启动时才会往下走
        guard !hasHandledInitialFocus else {return}
        hasHandledInitialFocus = true
        // 确保应用启动时激活到前台，避免窗口位于其他应用背后
        NSApp.activate(ignoringOtherApps: true)
        // 拿到当前控制器所在的 window（主窗口）
        // makeKeyAndOrderFront 会做两件事：成为 Key Window（接收键盘输入焦点）、Order Front（把窗口提到最顶层显示）
        self.view.window?.makeKeyAndOrderFront(nil)
    }
}

// Flutter 引擎本身是基于 AppKit 构建 而SwiftUI包含 AppKit 的核心
// 因此具有NSViewControllerRepresentable协议
// SwiftUI 桥接组件：负责把上面的 macOS 原生控制器包装给 SwiftUI 使用
struct FlutterContentView: NSViewControllerRepresentable {
  // FlutterViewController 由 FlutterMacOS 提供 内部封装了 Flutter 引擎实例
  func makeNSViewController(context: Context) -> FlutterViewController {
      // 实例化刚才自定义的控制器，而不是直接用系统默认的
    let controller = MainFlutterViewController()
    // 给实体打补丁/安装插件
    // RegisterGeneratedPlugins 由 FlutterMacOS 提供 将pubspec.yaml内需要调用 macOS 的插件配置到控制器上
    RegisterGeneratedPlugins(registry: controller)
    // 将这个配置完毕的完整实体交还给 SwiftUI
    return controller
  }

  func updateNSViewController(_ nsViewController: FlutterViewController, context: Context) {}
}
