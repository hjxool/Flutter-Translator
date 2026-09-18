// Notifier 处理接口数据/业务逻辑交互 UI界面处理界面交互
// models 定义数据模型 以及提供dynamic接口数据转换为数据模型的方法

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_translator/models/words.dart';

// 定义状态结构
class SearchState {
  final String keyword; // 输入框搜索词
  final String selectedWord; // 当前选中的单词

  const SearchState({this.keyword = '', this.selectedWord = ''});

  SearchState copyWith({String? keyword, String? selectedWord}) {
    return SearchState(
      keyword: keyword ?? this.keyword,
      selectedWord: selectedWord ?? this.selectedWord,
    );
  }
}

// 封装可变动作
class SearchNotifier extends Notifier<SearchState> {
  @override
  SearchState build() => const SearchState();

  // 更新搜索关键字
  void setKeyword(String newKeyword) {
    state = state.copyWith(keyword: newKeyword);
  }

  // 选中列表中的某个单词
  void selectWord(String word) {
    state = state.copyWith(selectedWord: word);
  }

  // 清空搜索框
  void clear() {
    state = state.copyWith(keyword: '');
  }
}

// 泛型参数分别代表“管状态的人”和“被管理的数据”
// SearchNotifier.new的写法是默认未命名构造函数的显式引用 即没有构造函数的类默认会有个无参数的构造函数 为了显式说调用了它就要用.new的形式
final searchProvider = NotifierProvider<SearchNotifier, SearchState>(
  SearchNotifier.new,
);

// 外层提供防抖这里是公用的
class SearchListNotifier extends AsyncNotifier<List<Word>> {
  @override
  FutureOr<List<Word>> build() async {
    // FutureOr 表示返回值既可以是同步的 T，也可以是异步的 Future<T>
    // 监听 keyword 自动执行搜索
    final keyword = ref.watch(searchProvider.select((state) => state.keyword));
    if (keyword.trim().isEmpty) return [];
    return WordApi.searchWords(keyword);
  }
}

final searchListProvider =
    AsyncNotifierProvider<SearchListNotifier, List<Word>>(
      SearchListNotifier.new,
    );

class WordDetailNotifier extends AsyncNotifier<Word?> {
  @override
  FutureOr<Word?> build() async {
    // 监听 selectedWord，一旦用户点击了新单词，自动重新拉取详情
    final selectedWord = ref.watch(
      searchProvider.select((state) => state.selectedWord),
    );
    if (selectedWord.trim().isEmpty) return null;
    return WordApi.getWordDetail(selectedWord);
  }
}

final wordDetailProvider = AsyncNotifierProvider<WordDetailNotifier, Word?>(
  WordDetailNotifier.new,
);
