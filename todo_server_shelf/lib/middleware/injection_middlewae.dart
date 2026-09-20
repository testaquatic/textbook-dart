import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:todo_server_shelf/exceptions.dart';
import 'package:todo_server_shelf/utils/request_utils.dart';

/// 의존성을 주입하는 미들웨어
/// 타입의 이름이 겹치면 오류가 발생한다.
Middleware injectState<T extends Object>(T object) {
  return (Handler handler) {
    return (Request request) async {
      final newRequest = request.provideState(object);
      return handler(newRequest);
    };
  };
}

T getState<T extends Object>(Request request) {
  final objectTypeString = T.toString();
  final object = request.context[objectTypeString];

  if (object == null) {
    throw const AppException(
      message: 'internalServerError',
      statusCode: HttpStatus.internalServerError,
    );
  }

  if (object is! T) {
    throw const AppException(
      message: 'internalServerError',
      statusCode: HttpStatus.internalServerError,
    );
  }

  return object;
}
