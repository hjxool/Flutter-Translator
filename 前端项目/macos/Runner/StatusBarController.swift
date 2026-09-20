// 得手动引入 不会根据联想自动引入
import Cocoa
import FlutterMacOS

class StatusBarController {
  // 变量名: 类型
  private var statusBar: NSStatusBar
  private var statusItem: NSStatusItem
  private var popover: NSPopover
  // 同dart语法 ？表示可空null
  private var eventMonitor: Any?

  // init 相当于构造函数
  // _ 表示调用该方法时可省略外部参数名 因为swift中 fn(a:type) 调用时必须fn(a:value) 而加了_ 即按顺序传入参数
  init(_ popover: NSPopover) {
    // 内部使用依然要用形参名
    // self 相当于 this 同名冲突时必须加 self
    self.popover = popover

    // 获取系统顶部状态栏，并创建一个根据内容自适应宽度的 Item
    // NSStatusBar 是整个 macOS 状态栏的管理类 system 是该类的一个全局单例
    statusBar = NSStatusBar.system
    // statusBar.statusItem 表示在系统状态栏借个地方放图标 variableLength 表示自适应长度
    statusItem = statusBar.statusItem(withLength: NSStatusItem.variableLength)

    // 配置状态栏按钮
    // 同go语法 判断时声明局部常量 因为statusItem.button可能为空 在赋值同时判断是否为空 为空则不执行
    // swift中let是常量 var是变量
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
          self.hidePopover(event)
        }
      })
  }

  // 类被销毁时触发
  deinit {
    // 如果监听器存在，安全注销全局鼠标监听，防止内存泄漏或无效回调
    if let monitor = eventMonitor {
      body
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
    // relativeTo: 参考相对位置（按钮的边界）
    // of: 依附的视图（按钮自身）
    // preferredEdge: .minY 表示向下展开
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
