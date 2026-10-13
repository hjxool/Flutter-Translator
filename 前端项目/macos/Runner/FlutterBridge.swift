import FlutterMacOS
import Foundation

/// FlutterBridge：负责 macOS 原生层（SwiftUI / AppKit）与 Flutter 引擎（Dart）之间的双向通信桥接单例
class FlutterBridge: NSObject {
  // 单例模式，保证全局统一的通信句柄与状态缓存
  static let shared = FlutterBridge()

  // 与 Flutter 端绑定的通信管道
  private var channel: FlutterMethodChannel?

  // 缓存待同步的搜索数据：
  // 当主窗口尚未创建或 Flutter 页面尚未就绪时，先将数据暂存到这里，避免消息丢失
  private var pendingKeyword: String?
  private var pendingSelectedWord: String?

  // 父类 NSObject 已经定义了不带参数的 init() 而父类 NSObject 的 init() 是公开的
  // 因此要实现严格单例 需要隐藏起构造函数
  private override init() {
    super.init()
  }

  /// 绑定 Flutter 引擎的二进制信使（在 FlutterViewController 加载时调用）
  func setup(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "com.flutter_translator/search_bridge",
      // Flutter 引擎二进制消息传输 绑定该通道与哪一个 Flutter 引擎实例进行绑定与通信
      binaryMessenger: messenger
    )
    self.channel = channel

    // 监听 Flutter 端发来的方法调用（处理 Flutter 主动拉取逻辑）
    // Swift侧：注册监听回调 channel.setMethodCallHandler { (call, result) in ... }
    channel.setMethodCallHandler { [weak self] (call, result) in
      guard let self = self else { return }

      if call.method == "getPendingSearch" {
        // Flutter 页面初始化完成时主动拉取是否有待同步的单词
        if let keyword = self.pendingKeyword {
          // result：闭包 定义为 (Any?) -> Void 给 Flutter 端返回响应
          // 这里[...]是传入字典
          result([
            "keyword": keyword,
            "selectedWord": self.pendingSelectedWord ?? "",
          ])
          // 消费完毕后立即清空暂存区，防止后续重复消费
          self.pendingKeyword = nil
          self.pendingSelectedWord = nil
        } else {
          // 有这个方法 但当前没有待消费数据
          result(nil)
        }
      } else {
        // 压根没有这个方法时
        // 必须调用 result，防止 Dart 端 await 永远挂死
        // 传回 FlutterMethodNotImplemented 时Flutter会把它识别为未实现错误，并在 Dart 端直接抛出异常
        // 所以flutter端实现时用try catch进行包裹
        result(FlutterMethodNotImplemented)
      }
    }
  }

  /// 浮窗触发：将正在查询的单词同步传递给 Flutter 主窗口
  /// - Parameters:
  ///   - keyword: 输入框的搜索词或选中的单词名
  ///   - selectedWord: 当前选中的单词详情（若未点开详情则为 nil）
  func syncSearch(keyword: String, selectedWord: String?) {
    // 1. 先存入暂存区（兜底冷启动与尚未渲染完成的场景）
    self.pendingKeyword = keyword
    self.pendingSelectedWord = selectedWord

    // 2. 如果通道已经就绪，立即推送到 Flutter（主窗口常驻在后台的热唤醒场景）
    // Swift侧：channel.invokeMethod("method", arguments: ...)
    channel?.invokeMethod(
      "syncSearch",
      arguments: [
        "keyword": keyword,
        "selectedWord": selectedWord ?? "",
      ])
  }
}
