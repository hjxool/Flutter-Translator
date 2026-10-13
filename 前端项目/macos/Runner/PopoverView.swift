// 引入苹果声明式 UI 开发框架（类似前端的 React 或 Flutter）
import SwiftUI

// 动态测量内部视图实际高度的 PreferenceKey
struct ContentHeightPreferenceKey: PreferenceKey {
  static var defaultValue: CGFloat = 0
  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value = max(value, nextValue())
  }
}

// SwiftUI 中，每一个界面组件都是一个遵循 View 协议的 struct
// struct A: B 其中B必须是协议，因为 struct 永远不能继承任何类，也不能被继承 含义是遵循/实现了协议 B
struct PopoverView: View {
  // @State：响应式状态定义 加了它就可以用 $属性 来双向绑定
  // 类似 React 的 useState，一旦这些变量值改变，界面上引用它们的部分会自动重新渲染
  @State private var searchText: String = ""
  // key: [Type] 是类型标注 [Type] 表示存放Type类型的数组 = [] 赋初值
  @State private var searchResults: [WordItem] = []  // 搜索结果列表
  @State private var selectedWord: WordItem? = nil  // 当前选中的单词详情（为 nil 时展示列表，不为 nil 时原地展示详情）
  @State private var isSearching: Bool = false  // 是否正在搜索中
  // Task<Success, Failure> 表示执行成功返回 以及执行失败返回
  // Never 表示绝不会报错崩溃而结束
  @State private var debounceTask: Task<Void, Never>? = nil  // 防抖任务句柄

