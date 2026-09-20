import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:todo_server_shelf/utils/response_utils.dart';

import '../exceptions.dart';

/// 예외를 잡아 표준화된 에러 응답으로 반환한다.
Middleware errorHandler() {
  return (Handler handler) {
    return (Request request) async {
      try {
        return await handler(request);
      } on AppException catch (e) {
        return jsonResponse(
          statusCode: e.statusCode,
          json: {'error': e.message, 'code': e.code},
        );
      } on FormatException catch (e) {
        return jsonResponse(
          statusCode: HttpStatus.badRequest,
          json: {'error': '잘못된 요청 형식: ${e.message}'},
        );
      } catch (e, st) {
        print('내부 서버 오류: $e\n$st');
        return jsonResponse(
          statusCode: HttpStatus.internalServerError,
          json: {'error': '내부 서버 오류가 발생했습니다.'},
        );
      }
    };
  };
}
