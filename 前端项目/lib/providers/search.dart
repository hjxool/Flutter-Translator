// 定义状态结构
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
