// 引入苹果声明式 UI 开发框架（类似前端的 React 或 Flutter）
import SwiftUI

// 单词详情内容视图（对标截屏 2026-10-10 15.59.02 样式）
struct WordDetailContentView: View {
  let item: WordItem

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      // 1. 词头
      Text(item.word)
        .font(.system(size: 20, weight: .bold))

      // 2. 音标与发音（英/美）
      if !item.phonetic.isEmpty {
        let formattedPhonetic = item.phonetic.hasPrefix("/") ? item.phonetic : "/\(item.phonetic)/"
        HStack(spacing: 16) {
          Button(action: {
            SpeechManager.shared.speak(item.word, language: "en-GB")
          }) {
            HStack(spacing: 4) {
              Image(systemName: "speaker.wave.2")
              Text("英 \(formattedPhonetic)")
            }
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
          }
          .buttonStyle(.plain)

          Button(action: {
            SpeechManager.shared.speak(item.word, language: "en-US")
          }) {
            HStack(spacing: 4) {
              Image(systemName: "speaker.wave.2")
              Text("美 \(formattedPhonetic)")
            }
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
          }
          .buttonStyle(.plain)
        }
      }

      // 3. 考试/分类标签
      if !item.tagList.isEmpty {
        HStack(spacing: 6) {
          // \.xxx 表示访问某个属性的一条路径规则 是独立的引用对象
          // .xxx 表示直接获取具体内容 或者已知枚举类型的值
          ForEach(item.tagList, id: \.self) { tag in
            Text(tag)
              .font(.system(size: 10, weight: .medium))
              .padding(.horizontal, 6)
              .padding(.vertical, 2)
              .background(Color.secondary.opacity(0.15))
              .cornerRadius(4)
          }
        }
      }

      Divider().padding(.vertical, 2)

      // 4. 英汉－汉英词典折叠标题栏
      HStack(spacing: 6) {
        Image(systemName: "chevron.down.square.fill")
          .font(.system(size: 12))
          .foregroundStyle(.secondary)
        Text("英汉－汉英词典")
          .font(.system(size: 12, weight: .semibold))
      }

      // 5. 分条释义列表
      VStack(alignment: .leading, spacing: 6) {
        ForEach(Array(item.translationLines.enumerated()), id: \.offset) { index, line in
          Text("\(index + 1). \(line)")
            .font(.system(size: 13))
            .lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)
        }
      }

      // 6. 时态及派生词展示
      if !item.exchangeWordsSummary.isEmpty {
        HStack(alignment: .top, spacing: 4) {
          Text("时态:")
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
          Text(item.exchangeWordsSummary)
            .font(.system(size: 12))
            .foregroundStyle(Color.accentColor)
        }
      }
    }
    .padding(.horizontal, 6)
    .padding(.vertical, 4)
  }
}
