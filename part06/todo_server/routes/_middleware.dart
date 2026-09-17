import 'package:dart_frog/dart_frog.dart';
import 'package:todo_server/src/database.dart';
import 'package:todo_server/src/middleware/cors_middleware.dart';
import 'package:todo_server/src/middleware/error_middlware.dart';
import 'package:todo_server/src/middleware/logging_middleware.dart';
import 'package:todo_server/src/todo_repositories/todo_repository.dart';
import 'package:todo_server/src/todo_repositories/user_repository.dart';

final _db = Database.open('todo.db');

Handler middleware(Handler handler) {
  return handler
      .use(errorHandler())
      .use(requestLogging())
      .use(
        cors(
          allowedOrigins: ['http://localhost:3000', 'https://yourapp.com'],
        ),
      )
      .use(provider<Database>((_) => _db))
      .use(
        provider<TodoRepository>((c) => TodoRepository(c.read<Database>())),
      )
      .use(
        provider<UserRepository>((c) => UserRepository(c.read<Database>())),
      );
}
