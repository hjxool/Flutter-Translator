import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _selectedWordIndex = 0;
  final List<Map<String, String>> _wordList = [
    {'word': 'register', 'def': 'vt. 记录；注册；登记；把...挂号；挂...'},
    {'word': 'registror', 'def': 'n. 暂存器'},
    {'word': 'register-translator', 'def': '寄存译码器;记发器-转发器'},
    {'word': 'register-sender', 'def': '记录发送机'},
  ];

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
              child: Text(
                'register',
                style: TextStyle(color: colorScheme.onSurface, fontSize: 13),
              ),
            ),
            Icon(Icons.clear, size: 14, color: colorScheme.primary),
          ],
        ),
      ),
    );
  }

  // 左侧边栏（搜索框 + 词条列表）
  Widget _buildLeftSidebar(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.surfaceContainerLow,
      child: Column(
        children: [
          // 搜索输入框
          _buildSearchBox(colorScheme),
          Divider(
            height: 1,
            thickness: 1,
            color: colorScheme.outlineVariant,
          ),
          // 搜索匹配出的单词列表
          Expanded(
            child: ListView.builder(
              itemCount: _wordList.length,
              itemBuilder: (context, index) {
                final item = _wordList[index];
                final isSelected = index == _selectedWordIndex;
                return InkWell(
                  onTap: () => setState(() => _selectedWordIndex = index),
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
                                item['word']!,
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
                                item['def']!,
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
            ),
          ),
        ],
      ),
    );
  }

  // 右侧词条详情展示区
  Widget _buildRightDetail(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.surface,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          // 单词大标题
          Text(
            'register',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          // 音标与跟读按钮
          Row(
            children: [
              _buildPhonetic(
                icon: Icons.volume_up_outlined,
                label: "英 /'redʒɪstə(r)/",
                colorScheme: colorScheme,
              ),
              const SizedBox(width: 16),
              _buildPhonetic(
                icon: Icons.volume_up_outlined,
                label: "美 /'redʒɪstər/",
                colorScheme: colorScheme,
              ),
              const SizedBox(width: 16),
              _buildActionButton(
                Icons.mic_none,
                '跟读',
                colorScheme: colorScheme,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 标签
          // Wrap 相当于自动换行的Row
          Wrap(
            spacing: 6, // 相邻元素间距
            children: ['高考', '四级', '六级', '考研']
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
          // 英汉-汉英词典
          _buildSectionHeader('英汉-汉英词典', colorScheme: colorScheme),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '1. vt. 记录；注册；登记；把...挂号；挂号邮寄；正式提出',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '2. vi. 登记；注册；挂号',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 6),
              // 富文本 传入可嵌套的TextSpan 每个都单独设置样式
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '时态: ',
                      style: TextStyle(
                        color: colorScheme.outline,
                        fontSize: 12,
                      ),
                    ),
                    TextSpan(
                      text: 'registered, registering, registers',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '形容词: ',
                      style: TextStyle(
                        color: colorScheme.outline,
                        fontSize: 12,
                      ),
                    ),
                    TextSpan(
                      text: 'registrable',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 近义、反义、联想词
          _buildSectionHeader('近义、反义、联想词', colorScheme: colorScheme),
          const SizedBox(height: 8),
          Text(
            '近义词',
            style: TextStyle(
              color: colorScheme.outline,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'n. written record, written account, timbre, timber, quality, tone, record',
            style: TextStyle(color: colorScheme.primary, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            'v. record, enter, put down, enroll, inscribe, enrol, recruit',
            style: TextStyle(color: colorScheme.primary, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            '联想词',
            style: TextStyle(
              color: colorScheme.outline,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'registration 注册;  login 进入系统;  enroll 【美】加入;  log 原木;  participate 参加, 参与;  enter 进入;  sign 符号;  submit 使服从;',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
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

  // 按钮
  Widget _buildActionButton(
    IconData icon,
    String text, {
    required ColorScheme colorScheme,
  }) {
    return Row(
      children: [
        Icon(icon, size: 13, color: colorScheme.primary),
        const SizedBox(width: 2),
        Text(
          text,
          style: TextStyle(color: colorScheme.primary, fontSize: 11),
        ),
      ],
    );
  }

  // 词典分类标题
  Widget _buildSectionHeader(
    String title, {
    required ColorScheme colorScheme,
  }) {
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
