import FlutterMacOS
import SwiftUI

// Flutter 引擎本身是基于 AppKit 构建 而SwiftUI包含 AppKit 的核心
// 因此具有NSViewControllerRepresentable协议
struct FlutterContentView: NSViewControllerRepresentable {
  // FlutterViewController 由 FlutterMacOS 提供 内部封装了 Flutter 引擎实例
  func makeNSViewController(context: Context) -> FlutterViewController {
    // 创造实体
    let controller = FlutterViewController()
    // 给实体打补丁/安装插件
    // RegisterGeneratedPlugins 由 FlutterMacOS 提供 将pubspec.yaml内需要调用 macOS 的插件配置到控制器上
    RegisterGeneratedPlugins(registry: controller)
    // 将这个配置完毕的完整实体交还给 SwiftUI
    return controller
  }

  func updateNSViewController(_ nsViewController: FlutterViewController, context: Context) {}
}
