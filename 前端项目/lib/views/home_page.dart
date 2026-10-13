import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_translator/providers/search.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  // 与 macOS 原生 FlutterBridge 对应的 MethodChannel
  // MethodChannel：对标 HTTP / RPC。单次请求/调用
  // EventChannel：对标 SSE
  static const MethodChannel _bridgeChannel = MethodChannel(
    'com.flutter_translator/search_bridge',
  );

  late final TextEditingController _searchController;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      // text 参数用来初始化输入框
      text: ref.read(searchProvider).keyword,
    );
    _initNativeBridge();
  }

  void _initNativeBridge() {
    // 1. 设置原生主动推送监听（应对主窗口已常驻在后台时的热同步场景）
    // Dart侧：注册监听回调 channel.setMethodCallHandler((call) async { ... })
    _bridgeChannel.setMethodCallHandler((call) async {
      // .method .arguments 都是固定写法
      if (call.method == 'syncSearch') {
        // Map.from 适合动态类型数据 进行校验
        // Map.of 适合编译期满足泛型约束
        final args = Map<String, dynamic>.from(call.arguments as Map);
        _applySync(
          keyword: args['keyword'] as String?,
          selectedWord: args['selectedWord'] as String?,
        );
      }
    });

    // 2. 首帧渲染完成后，主动向原生拉取一次可能遗留的未消费搜索词（应对冷启动场景）
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        // Dart侧：主动发起调用 channel.invokeMethod('method', args)
        // res 就是从swift中(call, result) in ... result(数据)传回的数据
        final res = await _bridgeChannel.invokeMethod<Map>('getPendingSearch');
        if (res != null) {
          final args = Map<String, dynamic>.from(res);
          _applySync(
            keyword: args['keyword'] as String?,
            selectedWord: args['selectedWord'] as String?,
          );
        }
      } catch (e) {
        debugPrint('获取初始同步单词失败: $e');
      }
    });
  }

  void _applySync({String? keyword, String? selectedWord}) {
    if (!mounted || keyword == null || keyword.isEmpty) return;

    // 取消可能正在进行的输入框防抖
    _debounceTimer?.cancel();

    // 更新输入框内容并把光标移至末尾
    _searchController.text = keyword;
    _searchController.selection = TextSelection.collapsed(
      offset: keyword.length,
    );

    // 更新 Riverpod 状态，触发搜索结果列表加载
    ref.read(searchProvider.notifier).setKeyword(keyword);

    // 如果指定了具体查看的单词，触发该单词详情加载
    if (selectedWord != null && selectedWord.isNotEmpty) {
      ref.read(searchProvider.notifier).selectWord(selectedWord);
    }
  }

  @override
  void dispose() {
    _bridgeChannel.setMethodCallHandler(null);
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // 输入防抖处理 延迟提交给 Notifier 触发接口搜索
  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      ref.read(searchProvider.notifier).setKeyword(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Row(
        children: [
          // 左侧栏
          SizedBox(width: 260, child: _buildLeftSidebar(colorScheme)),
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: colorScheme.outlineVariant,
          ),
          // 右侧词典详情区
          Expanded(child: _buildRightDetail(colorScheme)),
        ],
      ),
    );
  }

  // 搜索输入框
  Widget _buildSearchBox(ColorScheme colorScheme) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      alignment: Alignment.center,
      child: Container(
        height: 30,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Expanded(
              // child: Text(
              //   'register',
              //   style: TextStyle(color: colorScheme.onSurface, fontSize: 13),
              // ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: TextStyle(color: colorScheme.onSurface, fontSize: 13),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  // 减少默认高度与内边距 配合自定义高度
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 6),
                ),
              ),
            ),
            InkWell(
              onTap: () {
                _searchController.clear();
                ref.read(searchProvider.notifier).clear();
              },
              child: Icon(Icons.clear, size: 14, color: colorScheme.outline),
            ),
          ],
        ),
      ),
    );
  }

  // 左侧边栏（搜索框 + 词条列表）
  Widget _buildLeftSidebar(ColorScheme colorScheme) {
    final searchResultsAsync = ref.watch(searchListProvider);
    final selectedWord = ref.watch(
      searchProvider.select((state) => state.selectedWord),
    );

    return Container(
      color: colorScheme.surfaceContainerLow,
      child: Column(
        children: [
          // 搜索输入框
          _buildSearchBox(colorScheme),
          Divider(height: 1, thickness: 1, color: colorScheme.outlineVariant),
          // 搜索匹配出的单词列表
          Expanded(
            child: searchResultsAsync.when(
              loading: () => const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    '加载失败: $error',
                    style: TextStyle(color: colorScheme.error, fontSize: 12),
                  ),
                ),
              ),
              data: (data) {
                if (data.isEmpty) {
                  return Center(
                    child: Text(
                      '暂无匹配单词',
                      style: TextStyle(
                        color: colorScheme.outline,
                        fontSize: 12,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final item = data[index];
                    final isSelected =
                        item.word.toLowerCase() == selectedWord.toLowerCase();
                    return InkWell(
                      onTap: () {
                        ref.read(searchProvider.notifier).selectWord(item.word);
                      },
                      child: Container(
                        color: isSelected
                            ? colorScheme.secondaryContainer
                            : Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 2, right: 6),
                              child: Icon(
                                Icons.article_outlined,
                                size: 13,
                                color: isSelected
                                    ? colorScheme.onSecondaryContainer
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.word,
                                    style: TextStyle(
                                      color: isSelected
                                          ? colorScheme.onSecondaryContainer
                                          : colorScheme.onSurface,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.displayTranslation,
                                    // 最大显示行数 配合overflow
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isSelected
                                          ? colorScheme.onSecondaryContainer
                                                .withValues(alpha: 0.8)
                                          : colorScheme.onSurfaceVariant,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 右侧词条详情展示区
  Widget _buildRightDetail(ColorScheme colorScheme) {
    final detailAsync = ref.watch(wordDetailProvider);

    return Container(
      color: colorScheme.surface,
      child: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            '详情加载失败: $error',
            style: TextStyle(color: colorScheme.error),
          ),
        ),
        data: (data) {
          if (data == null) {
            return Center(
              child: Text(
                '未找到单词详情',
                style: TextStyle(color: colorScheme.outline),
              ),
            );
          }
          final tagList = data.tagLabels;
          final translations = data.translationLines;
          final exchanges = data.parsedExchanges;
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            children: [
              // 单词大标题
              Text(
                data.word,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              // 音标与按钮
              if (data.phonetic.isNotEmpty) ...[
                Row(
                  children: [
                    _buildPhonetic(
                      icon: Icons.volume_up_outlined,
                      label: data.phonetic.startsWith('/')
                          ? data.phonetic
                          : '/${data.phonetic}/',
                      colorScheme: colorScheme,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              // 标签
              if (tagList.isNotEmpty) ...[
                // Wrap 相当于自动换行的Row
                Wrap(
                  spacing: 6, // 主轴 相邻元素间距
                  runSpacing: 4, // 交叉轴
                  children: tagList
                      .map(
                        (tag) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 10,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 20),
              ],
              // 英汉-汉英词典
              _buildSectionHeader('英汉-汉英词典', colorScheme: colorScheme),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: translations
                    .map(
                      (line) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          line,
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              // 时态及变形展示
              if (exchanges.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildSectionHeader('时态与形态变换', colorScheme: colorScheme),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: exchanges.entries
                      .map(
                        (e) => Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '${e.key}: ',
                                style: TextStyle(
                                  color: colorScheme.outline,
                                  fontSize: 12,
                                ),
                              ),
                              TextSpan(
                                text: e.value,
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  // 音标
  Widget _buildPhonetic({
    required IconData icon,
    required String label,
    required ColorScheme colorScheme,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: colorScheme.primary),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
        ),
      ],
    );
  }

  // 词典分类标题
  Widget _buildSectionHeader(String title, {required ColorScheme colorScheme}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          Icon(
            Icons.keyboard_arrow_up,
            size: 16,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
