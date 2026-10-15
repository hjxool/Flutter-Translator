import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    // FlutterViewController 由 FlutterMacOS 提供 内部封装了 Flutter 引擎实例
    let flutterViewController = FlutterViewController()
    // 此时 self.frame 记录的是 Xib 模板中预设的原始尺寸
    let windowFrame = self.frame
    // 在 AppKit 机制中，当给窗口的 contentViewController 赋值时，NSWindow 会自动根据新控制器的默认视图尺寸来重置自身窗口的 frame
    self.contentViewController = flutterViewController
    // windowFrame 指定屏幕全局坐标系中的原点位置以及尺寸
    // display 窗口是否立即重绘
    // 如果写成 self.setFrame(self.frame, display: true)，获取到的 self.frame 已经在self.contentViewController = flutterViewController篡改了，无法恢复到 Xib 中的初始预设
    self.setFrame(windowFrame, display: true)

    // 给实体打补丁/安装插件
    // RegisterGeneratedPlugins 由 FlutterMacOS 提供 将pubspec.yaml内需要调用 macOS 的插件配置到控制器上
    RegisterGeneratedPlugins(registry: flutterViewController)

    // 接入原生与 Flutter 的 MethodChannel 桥接服务
    FlutterBridge.shared.setup(with: flutterViewController.engine.binaryMessenger)

    super.awakeFromNib()
  }
}
