import 'package:dart_frog/dart_frog.dart';
import 'package:todo_server/src/dto/todo_dto.dart';
import 'package:todo_server/src/exceptions.dart';
import 'package:todo_server/src/todo_repositories/todo_repository.dart';
import 'package:todo_server/src/utils/response_utils.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  final todoId = int.tryParse(id);
  if (todoId == null) {
    throw const ValidationException('유효하지 않은 ID입니다.');
  }

  return switch (context.request.method) {
    HttpMethod.get => _getTodo(context, todoId),
    HttpMethod.put => _updateTodo(context, todoId),
    HttpMethod.delete => _deleteTodo(context, todoId),
    _ => Response(statusCode: 405),
  };
}

Future<Response> _getTodo(RequestContext context, int id) async {
  final repo = context.read<TodoRepository>();
  final todo = await repo.findById(id);
  if (todo == null) {
    throw const NotFoundException('할 일을 찾을 수 없습니다.');
  }

  return okResponse(todo.toJson());
}

Future<Response> _updateTodo(RequestContext context, int id) async {
  final repo = context.read<TodoRepository>();
  final json = await context.request.json() as Map<String, dynamic>;
  final request = UpdateTodoRequest.fromJson(json);

  final updated = await repo.update(
    id: id,
    title: request.title,
    completed: request.completed,
  );

  return okResponse(updated.toJson());
}

Future<Response> _deleteTodo(RequestContext context, int id) async {
  // 없으면 NotFoundException 던짐
  await context.read<TodoRepository>().delete(id);

  return noContentResponse();
}
