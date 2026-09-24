// swift-tools-version: 5.9
import PackageDescription

// 有这个文件联想功能才能正常使用，并且创建完要cmd + shift + p 输入Developer: Reload Window重新加载窗口才能生效
// targets 中列出源文件路径，SourceKit-LSP 才能索引这些 Swift 文件，从而支持跳转定义和代码补全
let package = Package(
  name: "WorkspaceFix",
  defaultLocalization: "en",  // 如果项目默认是中文可以改成 "zh-Hans"
  products: [],
  targets: [
    .target(
      name: "macOSRunner",
      path: "前端项目/macos/Runner"
    )
  ]
)
