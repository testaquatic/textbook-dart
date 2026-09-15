import 'package:dart_frog/dart_frog.dart';

/// 성공 응답을 표준 형식으로 반환한다.
Response okResponse(dynamic data) {
  return Response.json(body: {'data': data, 'success': true});
}

/// 생성 성공 응답(201)
Response createdSuccess(dynamic data) {
  return Response.json(
    statusCode: 201,
    body: {'data': data, 'success': true},
  );
}

/// 목록 응답(페이지네이션 포함)
Response listResponse(
  List<dynamic> items, {
  int? total,
  int? page,
  int? limit,
}) {
  return Response.json(
    body: {
      'data': items,
      'success': true,
      'meta': {
        if (total != null) 'total': total,
        if (page != null) 'page': page,
        if (limit != null) 'limit': limit,
      },
    },
  );
}

/// 204 No Content (삭제 성공 등)
Response noContentResponse() {
  return Response(statusCode: 204);
}