  // 动态测量内部内容高度，实现自适应展开
  @State private var dynamicContentHeight: CGFloat = 60
  // 最大滚动高度限制（超过此高度才开启滚动）
  private let maxScrollHeight: CGFloat = 400

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
  // : View表示Body遵循View协议 本质表达的是"一个东西内部包含的组件，在行为和规范上与它自己属于同一类抽象"
  // 之所以是body: some View而不是body: Body 是为了用some View屏蔽复杂的Body类型实现
  // some 是修饰关键字 表示不透明类型 some + View 表示实现了 View 协议的某种具体静态类型
  // View 单独拿出来是协议（Protocol）Swift 中，不能把带关联类型的协议直接当作普通类型来用
  // 界面主体 (body) 所有 SwiftUI 界面的布局都在 body 属性中描述
  var body: some View {
    // VStack = 垂直线性布局（从上往下排布），内部子元素间距 10pt
    // swift 中规定函数的最后一个参数是回调函数时 可以把{}写在()外部
    // 完整写法其实是 VStack.init(spacing:10, content: {闭包})
    // init 是构造函数 但可以省略
    VStack(spacing: 10) {
      // 顶部：搜索栏（支持返回按钮与清除按钮）
      HStack(spacing: 8) {
        // 如果当前正处于单词详情模式，左侧显示返回列表按钮
        if selectedWord != nil {
          Button(action: {
            // action接收回调函数 withAnimation是显式动画函数 让“数据变化”所引发的所有界面变动以平滑过渡的方式呈现
            withAnimation(.easeInOut(duration: 0.2)) {
              selectedWord = nil
            }
          }) {
            Image(systemName: "chevron.left")
              .font(.system(size: 13, weight: .semibold))
              .foregroundStyle(.secondary)
          }
          .buttonStyle(.plain)
          .help("返回搜索结果")
        } else {
          Image(systemName: "magnifyingglass")
            .foregroundStyle(.secondary)
        }

        // text 参数用于实现双向数据绑定
        TextField("输入要查询的内容...", text: $searchText)
          .textFieldStyle(.plain)  // 去掉默认边框
          .font(.system(size: 14))  // font接收的是Font结构体实例 system 表示字体来源
          // 已经能根据of: searchText推断类型 闭包内形参就不用写类型
          // 参数列表不写类型 就可以省略括号
          .onChange(of: searchText) { _, newVal in
            // 用户输入发生变化时，退出详情页，切回搜索列表
            if selectedWord != nil {
              selectedWord = nil
            }

            debounceTask?.cancel()
            // 检查输入内容
            guard !newVal.trim().isEmpty else {
              searchResults = []
              return
            }
            debounceTask = Task {
              // try? 表示中途被取消了也不报错，安静退出
              try? await Task.sleep(for: .milliseconds(300))
              // 再次检查任务有没有被cancel
              // 如果已经被取消了，直接 return，不发起搜索
              guard !Task.isCancelled else { return }
              await performSearch(newVal)
            }
          }

        // 如果输入框不为空，显示一个快捷清空按钮
        if !searchText.isEmpty {
          Button(action: {
            // 因为是最后一个参数 且 也是传入回调函数所以写到外面
            searchText = ""
            selectedWord = nil
            searchResults = []
          }) {
            Image(systemName: "xmark.circle.fill")
              .foregroundStyle(.secondary)
          }
          .buttonStyle(.plain)
        }
      }
      .padding(8)  // 因为实现了ExpressibleByIntegerLiteral协议 所以可以直接传数字 而Font没有
      .background(Color(NSColor.controlBackgroundColor))
      .cornerRadius(8)

      // 中部：动态内容区（详情视图 ⇄ 搜索结果列表，自适应高度 + 设限滚动）
      ScrollView(.vertical, showsIndicators: true) {
        VStack(alignment: .leading, spacing: 8) {
          if isSearching {
            // 如果在加载中，显示系统转圈加载指示器 (Spinner)
            ProgressView("查询中...")
              .frame(maxWidth: .infinity, alignment: .center)  // 宽度撑满并居中
              .padding(.vertical, 16)
          } else if let word = selectedWord {
            // 【核心切换】：点击单词后原地展示单词详情（复用外部模块组件）
            WordDetailContentView(item: word)
          } else if searchResults.isEmpty && searchText.isEmpty {
            Text("输入单词即可快速预览释义...")
              .font(.system(size: 13))
              .foregroundColor(.secondary)
              .frame(maxWidth: .infinity, alignment: .center)
              .padding(.vertical, 12)
          } else if searchResults.isEmpty {
            Text("暂无匹配单词")
              .font(.system(size: 13))
              .foregroundColor(.secondary)
              .frame(maxWidth: .infinity, alignment: .center)
              .padding(.vertical, 16)
          } else {
            // 有结果时展示列表
            // 因为WordItem声明为Identifiable协议 因此ForEach省略了id:参数
            // 否则需要以 id: \TypeName.propertyName 或 id: \.propertyName 传参
            ForEach(searchResults) { item in
              HStack(alignment: .top, spacing: 8) {
                Image(systemName: "doc.text")
                  .font(.system(size: 11))
                  .foregroundStyle(.secondary)
                  .padding(.top, 2)
                VStack(alignment: .leading, spacing: 2) {
                  Text(item.word)
                    .font(.system(size: 13, weight: .medium))
                  Text(item.displayTranslation)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)  // 最多显示的行数
                }
                // 将HStack撑开 配合高亮使用
                Spacer()
              }
              .padding(.horizontal, 8)
              .padding(.vertical, 6)
              .clipShape(RoundedRectangle(cornerRadius: 6))  // 圆角
              .contentShape(Rectangle())  // 将整个矩形区域包括空白部分定义为可点击
              .onTapGesture {
                // 点击单词条目，原地平滑切换为详情视图
                withAnimation(.easeInOut(duration: 0.2)) {
                  selectedWord = item
                }
              }
            }
          }
        }
        .padding(4)
        // 测量内部实际渲染高度
        .background(
          GeometryReader { geo in
            Color.clear.preference(
              key: ContentHeightPreferenceKey.self,
              value: geo.size.height
            )
          }
        )
      }
      .onPreferenceChange(ContentHeightPreferenceKey.self) { newHeight in
        if abs(dynamicContentHeight - newHeight) > 1 {
          dynamicContentHeight = newHeight
        }
      }
      // 核心自适应逻辑：内容高度较小时刚好包裹内容，超出 maxScrollHeight 时固定高度并开启滚动
      .frame(height: min(max(dynamicContentHeight, 40), maxScrollHeight))

      Divider()  // 分割线

      // 底部：操作栏
      HStack {
        Text("迷你翻译")
          .font(.caption)  // 辅助说明性小字号
          .foregroundStyle(.secondary)
        Spacer()  // 弹性占位空间（弹簧），把左右两侧的内容推到最左和最右
        // 按钮：直接打开 id 为 "main-window" 的 Flutter 大窗口，并同时关闭当前状态栏弹窗
        Button(action: {
          // 1. 同步当前浮窗中正在查询或查看的单词到主界面
          let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)  // 输入框文本
          // 浮窗是否点击具体单词 如果没选则退而求其次使用输入框文本
          let keywordToSync = selectedWord?.word ?? trimmedSearch
          let wordToSelect = selectedWord?.word

          if !keywordToSync.isEmpty {
            // 输入框有内容就同步
            FlutterBridge.shared.syncSearch(
              keyword: keywordToSync,
              selectedWord: wordToSelect
            )
          }

          // 2. 打开独立主窗口
          openWindow(id: "main-window")
          // 3. 激活应用到前台，避免窗口位于其他应用背后
          NSApp.activate(ignoringOtherApps: true)
          // 4. 将弹窗状态置为 false，平滑关闭状态栏小气泡浮窗
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
    // 宽度固定为 320，不再硬编码 height: 400，实现窗口完全自适应内容
    .frame(width: 320)
    .animation(.easeInOut(duration: 0.2), value: dynamicContentHeight)
    .animation(.easeInOut(duration: 0.2), value: selectedWord?.id)
    .background(.ultraThinMaterial)  // macOS 原生的超薄毛玻璃（实时模糊穿透桌面背景）
  }

  // 业务逻辑函数
  private func performSearch(_ keyword: String) async {
    // MainActor.run 表示"切换到主线程（专门负责更新界面UI的地方）"
    await MainActor.run { isSearching = true }

    // URLComponents 负责拼接 URL，queryItems 赋值时自动做 percent encoding，无需手动处理
    var components = URLComponents()
    components.scheme = "http"
    components.host = "127.0.0.1"
    components.port = 8080
    components.path = "/api/search"
    components.queryItems = [URLQueryItem(name: "keyword", value: keyword)]

    guard let url = components.url else { return }

    do {
      // URLSession 管理网络请求 shared 是默认配置单例 data 获取服务器返回的二进制数据Data
      // 返回值 二进制结果 和 网络响应(http状态码、响应头这些)
      let (data, _) = try await URLSession.shared.data(from: url)
      // ApiResponse 直接解码整个响应结构，JSONDecoder 会自动忽略 head 字段，只取 body
      // JSONDecoder 解码器将二进制json数据反序列化为模型对象
      // ApiResponse<[WordItem]> 是类型名称 decode 要求传入的是类型实例 因此Type.self获取类型的运行时实例（值）
      let response = try JSONDecoder().decode(ApiResponse<[WordItem]>.self, from: data)
      await MainActor.run {
        searchResults = response.body
        isSearching = false
      }
    } catch {
      await MainActor.run { isSearching = false }
    }
  }
}
