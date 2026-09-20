import 'package:shelf/shelf.dart';
import 'package:todo_server_shelf/exceptions.dart';
import 'package:todo_server_shelf/services/auth_service.dart';
import 'package:todo_server_shelf/utils/request_utils.dart';

/// /todos 경로에 인증을 적용하는 미들웨어
/// /lib/middleware/auth_middleware.dart 로 이동하는게 맞는지도 모르겠다.
Handler todosAutuMiddleware(Handler handler) {
  return (Request request) async {
    final authHeader = request.headers['Authorization'];

    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      throw const UnauthorizedException();
    }

    final token = authHeader.substring(7);
    if (token.isEmpty) {
      throw const UnauthorizedException('유효하지 않은 토큰입니다');
    }

    final authService = request.readState<AuthService>();

    // JWT 검증 및 userId 추출
    final userId = authService.verifyToken(token);

    // userId를 다운스트림 핸들러에 주입
    return handler(request.provideState(userId));
  };
}
