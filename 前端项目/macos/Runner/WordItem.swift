// 基础工具库 提供字符串处理、数据解析等核心功能
import Foundation

// 给已有类型加扩展功能
extension String {
  func trim() -> String {
    // 去掉字符串首尾多余的空格
    return self.trimmingCharacters(in: .whitespaces)
  }
  func replace(_ of: String, _ with: String) -> String {
    // 把字符串里的旧文字（of）替换为新文字（with）
    return self.replacingOccurrences(of: of, with: with)
  }
}

// 通用响应包装结构，对应后端的 {"head":{...},"body":T} 格式
// JSONDecoder 解码时会自动忽略结构体中未声明的字段（如 head），只取 body
// Decodable协议 表示能够被解码/反序列化
// T: Decodable 表示 T 的类型必须具备被解码的能力
struct ApiResponse<T: Decodable>: Decodable {
  let body: T
}

// 对应后端返回的单词结构
// Decodable：允许将网络传回的 JSON 格式文本全自动转化为 Swift 变量
// Identifiable：给列表组件使用，表明每个单词都有独一无二的编号（id），方便界面渲染
struct WordItem: Decodable, Identifiable {
  let id: Int
  let word: String
  let phonetic: String
  let translation: String
  let tag: String
  let exchange: String
  
  // 计算属性：列表单行简略释义预览
  // 计算属性完整写法 var xxx: Type { get { ... } set { ... } }
  // 仅有get时简写 var xxx: Type { ... return val }
  // 仅有get且只有单行简写 var xxx: Type { 表达式 }
  var displayTranslation: String {
    return translation
    // 替换字符
      .replace("\\r\\n", "\n")
      .replace("\\n", "\n")
    // 以换行为切割点，把长文本切成数组（每一行是一项）
      .components(separatedBy: "\n")
    // 从头往下找，取出第一行“去掉空格后不是空字符串”的内容
      .first(where: { (item: String) -> Bool in
        return !item.trim().isEmpty
      })
    ?? ""
  }
  
  // 考试标签解析（zk/gk/4/6/ky 等映射为中文）
  var tagList: [String] {
    let dict: [String: String] = [
      "zk": "中考", "gk": "高考", "4": "四级", "6": "六级",
      "ky": "考研", "toefl": "托福", "ielts": "雅思", "gre": "GRE"
    ]
    return tag.components(separatedBy: " ")
      .filter { !$0.trim().isEmpty }
    // 查字典换中文，字典没收录的就转大写
      .map { dict[$0] ?? $0.uppercased() }
  }
  
  // 多行详细条目释义拆分
  var translationLines: [String] {
    return translation
      .replace("\\r\\n", "\n")
      .replace("\\n", "\n")
      .components(separatedBy: "\n")
      .map { $0.trim() }
      .filter { !$0.isEmpty }
  }
  
  // 时态及形态变换解析
  // (key: String, value: String) 是带标签元组 把少量临时字段打包在一起，不需要专门写一个完整的 struct
  var parsedExchanges: [(key: String, value: String)] {
    guard !exchange.trim().isEmpty else { return [] }
    let labelMap: [String: String] = [
      "p": "过去式", "d": "过去分词", "i": "现在分词",
      "3": "第三人称单数", "r": "比较级", "t": "最高级", "s": "复数"
    ]
    let parts = exchange.components(separatedBy: "/")
    var results: [(key: String, value: String)] = []
    for part in parts {
      let kv = part.components(separatedBy: ":")
      if kv.count == 2, let label = labelMap[kv[0]] {
        results.append((key: label, value: kv[1]))
      }
    }
    return results
  }
  
  // 时态变形预览串（例如：registered, registering, registers）
  var exchangeWordsSummary: String {
    let words = parsedExchanges.map { $0.value }
    return words.joined(separator: ", ")
  }
}
