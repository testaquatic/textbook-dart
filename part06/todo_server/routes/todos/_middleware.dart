import 'package:dart_frog/dart_frog.dart';
import 'package:todo_server/src/exceptions.dart';

/// /todos 경로에 인증을 적용하는 미들웨어
Handler middleware(Handler handler) {
  return (RequestContext context) async {
    // Preflight OPTIONS 요청 및 GET 요청은 인증 없이 통과
    if (context.request.method == HttpMethod.options ||
        context.request.method == HttpMethod.get) {
      return handler(context);
    }

    final authHeader = context.request.headers['Authorization'];

    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      throw const UnauthorizedException();
    }

    final token = authHeader.substring(7);
    if (token.isEmpty) {
      throw const UnauthorizedException('유효하지 않은 토큰입니다');
    }

    return handler(context);
  };
}
