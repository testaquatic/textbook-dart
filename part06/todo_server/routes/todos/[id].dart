import 'package:dart_frog/dart_frog.dart';
import 'package:todo_server/src/dto/todo_dto.dart';
import 'package:todo_server/src/exceptions.dart';
import 'package:todo_server/src/utils/response_utils.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  final todoId = int.tryParse(id);
  if (todoId == null) {
    return Response.json(
      statusCode: 400,
      body: {'error': '유효하지 않은 ID 입니다.'},
    );
  }

  return switch (context.request.method) {
    HttpMethod.get => _getTodo(context, todoId),
    HttpMethod.put => _updateTodo(context, todoId),
    HttpMethod.delete => _deleteTodo(context, todoId),
    _ => Response(statusCode: 405),
  };
}

Future<Response> _getTodo(RequestContext context, int id) async {
  // DB 연동 예정
  if (id > 2) {
    return Response.json(statusCode: 404, body: {'error': '할 일을 찾을 수 없습니다.'});
  }

  final todo = {
    'id': id,
    'title': '할 일 $id',
    'completed': false,
  };

  return okResponse(todo);
}

Future<Response> _updateTodo(RequestContext context, int id) async {
  final json = await context.request.json() as Map<String, dynamic>;
  final request = UpdateTodoRequest.fromJson(json);

  if (id > 2) {
    throw const NotFoundException('할 일을 찾을 수 없습니다.');
  }

  final updated = {
    'id': id,
    'title': request.title ?? '할 일 $id',
    'completed': request.completed ?? false,
    'updatedAt': DateTime.now().toIso8601String(),
  };

  return okResponse(updated);
}

Future<Response> _deleteTodo(RequestContext context, int id) async {
  if (id > 2) {
    throw const NotFoundException('할 일을 찾을 수 없습니다.');
  }
  return noContentResponse();
}
