import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:todo_server_shelf/config.dart';
import 'package:todo_server_shelf/database.dart';
import 'package:todo_server_shelf/handler/auth.dart';
import 'package:todo_server_shelf/handler/todos/id/index.dart';
import 'package:todo_server_shelf/handler/todos/index.dart';
import 'package:todo_server_shelf/middleware/auth_middleware.dart';
import 'package:todo_server_shelf/middleware/cors_middleware.dart';
import 'package:todo_server_shelf/middleware/error_middleware.dart';
import 'package:todo_server_shelf/middleware/injection_middlewae.dart';
import 'package:todo_server_shelf/repository/todo_repository.dart';
import 'package:todo_server_shelf/repository/user_repository.dart';
import 'package:todo_server_shelf/services/auth_service.dart';

Future<Handler> getAppHandler() async {
  final currentPath = p.join(Directory.current.path, 'todo.db');
  final db = await Database.open(currentPath);
  final todoRepo = TodoRepository(db);
  final userRepo = UserRepository(db);
  final appConfig = AppConfig.fromEnvironment();
  final authService = AuthService(
    userRepository: userRepo,
    jwtSecret: appConfig.jwtSecret,
  );

  // Configure routes.
  final appRouter = Router()
    ..get('/echo/<message>', _echoHandler)
    ..mount('/todos', _getTodoHandler())
    ..mount('/auth', _authHandler());

  final appHandler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(errorHandler())
      .addMiddleware(
        cors(allowedOrigins: ['http://localhost:8080', 'https://yourapp.com']),
      )
      .addMiddleware(injectState(todoRepo))
      .addMiddleware(injectState(userRepo))
      .addMiddleware(injectState(authService))
      .addHandler(appRouter.call);

  return appHandler;
}

Handler _getTodoHandler() {
  final todosRouter = Router(notFoundHandler: _notFoundHandler)
    ..get('/<stringId>', getTodo)
    ..put('/<stringId>', updateTodo)
    ..delete('/<stringId>', deleteTodo)
    ..get('/', getTodos)
    ..post('/', createTodo);

  final todosHandler = Pipeline()
      .addMiddleware(todosAutuMiddleware)
      .addHandler(todosRouter.call);

  return todosHandler;
}

Handler _authHandler() {
  final authRouter = Router(notFoundHandler: _notFoundHandler)
    ..post('/register', register)
    ..post('/login', login);

  final authHandler = Pipeline().addHandler(authRouter.call);

  return authHandler;
}

Response _echoHandler(Request request) {
  final message = request.params['message'];
  return Response.ok('$message\n');
}

Response _notFoundHandler(Request _) => Response(HttpStatus.methodNotAllowed);
