import SwiftUI
import FlutterMacOS

// 程序的主入口标记
@main
// 现代 SwiftUI 入口！彻底告别 AppKit 入口
struct TranslatorApp:App{
    // @NSApplicationDelegateAdaptor 是苹果官方提供的转接器 它告诉 SwiftUI：“请帮我把底层的传统管家接进来，有系统事件时通知它”
    // 参数 表示告诉转接器：“请用哪一个类来做这个管家？”这里的 AppDelegate.self 就是class AppDelegate 传给它
    // 创建出来的管家实例存放到 appDelegate 类名后面跟：.self相当于 Java 的 .class
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // 因为遵循的是 App 协议 所以是Scene而不是View
    var body: some Scene{
        // 纯 SwiftUI 的状态栏小气泡窗口
        MenuBarExtra("Translator",systemImage: "character.book.closed"){
            PopoverView()
        }
        .menuBarExtraStyle(.window) // 气泡浮窗样式
        
        // 独立主窗口用于承载Flutter大界面
        Window("Flutter Translator", id: "main-window"){
            FlutterContentView().frame(minWidth: 800, minHeight: 600)
        }
    }
}

// 核心：将 FlutterAppDelegate 作为适配器挂入 SwiftUI 生命周期
// 这样 Flutter 引擎才能正常接收系统事件、快捷键、插件消息
// AppDelegate 降级为一个辅助委托对象，不再加 @main
class AppDelegate: FlutterAppDelegate{
    override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool{
        return false // 关闭主窗口后应用不退出，状态栏小组件继续常驻
    }
}
