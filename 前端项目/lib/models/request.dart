import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_translator/main.dart';

class Request {
  Request._();

  static final Dio _dio =
      Dio(
          BaseOptions(
            baseUrl: 'http://127.0.0.1:8080',
            connectTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 5),
            headers: {'Content-Type': 'application/json'},
          ),
        )
        ..interceptors.add(
          InterceptorsWrapper(
            // 过滤响应结果
            onResponse: (response, handler) {
              final res = response.data;
              if (res is Map) {
                final code = res['head']?['code'] ?? res['code'];
                final body = res['body'];
                // 剥离外层head 只返回布尔值或实际数据
                if (code == 200 || code == '200') {
                  response.data = body;
                } else {
                  // 业务失败 (code 为 200 以外的值)
                  final errorMsg =
                      res['head']?['message'] ?? res['message'] ?? '请求失败，请稍后重试';
                  _showErrorDialog(errorMsg.toString());
                  response.data = null;
                }
              }
              return handler.next(response);
            },
            // 处理网络请求异常 200–299 以外的响应会进入onError
            onError: (error, handler) {
              String errorMsg = '网络好像有点问题，请检查网络设置';
              if (error.type == DioExceptionType.connectionTimeout ||
                  error.type == DioExceptionType.receiveTimeout) {
                errorMsg = '网络连接超时';
              } else if (error.response != null) {
                // HTTP 状态码错误
                final responseData = error.response?.data;
                if (responseData is Map) {
                  errorMsg =
                      (responseData['head']?['message'] ??
                              responseData['message'] ??
                              '服务器异常 (${error.response?.statusCode})')
                          .toString();
                } else {
                  errorMsg = '服务器异常 (${error.response?.statusCode})';
                }
              }
              _showErrorDialog(errorMsg);
              // 将网络异常转换为普通成功响应返回 false，不再抛出异常给业务层
              return handler.resolve(
                Response(requestOptions: error.requestOptions, data: false),
              );
            },
          ),
        );

  static Future<T?> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final res = await _dio.get(
      path,
      queryParameters: queryParameters,
      options: options,
    );
    // 把data取出 避免外层每次都要then((res) => res.data)
    return res.data is T ? res.data : null;
  }

  // ⚠️ 返回值类型可能为null 所以要用T?
  static Future<T?> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    final res = await _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
    return res.data is T ? res.data : null;
  }
}

// 提取统一弹窗的私有函数
void _showErrorDialog(String message) {
  // 从全局 navigatorKey 中获取当前最顶层的 context
  final context = navigatorKey.currentContext;
  if (context == null) return;
  // 使用 WidgetsBinding 确保在当前帧渲染完成后再弹窗，防止在请求极快时与页面构建产生冲突
  // WidgetsBinding 是应用级别的绑定对象，而不是某个 Widget 的实例 用于将 Widget层和 Flutter Engine（渲染层）绑定起来
  // addPostFrameCallback 是当前帧的绘制/渲染流程完全结束后立即执行回调函数
  WidgetsBinding.instance.addPostFrameCallback((_) {
    showDialog(
      context: context,
      barrierDismissible: true, // 点击背景可以关闭
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('提示'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            // Navigator.of 找到的是和当前 BuildContext 最近的 Navigator
            // navigatorKey.currentState 操作的是全局 Navigator 用全局的容易导致路由页面也关掉
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  });
}
