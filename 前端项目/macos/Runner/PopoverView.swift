// 引入苹果声明式 UI 开发框架（类似前端的 React 或 Flutter）
import SwiftUI

// SwiftUI 中，每一个界面组件都是一个遵循 View 协议的 struct
// struct A: B 其中B必须是协议，因为 struct 永远不能继承任何类，也不能被继承 含义是遵循/实现了协议 B
struct PopoverView: View {
  // @State：响应式状态定义 加了它就可以用 $属性 来双向绑定
  // 类似 React 的 useState，一旦这些变量值改变，界面上引用它们的部分会自动重新渲染
  @State private var searchText: String = ""
  @State private var translationResult: String = "输入单词即可快速预览释义..."
  @State private var isSearching: Bool = false

  // @Binding：双向绑定状态，由外部（App/Scene 级）传入，用于控制当前状态栏弹窗的展开与关闭
  // @State 负责分配和管理真实内存 @Binding 自身只持有一对读写操作管道
  // @State 和 @Binding大多数情况下就是成对搭配出现 @State 创建并拥有真实数据（分配内存、负责存储）@Binding 声明，接收外层传进来的绑定（不分配独立数据内存、负责委托修改）
  @Binding var isMenuPresented: Bool

  // 类似抽象方法 定义接口规格，推迟具体实现 外部使用PopoverView时必须提供回调实现
  // var onOpenMainWindow: () -> Void
  // @Environment 借用系统API \.openWindow 是系统的KeyPath表示激活新窗口的能力
  // SwiftUI 底层，有一个巨大的全局字典型容器存放了所有系统级的环境信息 openWindow 是该仓库中的工具
  // EnvironmentValues.openWindow 取出来的并不是普通函数，而是struct
  // openWindow(id) 实际上是执行 openWindow.callAsFunction(id)
  // callAsFunction 是语法糖 在类型（struct、class 甚至 enum）中实现了 func callAsFunction(...)
  // 该类型的具体实例就可以直接加上括号像函数一样被调用 类似TS、Dart中的fn.call call被简写了而已
  @Environment(\.openWindow) private var openWindow

  // protocol View 中 associatedtype Body: View 其中associatedtype是泛型关键字 Body是声明的类型
  // : View表示Body遵循View协议 本质表达的是“一个东西内部包含的组件，在行为和规范上与它自己属于同一类抽象”
  // 之所以是body: some View而不是body: Body 是为了用some View屏蔽复杂的Body类型实现
  // some 是修饰关键字 表示不透明类型 some + View 表示实现了 View 协议的某种具体静态类型
  // View 单独拿出来是协议（Protocol）Swift 中，不能把带关联类型的协议直接当作普通类型来用
  // 界面主体 (body) 所有 SwiftUI 界面的布局都在 body 属性中描述
  var body: some View {
    // VStack = 垂直线性布局（从上往下排布），内部子元素间距 12pt
    // swift 中规定函数的最后一个参数是回调函数时 可以把{}写在()外部
    // 完整写法其实是 VStack.init(spacing:12, content: {闭包})
    // init 是构造函数 但可以省略
    VStack(spacing: 12) {
      // 顶部：搜索栏
      HStack {
        Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
        // text 参数用于实现双向数据绑定
        TextField("输入要查询的内容...", text: $searchText)
          .textFieldStyle(.plain)  // 去掉默认边框
          .font(.system(size: 14))  // font接收的是Font结构体实例 system 表示字体来源
          .onSubmit {
            // 监听回车按键
            performSearch()
          }
        // 如果输入框不为空，显示一个快捷清空按钮
        if !searchText.isEmpty {
          Button(action: { searchText = "" }) {
            // 因为是最后一个参数 且 也是传入回调函数所以写到外面
            Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
          }.buttonStyle(.plain)
        }
      }
      .padding(8)  // 因为实现了ExpressibleByIntegerLiteral协议 所以可以直接传数字 而Font没有
      .background(Color(NSColor.controlBackgroundColor))
      .cornerRadius(8)

      // 中部：释义展示卡片
      ScrollView {
        VStack(alignment: .leading, spacing: 8) {
          if isSearching {
            // 如果在加载中，显示系统转圈加载指示器 (Spinner)
            ProgressView("查询中...")
              .frame(maxWidth: .infinity, alignment: .center)  // // 宽度撑满并居中
              .padding(.top, 20)
          } else {
            // 正常状态显示翻译结果
            Text(translationResult)
              .font(.system(size: 13))
              .lineSpacing(4)  // 行间距
              .foregroundStyle(.primary)
              .frame(maxWidth: .infinity, alignment: .leading)
          }
        }
        .padding(4)
      }
      .frame(maxHeight: .infinity)  // 撑满剩余垂直高度

      Divider()  // 分割线

      // 底部：操作栏
      HStack {
        Text("迷你翻译")
          .font(.caption)  // 辅助说明性小字号
          .foregroundStyle(.secondary)
        Spacer()  // 弹性占位空间（弹簧），把左右两侧的内容推到最左和最右
        // 按钮：直接打开 id 为 "main-window" 的 Flutter 大窗口，并同时关闭当前状态栏弹窗
        Button(action: {
          // 1. 打开独立主窗口
          openWindow(id: "main-window")
          // 2. 激活应用到前台，避免窗口位于其他应用背后
          NSApp.activate(ignoringOtherApps: true)
          // 3. 将弹窗状态置为 false，平滑关闭状态栏小气泡浮窗
          isMenuPresented = false
        }) {
          HStack(spacing: 4) {
            Text("打开完整主窗口")
            Image(systemName: "arrow.up.forward.app")  // 右上角箭头图标
          }
          .font(.caption)
        }
        .buttonStyle(.link)  // 超链接样式的按钮（蓝色下划线交互感）
      }
    }
    // 整窗修饰符
    .padding(14)
    .frame(width: 320, height: 400)
    .background(.ultraThinMaterial)  // macOS 原生的超薄毛玻璃（实时模糊穿透桌面背景）
  }

  // 业务逻辑函数
  private func performSearch() {
    // 去除首尾空格后如果为空，则直接退出不请求
    // trimmingCharacters string结构体自带的方法 whitespaces 表示空格
    guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
    // 进入加载状态，界面立刻切为 ProgressView 转圈
    isSearching = true
    Task {
      // 挂起当前任务 0.6 秒（非阻塞等待）
      // try 是简写do catch try? 表示不在乎错误是什么 报错则返回nil 正常则返回原本值
      try? await Task.sleep(for: .seconds(0.6))
      // 模板字符串 \(表达式)
      self.translationResult = "【原生释义】\(self.searchText)\n1. n. 原生渲染示例；\n2. v. 脱离 Flutter 独立在平台渲染。"
      self.isSearching = false  // 关闭加载转圈
    }
  }
}
