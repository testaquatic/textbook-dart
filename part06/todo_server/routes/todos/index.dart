import 'package:dart_frog/dart_frog.dart';
import 'package:todo_server/src/utils/response_utils.dart';

Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.get => _getTodos(context),
    HttpMethod.post => _createTodo(context),
    _ => Response(statusCode: 405),
  };
}

Future<Response> _getTodos(RequestContext context) async {
  final queryParams = context.request.uri.queryParameters;
  final completed = queryParams['completed'];
  final limit = int.tryParse(queryParams['limit'] ?? '20') ?? 20;
  final offset = int.tryParse(queryParams['offset'] ?? '0') ?? 0;

  // 나중에 DB 연동
  final todos = [
    {'id': 1, 'title': '첫 번째 할 일', 'completed': false},
    {'id': 2, 'title': '두 번째 할 일', 'completed': true},
  ];

  final filtered = completed != null
      ? todos.where((t) => t['completed'] == (completed == 'true')).toList()
      : todos;

  return listResponse(
    filtered,
    total: filtered.length,
    page: offset ~/ limit + 1,
    limit: limit,
  );
}

Future<Response> _createTodo(RequestContext context) async {
  final body = await context.request.json() as Map<String, dynamic>;
  final title = body['title'] as String?;

  if (title == null || title.isEmpty) {
    return Response.json(statusCode: 400, body: {'error': 'title은 필수입니다.'});
  }

  // 나중에 DB 연동
  final newTodo = {
    'id': 3,
    'title': title,
    'completed': false,
    'created_at': DateTime.now().toIso8601String(),
  };

  return createdSuccess(newTodo);
}
