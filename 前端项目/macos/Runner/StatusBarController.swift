// 得手动引入 不会根据联想自动引入
import Cocoa
import SwiftUI

class StatusBarController {
    // 变量名: 类型
    private var statusBar: NSStatusBar
    private var statusItem: NSStatusItem
    private var popover: NSPopover
    // 同dart语法 ？表示可空null
    private var eventMonitor: Any?
    
    // init 相当于构造函数
    // _ 表示调用该方法时可省略外部参数名 因为swift中 fn(a:type) 调用时必须fn(a:value) 而加了_ 即按顺序传入参数
    // @escaping 表示逃逸闭包 用于异步任务、用户点击回调 在函数返回之后可能才会被触发
    // 但是存在循环引用风险，通常在闭包内使用 [weak self] 防止内存泄漏
    init(_ onOpenMainWindow: @escaping () -> Void {
        // 内部使用依然要用形参名
        // self 相当于 this 同名冲突时必须加 self
        
        // 获取系统顶部状态栏，并创建一个根据内容自适应宽度的 Item
        // NSStatusBar 是整个 macOS 状态栏的管理类 system 是该类的一个全局单例
        statusBar = NSStatusBar.system
        // statusBar.statusItem 表示在系统状态栏借个地方放图标 variableLength 表示自适应长度
        statusItem = statusBar.statusItem(withLength: NSStatusItem.variableLength)
        // 实例化一个气泡浮窗
        popover = NSPopover()
        
        // 核心：使用 NSHostingController 承载纯 SwiftUI 视图
        // 创建一个 SwiftUI 视图（PopoverView），并将关闭浮窗及唤起 Flutter 窗口的回调传给它
        // swift 中对象有个属性记录该引用数量 当为0时 GC 会进行回收
        // swift 中闭包语法 { [捕获列表] (参数列表) -> 返回值类型 in 执行代码 }
        // [捕获列表] 引用外部变量时使用 不写[...]表示默认强引用 即只要闭包存活就一直引用外部变量 导致无法被回收
        // 因此[weak self]，相当于给闭包立了个规矩 你可以远远看一下 但如果self销毁了 你内部引用就可能变为 nil
        let swiftUIView = PopoverView{ [weak self] in
            self?.hidePopover(nil)
            onOpenMainWindow() // 调用外部传进来的逻辑，唤醒 Flutter 主窗口
        }
        // 【关键桥接】：Popover 是旧 AppKit 体系的容器，不能直接装 SwiftUI。
        // NSHostingController 相当于一个“适配器外壳”，把 SwiftUI 包装成传统的 NSViewController 塞进 Popover
        
        if let button = statusItem.button {
            // 设置自定义图标 accessibilityDescription 表示无障碍提示
            button.image = NSImage(
                systemSymbolName: "character.book.closed", accessibilityDescription: "Translator")
            // 类似前端绑定事件监听('click', event) 只不过obj-c/swift将其拆分为target和action
            // target 表示触发事件的目标 action 表示绑定的事件
            button.target = self
            // #selector 是固定写法 用于传递方法名
            // 因为swift支持函数重载 (_:) 表示根据参数匹配对应函数
            button.action = #selector(togglePopover(_:))
        }
        
        // 监听全局鼠标点击事件：当用户点击屏幕其它任意区域时收起 Popover
        eventMonitor = NSEvent.addGlobalMonitorForEvents(
            // swift 中 enum枚举 可以用fn(p:.c)的形式直接传入最后一位 不用写前缀 因为编译器会自动类型推断
            // 但只有 OptionSet选项集 才能用[.b, .c]的形式
            matching: [.leftMouseDown, .rightMouseDown],
            // swift 中对象有个属性记录该引用数量 当为0时 GC 会进行回收
            // swift 中闭包语法 { [捕获列表] (参数列表) -> 返回值类型 in 执行代码 }
            // [捕获列表] 引用外部变量时使用 不写[...]表示默认强引用 即只要闭包存活就一直引用外部变量 导致无法被回收
            // 因此[weak self]，相当于给闭包立了个规矩 你可以远远看一下 但如果self销毁了 你内部引用就可能变为 nil
            handler: { [weak self] event in
                // 因此需要 guard 语句 它的 else 代码块必须以某种方式中断或跳出当前作用域
                guard let cusSelf = self else { return }
                if cusSelf.popover.isShown {
                    // 如果此时弹窗正在显示，则调用隐藏方法
                    cusSelf.hidePopover(event)
                }
            })
    }
    
    // 类被销毁时触发
    deinit {
        // 如果监听器存在，安全注销全局鼠标监听，防止内存泄漏或无效回调
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
    
    // 切换 Popover 的显隐
    // @objc 表示将该 Swift 方法暴露给底层的 Objective-C
    @objc func togglePopover(_ sender: AnyObject?) {
        // AnyObject 表示限制类型只能是class类
        if popover.isShown {
            hidePopover(sender)
        } else {
            showPopover(sender)
        }
    }
    
    func showPopover(_ sender: AnyObject?) {
        guard let button = statusItem.button else { return }
        // 在状态栏按钮下方弹出气泡
        // relativeTo: 对准该控件的哪块具体定位
        // of: 贴在哪个控件上
        // preferredEdge: 从控件的哪条边伸出小箭头
        // .bounds：控件的中心点
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        // 激活当前应用并让窗口成为 Key Window（获得焦点）
        // 如果不做这步，Flutter 内部的 TextField / 输入框无法立即捕获键盘输入
        NSApp.activate(ignoringOtherApps: true)
        // contentViewController 气泡（NSPopover）承载的Flutter 视图控制器
        // view 控制器管理的根视图
        // window macOS 的 NSPopover 弹出时，系统内部会为它创建一个专属的半透明/特殊样式的独立窗口
        // makeKey 调用该窗口的方法，将其设为应用程序当前的 Key Window
        popover.contentViewController?.view.window?.makeKey()
    }
    func hidePopover(_ sender: AnyObject?) {
        // 原生调用关闭弹窗气泡
        popover.performClose(sender)
    }
}
