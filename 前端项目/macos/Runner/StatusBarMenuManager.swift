import Cocoa
import SwiftUI

/// StatusBarMenuManager：以 AppKit 为底管理系统状态栏图标与浮窗
/// 实现功能：
/// 1. 左键点击状态栏图标：展开/收起以 SwiftUI 填充的 PopoverView 查词浮窗
/// 2. 右键点击状态栏图标：弹出原生系统菜单（不影响左键点击弹出查词浮窗）
/// 3. 功能开关项（划词取词、鼠标悬停取词、快捷键截图翻译）以“勾选/取消勾选”状态呈现，并持久化到 UserDefaults
/// 4. 分隔线隔开各业务开关
/// 5. 底部放置“退出应用”选项（带 Cmd+Q 提示），彻底退出整个应用进程
// 继承 NSObject 说明使用的是 macOS 传统的 AppKit 框架（命令式 UI）
class StatusBarMenuManager: NSObject {
  // 单例模式，确保全局唯一的状态栏菜单句柄
  static let shared = StatusBarMenuManager()

  // AppKit 原生状态栏图标对象
  private var statusItem: NSStatusItem?
  // AppKit 原生气泡浮窗容器（内部填充 SwiftUI）
  private var popover = NSPopover()
  // NSHostingController 必须作为类属性强引用保留，否则 setup() 执行完后 ARC 会立即释放它
  // 导致 popover.contentViewController 变成悬空引用，进而使状态栏图标不响应甚至消失
  // 悬空引用：引用的内存被回收了 但指针本身没有被清指向一片虚无空间
  private var popoverHostingController: NSHostingController<PopoverView>?
  // NSMenu 是 macOS 原生 AppKit 框架中的菜单容器对象 屏幕顶部的主菜单栏、Dock 图标弹出的右键菜单，还是状态栏托盘图标的下拉菜单，底层都是 NSMenu
  private var contextMenu = NSMenu()

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

  // MARK: - 初始化绑定
  /// 启动配置：以 AppKit 为底创建状态栏图标，配置 NSPopover（由 SwiftUI 填充）和右键菜单
  func setup() {
    // 1. 创建 AppKit 原生状态栏条目
    // squareLength = 正方形宽度，适合只放图标；variableLength = 由内容自动决定宽度
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    self.statusItem = item

    print("[StatusBar] statusItem created: \(item)")
    print("[StatusBar] button: \(String(describing: item.button))")

    if let button = item.button {
      let icon = NSImage(
        systemSymbolName: "character.book.closed",
        accessibilityDescription: "Translator"
      )
      print("[StatusBar] icon from systemSymbolName: \(String(describing: icon))")

      if let icon = icon {
        // 正常情况：用 SF Symbol 图标，设为 template 模式以适配 macOS 深色/浅色外观
        icon.isTemplate = true
        button.image = icon
      } else {
        // 兜底：SF Symbol 加载失败时，用文字代替确保图标可见
        button.title = "译"
      }

      button.target = self
      button.action = #selector(handleStatusItemClick(_:))
      // 开启支持响应左键和右键抬起事件
      button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    } else {
      print("[StatusBar] ⚠️ button is nil！状态栏条目创建失败")
    }


    // 2. 配置 AppKit 浮窗容器 (NSPopover)
    popover.behavior = .transient  // 点击浮窗外部区域时系统自动平滑收起
    popover.animates = true

    // 【以 AppKit 为底，SwiftUI 填充】：使用 NSHostingController 将纯 SwiftUI 编写的 PopoverView 挂载入 AppKit 浮窗中
    let hostingController = NSHostingController(
      rootView: PopoverView(onClose: { [weak self] in
        self?.closePopover()
      })
    )
    // 必须强引用到类属性，防止 setup() 返回后 ARC 立即释放这个局部变量
    // 若不保留，popover.contentViewController 会变成悬空引用
    popoverHostingController = hostingController
    // contentViewController 必须是 NSViewController，通过 NSHostingController 将其转换
    // contentViewController 其特殊性导致赋值无法增加强引用ARC计数
    popover.contentViewController = hostingController

    // 3. 构建右键原生菜单
    buildMenu()
  }

  // MARK: - 左右键点击分发
  @objc private func handleStatusItemClick(_ sender: NSStatusBarButton) {
    guard let event = NSApp.currentEvent else { return }

    // 判断是否为右键或按住 Control 键的左键点击
    let isRightClick = event.type == .rightMouseUp
    let isControlLeftClick = event.type == .leftMouseUp && event.modifierFlags.contains(.control)

    if isRightClick || isControlLeftClick {
      // 如果左键浮窗正在展开，先平滑收起它
      closePopover()
      // 弹出右键菜单
      showContextMenu(for: sender)
    } else {
      // 普通左键点击：切换 SwiftUI 浮窗显示/收起
      togglePopover(sender)
    }
  }

  // MARK: - Popover 显隐控制
  func togglePopover(_ sender: NSStatusBarButton) {
    if popover.isShown {
      closePopover()
    } else {
      // 确保应用激活到前台，避免浮窗处于失焦状态
      NSApp.activate(ignoringOtherApps: true)
      popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
    }
  }

  func closePopover() {
    if popover.isShown {
      popover.performClose(nil)
    }
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

  private func showContextMenu(for button: NSStatusBarButton) {
    refreshMenuCheckmarks()

    // 1. 临时挂载菜单到 statusItem
    statusItem?.menu = contextMenu
    // 2. 触发系统原生状态栏菜单弹出（内部会同步阻塞直到菜单关闭）
    button.performClick(nil)
    // 3. 菜单关闭后立即清空，完全不影响后续左键点击弹出 SwiftUI PopoverView
    statusItem?.menu = nil
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
