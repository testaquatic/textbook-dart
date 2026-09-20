import 'package:shelf/shelf.dart';
import 'package:todo_server_shelf/dto/todo_dto.dart';
import 'package:todo_server_shelf/repository/todo_repository.dart';
import 'package:todo_server_shelf/utils/query_params.dart';
import 'package:todo_server_shelf/utils/request_utils.dart';
import 'package:todo_server_shelf/utils/response_utils.dart';

Future<Response> getTodos(Request request) async {
  final repo = request.readState<TodoRepository>();
  final params = request.url.queryParameters;
  final userId = request.readState<int>();

  final limit = parseIntParams(params, 'limit', defaultValue: 20, max: 100);
  final offset = parseIntParams(params, 'offset', defaultValue: 0, min: 0);
  final completed = parseBoolQueryParam(params, 'completed');

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

Future<Response> createTodo(Request request) async {
  final repo = request.readState<TodoRepository>();
  final json = await request.json();
  final createTodoRequest = CreateTodoRequest.fromJson(json);
  final userId = request.readState<int>();

  final todo = await repo.create(
    userId: userId,
    title: createTodoRequest.title,
  );

  return createdResponse(todo.toJson());
}
