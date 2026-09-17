import 'package:dart_frog/dart_frog.dart';
import 'package:todo_server/src/dto/todo_dto.dart';
import 'package:todo_server/src/todo_repositories/todo_repository.dart';
import 'package:todo_server/src/utils/query_params.dart';
import 'package:todo_server/src/utils/response_utils.dart';

Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.get => _getTodos(context),
    HttpMethod.post => _createTodo(context),
    _ => Response(statusCode: 405),
  };
}

Future<Response> _getTodos(RequestContext context) async {
  final repo = context.read<TodoRepository>();
  final params = context.request.uri.queryParameters;

  final limit = parseIntParams(params, 'limit', defaultValue: 20, max: 100);
  final offset = parseIntParams(params, 'offset', defaultValue: 0, min: 0);
  final completed = parseBoolQueryParam(params, 'completed');

  // 인증 미들웨어는 나중에 추가
  // 임시 값
  const userId = 1;

  final todos = await repo.findByUserId(
    userId,
    completed: completed,
    limit: limit,
    offset: offset,
  );
  final total = await repo.countByUserId(userId, completed: completed);

  return listResponse(
    todos.map((t) => t.toJson()).toList(),
    total: total,
    page: offset ~/ limit + 1,
    limit: limit,
  );
}

Future<Response> _createTodo(RequestContext context) async {
  final repo = context.read<TodoRepository>();
  final json = await context.request.json() as Map<String, dynamic>;
  final request = CreateTodoRequest.fromJson(json);

  // 나중에 구현 예정
  const userId = 1;

  final todo = await repo.create(userId: userId, title: request.title);

  return createdResponse(todo.toJson());
}
