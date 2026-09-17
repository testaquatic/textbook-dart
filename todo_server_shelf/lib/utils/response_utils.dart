import 'dart:convert';

import 'package:shelf/shelf.dart';

/// 성공 응답을 표준 형식으로 반환한다.
Response okResponse(dynamic data) {
  return Response(
    200,
    headers: {'Content-Type': 'application/json'},
    body: {'data': jsonEncode(data), 'success': true},
  );
}

/// 생성 성공 응답(201)
Response createdResponse(dynamic data) {
  return Response(
    201,
    headers: {'Content-Type': 'application/json'},
    body: {'data': jsonEncode(data), 'success': true},
  );
}

/// 목록 응답(페이지네이션 포함)
Response listResponse(
  List<dynamic> items, {
  int? total,
  int? page,
  int? limit,
}) {
  var json = {
    'data': items,
    'success': true,
    'meta': {'total': ?total, 'page': ?page, 'limit': ?limit},
  };

  return Response(
    200,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(json),
  );
}

/// 204 No Content (삭제 성공 등)
Response noContentResponse() {
  return Response(204);
}
