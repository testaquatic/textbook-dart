import 'package:shelf/shelf.dart';
import 'package:todo_server_shelf/exceptions.dart';

/// /todos 경로에 인증을 적용하는 미들웨어
/// /lib/middleware/auth_middleware.dart 로 이동하는게 맞는지도 모르겠다.
Handler todosAutuMiddleware(Handler handler) {
  return (Request request) async {
    // Preflight OPTIONS 요청 및 GET 요청은 인증 없이 통과
    if (request.method == "OPTIONS" || request.method == "GET") {
      return handler(request);
    }

    final authHeader = request.headers['Authorization'];

    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      throw const UnauthorizedException();
    }

    final token = authHeader.substring(7);
    if (token.isEmpty) {
      throw const UnauthorizedException('유효하지 않은 토큰입니다');
    }

    return handler(request);
  };
}
