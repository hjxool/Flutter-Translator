import Cocoa

/// StatusBarMenuManager：专门负责顶部状态栏图标右键菜单的管理类
/// 实现功能：
/// 1. 右键点击状态栏图标时，弹出原生系统菜单（不影响左键点击弹出查词浮窗）
/// 2. 功能开关项（划词取词、鼠标悬停取词、快捷键截图翻译）以“勾选/取消勾选”状态呈现，并持久化到 UserDefaults
/// 3. 分隔线隔开各业务开关
/// 4. 底部放置“退出应用”选项（带 Cmd+Q 提示），彻底退出整个应用进程
// 继承 NSObject 说明使用的是 macOS 传统的 AppKit 框架（命令式 UI）
// 因为SwiftUI的 MenuBarExtra 存在严重的局限性 无法区分鼠标左右键
class StatusBarMenuManager: NSObject {
  // 单例模式，确保全局唯一的状态栏菜单句柄
  static let shared = StatusBarMenuManager()
  // weak 声明弱引用 表示不会增加被引用对象的引用计数 当被引用的对象被系统释放销毁时，该属性会被自动置为 nil
  // 因此 weak 修饰的变量必须是 var 且必须是可选类型 ?
  private weak var statusItem: NSStatusItem?
  // NSMenu 是 macOS 原生 AppKit 框架中的菜单容器对象 屏幕顶部的主菜单栏、Dock 图标弹出的右键菜单，还是状态栏托盘图标的下拉菜单，底层都是 NSMenu
  private var contextMenu = NSMenu()
  private var eventMonitor: Any?
  private var onRightClickTriggered: (() -> Void)?

  // MARK: - 持久化配置键名定义
  private enum PrefKeys {
    static let enableSelectionPick = "enable_selection_pick"
    static let enableHoverPick = "enable_hover_pick"
    static let enableOcr = "enable_ocr"
  }

  // MARK: - 功能开关状态（绑定系统 UserDefaults，支持与 Flutter 共享）
  var isSelectionPickEnabled: Bool {
    // object 同localStorage的getItem
    get { UserDefaults.standard.object(forKey: PrefKeys.enableSelectionPick) as? Bool ?? true }
    // set 完整写法
    set(val) {
      UserDefaults.standard.set(val, forKey: PrefKeys.enableSelectionPick)
    }
  }

  var isHoverPickEnabled: Bool {
    get { UserDefaults.standard.object(forKey: PrefKeys.enableHoverPick) as? Bool ?? false }
    // set 简写
    set { UserDefaults.standard.set(newValue, forKey: PrefKeys.enableHoverPick) }
  }

  var isOcrEnabled: Bool {
    get { UserDefaults.standard.object(forKey: PrefKeys.enableOcr) as? Bool ?? true }
    set { UserDefaults.standard.set(newValue, forKey: PrefKeys.enableOcr) }
  }
  // 单例模式 隐藏起构造函数 由前面StatusBarMenuManager()调用
  private override init() {
    super.init()
  }
  // 生命周期结束前执行资源清理，避免内存泄漏或无效回调
  deinit {
    if let monitor = eventMonitor {
      NSEvent.removeMonitor(monitor)  // 移除监听器
    }
  }

  // MARK: - 初始化绑定
  /// 绑定系统状态栏项目，并配置右键监听与菜单
  /// - Parameters:
  ///   - statusItem: 由 MenuBarExtraAccess 拿到的底层 NSStatusItem 实例
  ///   - onRightClick: 右键触发时的闭包回调（例如收起左键展开的气泡浮窗）
  func setup(statusItem: NSStatusItem, onRightClick: (() -> Void)? = nil) {
    // 将传入值存起来 方便后续方法调用
    self.statusItem = statusItem
    self.onRightClickTriggered = onRightClick

    buildMenu()
    setupRightClickMonitor()
  }

