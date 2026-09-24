import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
    override func awakeFromNib() {
        // 老模板的 MainMenu.xib 内部写死了启动时自动创建并弹出 MainFlutterWindow
        self.close() // 直接关闭 xib 模板创建的默认窗口
        super.awakeFromNib()
    }
}
