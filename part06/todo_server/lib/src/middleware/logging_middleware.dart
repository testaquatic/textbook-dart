import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

/// 요청/응답을 로깅하는 미들웨어
Middleware requestLogging() {
  return (Handler handler) {
    return (RequestContext context) async {
      final start = DateTime.now();
      final request = context.request;

      final response = await handler(context);

      final elapsed = DateTime.now().difference(start).inMilliseconds;
      final method = request.method.value.padLeft(7);
      final status = response.statusCode;
      final path = request.uri.path;
      final statusColor = _statusColor(status);

      stderr.writeln(
        '$statusColor[$status]\x1B[0m $method $path (${elapsed}ms)',
      );

      return response;
    };
  };
}

String _statusColor(int status) {
  // 초록
  if (status < 300) {
    return '\x1B[32m';
  }
  // 노랑
  if (status < 400) {
    return '\x1B[33m';
  }

  // 빨강
  return '\x1B[31m';
}
