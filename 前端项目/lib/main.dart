import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_translator/views/home_page.dart';

void main() {
  runApp(const ProviderScope(child: App()));
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF1E88E5); // 基础种子主题色

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // 跟随系统 会固定切换来自theme/darkTheme的主题色
      themeMode: ThemeMode.system,
      // 浅色主题
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light, // 声明当前的界面基调
        ),
      ),
      // 深色主题
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
      ),
      home: HomePage(),
    );
  }
}
