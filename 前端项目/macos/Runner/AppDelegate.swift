import FlutterMacOS
import MenuBarExtraAccess
import SwiftUI

// 程序的主入口标记
@main
// 现代 SwiftUI 入口！彻底告别 AppKit 入口
struct TranslatorApp: App {
    // @NSApplicationDelegateAdaptor 是苹果官方提供的转接器 它告诉 SwiftUI：“请帮我把底层的传统管家接进来，有系统事件时通知它”
    // 参数 表示告诉转接器：“请用哪一个类来做这个管家？”这里的 AppDelegate.self 就是class AppDelegate 传给它
    // 创建出来的管家实例存放到 appDelegate 类名后面跟：.self相当于 Java 的 .class
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // 状态栏小气泡窗口的展开/关闭状态（双向绑定）
    @State private var isMenuPresented: Bool = false
    
    // 因为遵循的是 App 协议 所以是Scene而不是View
    // Scene 是“应用级常驻结构”，不是“一次性弹窗” var body: some Scene 并不是用来控制“启动瞬间”的临时逻辑，而是声明当前应用程序包含哪些长期存在的系统级入口
    var body: some Scene {
        // 独立主窗口用于承载Flutter大界面（作为第一个Scene，启动时默认弹出）
        // SwiftUI 的生命周期机制里，声明顺序至关重要
        // MenuBarExtra 排在第一个时：系统会优先将应用视作菜单栏驻留型应用
        // 位于后面的 Window 不会被视为主场景，因此启动时默认不会自动呈现
        // 当 Window 移到最前面时：系统会将该 Window 识别为主应用窗口
        Window("Flutter Translator", id: "main-window") {
            FlutterContentView().frame(minWidth: 800, minHeight: 600)
        }
        
        // 纯 SwiftUI 的状态栏小气泡窗口
        // 声明状态栏图标
        MenuBarExtra("Translator", systemImage: "character.book.closed") {
            // 点击图标后触发的该闭包
            PopoverView(isMenuPresented: $isMenuPresented)
        }
        .menuBarExtraAccess(isPresented: $isMenuPresented)  // 必须紧邻 MenuBarExtra，声明式控制展开/收起
        .menuBarExtraStyle(.window)  // 气泡浮窗样式
    }
}

// 核心：将 FlutterAppDelegate 作为适配器挂入 SwiftUI 生命周期
// 这样 Flutter 引擎才能正常接收系统事件、快捷键、插件消息
// AppDelegate 降级为一个辅助委托对象，不再加 @main
class AppDelegate: FlutterAppDelegate {
    override func applicationDidFinishLaunching(_ notification: Notification) {
        super.applicationDidFinishLaunching(notification)
        // 强制将应用策略设为常规应用（保证可以被 activate 到最前台）
        NSApp.setActivationPolicy(.regular)
    }
    
    // 从 macOS 12 / iOS 15 开始，如果应用没有显式实现此方法，系统控制台或编译运行期就会打印一条告警（Warning），提示开发者未明确声明安全状态恢复策略
    override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false  // 关闭主窗口后应用不退出，状态栏小组件继续常驻
    }
}
