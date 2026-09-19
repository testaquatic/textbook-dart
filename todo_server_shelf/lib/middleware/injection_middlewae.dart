import 'package:shelf/shelf.dart';

/// 의존성을 주입하는 미들웨어
/// 타입의 이름이 겹치면 오류가 발생한다.
Middleware injectState<T extends Object>(T object) {
  var objectTypeString = object.runtimeType.toString();
  return (Handler handler) {
    return (Request request) async {
      final newRequest = request.change(
        context: {...request.context, objectTypeString: object},
      );
      return handler(newRequest);
    };
  };
}

T getState<T extends Object>(Request request) {
  final objectTypeString = T.toString();
  final object = request.context[objectTypeString];

  if (object == null) {
    throw Exception('State of type $objectTypeString not found');
  }

  if (object is! T) {
    throw Exception('State of type $objectTypeString is not of type $T');
  }

  return object;
}
