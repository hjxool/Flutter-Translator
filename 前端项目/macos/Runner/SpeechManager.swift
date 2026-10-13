// 官方的音视频多媒体框架（提供文字转语音的能力）
import AVFoundation

// 系统原生语音朗读单例管理（避免局部对象提前销毁导致发音中断）
class SpeechManager {
  // 唯一的全局访问点
  static let shared = SpeechManager()
  private let synthesizer = AVSpeechSynthesizer()

  // 私有化构造函数，禁止外部通过 init() 实例化
  private init() {}

  func speak(_ text: String, language: String = "en-US") {
    // 状态检查：如果播音员正在说话，先立刻打断停止，防止声音重叠
    if synthesizer.isSpeaking {
      synthesizer.stopSpeaking(at: .immediate)
    }
    // 把普通文字包装成一段“台词对象”（AVSpeechUtterance）
    let utterance = AVSpeechUtterance(string: text)
    // 设置发音语言
    utterance.voice = AVSpeechSynthesisVoice(language: language)
    utterance.rate = 0.45  // 设置语速
    synthesizer.speak(utterance)  // 命令合成器开始发音朗读
  }
}
