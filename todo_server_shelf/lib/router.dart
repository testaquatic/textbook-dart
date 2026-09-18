import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:todo_server_shelf/handler/todos/id/index.dart';
import 'package:todo_server_shelf/handler/todos/index.dart';
import 'package:todo_server_shelf/middleware/auth_middleware.dart';

// Configure routes.
final appRouter = Router()
  ..get('/echo/<message>', _echoHandler)
  ..mount('/todos', _todosHandler);

Response _echoHandler(Request request) {
  final message = request.params['message'];
  return Response.ok('$message\n');
}

final todosRouter = Router(notFoundHandler: _notFoundHandler)
  ..get('/<stringId>', getTodo)
  ..put('/<stringId>', updateTodo)
  ..delete('/<stringId>', deleteTodo)
  ..get('/', getTodos)
  ..post('/', createTodo);
final _todosHandler = Pipeline()
    .addMiddleware(todosAutuMiddleware)
    .addHandler(todosRouter.call);

Response _notFoundHandler(Request _) => Response(HttpStatus.methodNotAllowed);
