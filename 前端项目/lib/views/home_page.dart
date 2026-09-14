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
    return Scaffold(
      body: Row(
        children: [
          // 左侧栏
          SizedBox(width: 260, child: _buildLeftSidebar()),
          const VerticalDivider(width: 1, color: Color(0xFF282828)),
          // 右侧词典详情区
          Expanded(child: _buildRightDetail()),
        ],
      ),
    );
  }

  // 搜索输入框
  Widget _buildSearchBox() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      alignment: Alignment.center,
      child: Container(
        height: 30,
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFF333333)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'register',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
            Icon(Icons.clear, size: 14, color: Colors.blue.shade300),
          ],
        ),
      ),
    );
  }

  // 左侧边栏（搜索框 + 词条列表）
  Widget _buildLeftSidebar() {
    return Container(
      color: const Color(0xFF181818),
      child: Column(
        children: [
          // 搜索输入框
          _buildSearchBox(),
          const Divider(height: 1, color: Color(0xFF282828)),
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
                        ? const Color(0xFF242424)
                        : Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2, right: 6),
                          child: Icon(
                            Icons.article_outlined,
                            size: 13,
                            color: Colors.grey,
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
                                      ? Colors.white
                                      : const Color(0xFFCCCCCC),
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
                                style: const TextStyle(
                                  color: Color(0xFF6E6E6E),
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
  Widget _buildRightDetail() {
    return Container(
      color: const Color(0xFF141414),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          // 单词大标题
          const Text(
            'register',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          // 音标与跟读按钮
          Row(
            children: [
              _buildPhonetic(
                icon: Icons.volume_up_outlined,
                label: "英 /'redʒɪstə(r)/",
              ),
              const SizedBox(width: 16),
              _buildPhonetic(
                icon: Icons.volume_up_outlined,
                label: "美 /'redʒɪstər/",
              ),
              const SizedBox(width: 16),
              _buildActionButton(Icons.mic_none, '跟读'),
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
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          // 英汉-汉英词典
          _buildSectionHeader('英汉-汉英词典'),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                '1. vt. 记录；注册；登记；把...挂号；挂号邮寄；正式提出',
                style: TextStyle(
                  color: Color(0xFFCCCCCC),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '2. vi. 登记；注册；挂号',
                style: TextStyle(
                  color: Color(0xFFCCCCCC),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 6),
              // 富文本 传入可嵌套的TextSpan 每个都单独设置样式
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '时态: ',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    TextSpan(
                      text: 'registered, registering, registers',
                      style: TextStyle(color: Colors.blueAccent, fontSize: 12),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 2),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '形容词: ',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    TextSpan(
                      text: 'registrable',
                      style: TextStyle(color: Colors.blueAccent, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 近义、反义、联想词
          _buildSectionHeader('近义、反义、联想词'),
          const SizedBox(height: 8),
          const Text(
            '近义词',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'n. written record, written account, timbre, timber, quality, tone, record',
            style: TextStyle(color: Colors.blueAccent, fontSize: 12),
          ),
          const SizedBox(height: 4),
          const Text(
            'v. record, enter, put down, enroll, inscribe, enrol, recruit',
            style: TextStyle(color: Colors.blueAccent, fontSize: 12),
          ),
          const SizedBox(height: 8),
          const Text(
            '联想词',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'registration 注册;  login 进入系统;  enroll 【美】加入;  log 原木;  participate 参加, 参与;  enter 进入;  sign 符号;  submit 使服从;',
            style: TextStyle(
              color: Color(0xFFCCCCCC),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // 音标
  Widget _buildPhonetic({required IconData icon, required String label}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.lightBlueAccent),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  // 按钮
  Widget _buildActionButton(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 13, color: Colors.lightBlueAccent),
        const SizedBox(width: 2),
        Text(
          text,
          style: const TextStyle(color: Colors.lightBlueAccent, fontSize: 11),
        ),
      ],
    );
  }

  // 词典分类标题
  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF222222), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFE0E0E0),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Icon(Icons.keyboard_arrow_up, size: 16, color: Colors.grey),
        ],
      ),
    );
  }
}
