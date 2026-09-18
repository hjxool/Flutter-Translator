import 'package:flutter_translator/models/request.dart';

class Word {
  final int id;
  final String word;
  final String phonetic;
  final String definition;
  final String translation;
  final String tag;
  final String exchange;

  Word({
    required this.id,
    required this.word,
    required this.phonetic,
    required this.definition,
    required this.translation,
    required this.tag,
    required this.exchange,
  });

  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      id: json['id'] as int? ?? 0,
      word: json['word'] as String? ?? '',
      phonetic: json['phonetic'] as String? ?? '',
      definition: json['definition'] as String? ?? '',
      translation: json['translation'] as String? ?? '',
      tag: json['tag'] as String? ?? '',
      exchange: json['exchange'] as String? ?? '',
    );
  }

  // 将换行符拼接的释义拆分成列表
  List<String> get translationLines {
    if (translation.isEmpty) return [];
    // where 相当于 JS中filter
    return translation
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  // 将 'zk gk 4 6 ky' 映射为中文标签
  List<String> get tagLabels {
    if (tag.isEmpty) return [];
    const tagDict = {
      'zk': '中考',
      'gk': '高考',
      '4': '四级',
      '6': '六级',
      'ky': '考研',
      'toefl': '托福',
      'ielts': '雅思',
      'gre': 'GRE',
    };
    return tag
        .split(' ')
        .where((s) => s.isNotEmpty)
        .map((s) => tagDict[s] ?? s.toUpperCase())
        .toList();
  }

  // 将 'p:registered/d:registered/i:registering' 拆解为时态字典
  Map<String, String> get parsedExchanges {
    if (exchange.isEmpty) return {};
    const labelMap = {
      'p': '过去式',
      'd': '过去分词',
      'i': '现在分词',
      '3': '第三人称单数',
      'r': '比较级',
      't': '最高级',
      's': '复数',
    };
    final map = <String, String>{};
    final parts = exchange.split('/');
    for (final part in parts) {
      final kv = part.split(':');
      if (kv.length == 2 && labelMap.containsKey(kv[0])) {
        map[labelMap[kv[0]]!] = kv[1];
      }
    }
    return map;
  }
}

class WordApi {
  WordApi._(); // 构造函数私有化 防止创建实例

  static Future<List<Word>> searchWords(String keyword) async {
    final query = keyword.trim();
    if (query.isEmpty) return [];
    final data = await Request.get(
      '/search',
      queryParameters: {'keyword': query},
    );
    // 从接口获取的数据是json 也就是dynamic 做一下简单的校验
    if (data is! List) return [];
    // whereType 遍历数组每一项 判断是否符合传入的泛型 从而过滤杂质
    return data.whereType<Map<String, dynamic>>().map(Word.fromJson).toList();
  }

  static Future<Word?> getWordDetail(String word) async {
    word = word.trim();
    if (word.isEmpty) return null;
    final data = await Request.get('/word/$word');
    if (data == null) return null;
    return Word.fromJson(data);
  }
}
