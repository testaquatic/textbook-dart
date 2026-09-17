import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:todo_server_shelf/database.dart';
import 'package:todo_server_shelf/handler/todos/index.dart';
import 'package:todo_server_shelf/middleware/cors_middleware.dart';
import 'package:todo_server_shelf/repository/todo_repository.dart';
import 'package:todo_server_shelf/repository/user_repository.dart';

// Configure routes.
final _router = Router()
  ..get('/echo/<message>', _echoHandler)
  ..all('/todos', onRequest);

Response _echoHandler(Request request) {
  final message = request.params['message'];
  return Response.ok('$message\n');
}

void main(List<String> args) async {
  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.anyIPv4;

  final db = Database.open("1.db");
  final todoRepo = TodoRepository(db);
  final userRepo = UserRepository(db);

  print(db);
  print(todoRepo);
  print(userRepo);

  // Configure a pipeline that logs requests.
  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(
        cors(allowedOrigins: ['http://localhost:3000', 'https://yourapp.com']),
      )
      .addMiddleware((Handler handler) {
        return (Request request) async {
          var req = request.change(
            context: {
              ...request.context,
              ...{'todoRepo': todoRepo, 'userRepo': userRepo},
            },
          );
          return handler(req);
        };
      })
      .addHandler(_router.call);

  // For running in containers, we respect the PORT environment variable.
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, ip, port);
  print('Server listening on port ${server.port}');
}
