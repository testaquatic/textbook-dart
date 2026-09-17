import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:todo_server_shelf/dto/todo_dto.dart';
import 'package:todo_server_shelf/repository/todo_repository.dart';
import 'package:todo_server_shelf/utils/query_params.dart';
import 'package:todo_server_shelf/utils/response_utils.dart';

Future<Response> onRequest(Request request) async {
  return switch (request.method) {
    "GET" => _getTodos(request),
    "POST" => _createTodo(request),
    _ => Response(405),
  };
}

Future<Response> _getTodos(Request request) async {
  final repo = request.context['todoRepo'] as TodoRepository;
  final params = request.url.queryParameters;

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

Future<Response> _createTodo(Request request) async {
  final repo = request.context['todoRepo'] as TodoRepository;
  final json = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
  final createTodoRequest = CreateTodoRequest.fromJson(json);

  // 나중에 구현 예정
  const userId = 1;

  final todo = await repo.create(
    userId: userId,
    title: createTodoRequest.title,
  );

  return createdResponse(todo.toJson());
}
