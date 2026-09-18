import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:todo_server_shelf/dto/todo_dto.dart';
import 'package:todo_server_shelf/exceptions.dart';
import 'package:todo_server_shelf/repository/todo_repository.dart';
import 'package:todo_server_shelf/utils/response_utils.dart';

Future<Response> getTodo(Request request, String stringId) async {
  final id = int.tryParse(stringId);
  if (id == null) {
    throw const ValidationException('유효하지 않은 ID입니다.');
  }
  final repo = request.context['todoRepo'] as TodoRepository;
  final todo = await repo.findById(id);
  if (todo == null) {
    throw const NotFoundException('할 일을 찾을 수 없습니다.');
  }

  return okResponse(todo.toJson());
}

Future<Response> updateTodo(Request request, String stringId) async {
  final id = int.tryParse(stringId);
  if (id == null) {
    throw const ValidationException('유효하지 않은 ID입니다.');
  }

  final repo = request.context['todoRepo'] as TodoRepository;
  final json = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
  final updateRequest = UpdateTodoRequest.fromJson(json);

  final updated = await repo.update(
    id: id,
    title: updateRequest.title,
    completed: updateRequest.completed,
  );

  return okResponse(updated.toJson());
}

Future<Response> deleteTodo(Request request, String stringId) async {
  final id = int.tryParse(stringId);
  if (id == null) {
    throw const ValidationException('유효하지 않은 ID입니다.');
  }
  // 없으면 NotFoundException 던짐
  await (request.context['todoRepo'] as TodoRepository).delete(id);

  return noContentResponse();
}
