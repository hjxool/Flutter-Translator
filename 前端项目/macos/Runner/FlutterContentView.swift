import SwiftUI
import FlutterMacOS

// SwiftUI 无法直接识别 Flutter 的 FlutterViewController
// 因此需要一个文件遵循 NSViewControllerRepresentable 协议，把 Flutter 控制器包装成 SwiftUI 能用的 View
struct FlutterContentView:NSViewControllerRepresentable {
    func makeNSViewController(context:Context) -> FlutterViewController {
        let controller = FlutterViewController()
        // 注册 Flutter 插件（如网络、音视频等插件）
        RegisterGeneratedPlugins(registry: controller)
        return controller
    }
    
    func updateNSViewController(_ nsViewController: FlutterViewController, context: Context) {}
}
