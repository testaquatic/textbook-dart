import 'package:dart_frog/dart_frog.dart';
import 'package:todo_server/src/exceptions.dart';

/// 예외를 잡아 표준화된 에러 응답으로 반환한다.
Middleware errorHandler() {
  return (Handler handler) {
    return (RequestContext context) async {
      try {
        return await handler(context);
      } on AppException catch (e) {
        return Response.json(
          statusCode: e.statusCode,
          body: {
            'error': e.message,
            'code': e.code,
          },
        );
      } on FormatException catch (e) {
        return Response.json(
          statusCode: 400,
          body: {'error': '잘못된 요청 형식: ${e.message}'},
        );
      } catch (e, st) {
        print('내부 서버 오류: $e\n$st');
        return Response.json(
          statusCode: 500,
          body: {'error': '내부 서버 오류가 발생했습니다.'},
        );
      }
    };
  };
}