  // MARK: - 构建菜单结构
  private func buildMenu() {
    // contextMenu.addItem(...) 追加元素会导致菜单里出现重复的选项
    contextMenu.removeAllItems()  // 防止菜单项被重复追加

    // 1. 划词取词开关
    let selectionItem = NSMenuItem(
      title: "划词取词",
      action: #selector(toggleSelectionPick(_:)),
      keyEquivalent: ""
    )
    selectionItem.target = self
    selectionItem.state = isSelectionPickEnabled ? .on : .off
    contextMenu.addItem(selectionItem)

    // 2. 悬停取词开关
    let hoverItem = NSMenuItem(
      title: "鼠标悬停取词",
      action: #selector(toggleHoverPick(_:)),
      keyEquivalent: ""
    )
    hoverItem.target = self
    hoverItem.state = isHoverPickEnabled ? .on : .off
    contextMenu.addItem(hoverItem)

    // 3. 快捷键截图翻译
    let ocrItem = NSMenuItem(
      title: "快捷键截图翻译",
      action: #selector(toggleOcr(_:)),
      keyEquivalent: ""
    )
    ocrItem.target = self
    ocrItem.state = isOcrEnabled ? .on : .off
    contextMenu.addItem(ocrItem)

    // 4. 分隔线：明确隔离功能开关与退出按钮
    contextMenu.addItem(NSMenuItem.separator())

    // 5. 退出当前应用（带 Command + Q 快捷键）
    let quitItem = NSMenuItem(
      title: "退出 Flutter Translator",
      action: #selector(quitApp),
      keyEquivalent: "q"
    )
    quitItem.target = self
    contextMenu.addItem(quitItem)
  }

  // MARK: - 右键事件拦截监听
  private func setupRightClickMonitor() {
    // 防止重复注册
    if let monitor = eventMonitor {
      NSEvent.removeMonitor(monitor)
    }

    // 监听本地鼠标事件：拦截右键抬起（.rightMouseUp）以及带 Control 键的左键抬起
    // 之所以用局部监视器而不是直接赋值 button.menu，是为了避免污染左键对 SwiftUI PopoverView 的正常弹出
    eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.rightMouseUp, .leftMouseUp]) {
      [weak self] event in
      guard let self = self,
        let button = self.statusItem?.button,
        event.window == button.window
      else {
        return event
      }

      // 判断是否为右键或 Control+左键
      let isRightClick = event.type == .rightMouseUp
      let isControlLeftClick = event.type == .leftMouseUp && event.modifierFlags.contains(.control)

      guard isRightClick || isControlLeftClick else {
        return event  // 普通左键点击，放行给 SwiftUI 默认逻辑（展开 PopoverView）
      }

      // 将窗口点击坐标转换为状态栏按钮自身的局部坐标
      let locationInButton = button.convert(event.locationInWindow, from: nil)
      if button.bounds.contains(locationInButton) {
        // 如果左键浮窗当前正展开着，先平滑收起它
        self.onRightClickTriggered?()

        // 弹出右键菜单
        self.showContextMenu(at: locationInButton)
        return nil  // 消费拦截该事件，不继续向后传播
      }
      return event
    }
  }

  private func showContextMenu(at point: NSPoint) {
    guard let statusItem = statusItem, let button = statusItem.button else { return }
    refreshMenuCheckmarks()

    // 1. 临时挂载菜单到 statusItem
    statusItem.menu = contextMenu
    // 2. 触发系统原生状态栏菜单弹出（内部会同步阻塞直到菜单关闭）
    button.performClick(nil)
    // 3. 菜单关闭后立即清空，完全不影响后续左键点击弹出 SwiftUI PopoverView
    statusItem.menu = nil
  }

  /// 弹出前重新同步最新的勾选状态
  private func refreshMenuCheckmarks() {
    if contextMenu.items.count >= 3 {
      contextMenu.items[0].state = isSelectionPickEnabled ? .on : .off
      contextMenu.items[1].state = isHoverPickEnabled ? .on : .off
      contextMenu.items[2].state = isOcrEnabled ? .on : .off
    }
  }

  // MARK: - 菜单项点击响应
  @objc private func toggleSelectionPick(_ sender: NSMenuItem) {
    isSelectionPickEnabled.toggle()
    sender.state = isSelectionPickEnabled ? .on : .off
  }

  @objc private func toggleHoverPick(_ sender: NSMenuItem) {
    isHoverPickEnabled.toggle()
    sender.state = isHoverPickEnabled ? .on : .off
  }

  @objc private func toggleOcr(_ sender: NSMenuItem) {
    isOcrEnabled.toggle()
    sender.state = isOcrEnabled ? .on : .off
  }

  @objc private func quitApp() {
    // 干净彻底地终止并退出应用程序进程
    NSApp.terminate(nil)
  }
}
