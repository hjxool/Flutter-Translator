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
}

class WordApi {
  WordApi._(); // 构造函数私有化 防止创建实例

  static Future<List<Word>> searchWords(String keyword) async {
    final query = keyword.trim();
    if (query.isEmpty) return [];
    final data = await Request.get<List<Word>>('/api/search?keyword=$query');
    if (data == null) return [];
    return data;
  }

  static Future<Word?> getWordDetail(String word) async {
    word = word.trim();
    if (word.isEmpty) return null;
    final data = await Request.get('/api/word/$word');
  }
}
