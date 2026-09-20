import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';

/// JSON 응답을 생성한다.
Response jsonResponse({
  required int statusCode,
  required Object? json,
  Map<String, Object>? headers,
}) {
  final jsonHeaders = <String, Object>{
    ...?headers,
    'Content-Type': 'application/json',
  };

  return Response(statusCode, headers: jsonHeaders, body: jsonEncode(json));
}

/// 성공 응답을 표준 형식으로 반환한다.
Response okResponse(dynamic data) {
  return jsonResponse(
    statusCode: HttpStatus.ok,
    json: {'data': data, 'success': true},
  );
}

/// 생성 성공 응답(201)
Response createdResponse(dynamic data) {
  return jsonResponse(
    statusCode: HttpStatus.created,
    json: {'data': data, 'success': true},
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

  return jsonResponse(statusCode: HttpStatus.ok, json: json);
}

/// 204 No Content (삭제 성공 등)
Response noContentResponse() {
  return Response(204);
}

/// 인증 관련 응답
Response authResponse({
  required String token,
  required Map<String, Object?> user,
}) {
  return jsonResponse(
    statusCode: HttpStatus.ok,
    json: {'token': token, 'user': user},
  );
}
