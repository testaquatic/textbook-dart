import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:sqflite_common_ffi/sqflite_common_ffi.dart'
    as sqflite_common_ffi;
import 'package:todo_server_shelf/database.dart';
import 'package:todo_server_shelf/middleware/cors_middleware.dart';
import 'package:todo_server_shelf/middleware/error_middleware.dart';
import 'package:todo_server_shelf/repository/todo_repository.dart';
import 'package:todo_server_shelf/repository/user_repository.dart';
import 'package:todo_server_shelf/router.dart';
import 'package:path/path.dart' as p;

void main(List<String> args) async {
  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.anyIPv4;

  sqflite_common_ffi.sqfliteFfiInit();
  final currentPath = p.join(Directory.current.path, 'todo.db');
  final db = await Database.open(currentPath);
  final todoRepo = TodoRepository(db);
  final userRepo = UserRepository(db);

  // Configure a pipeline that logs requests.
  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(errorHandler())
      .addMiddleware(
        cors(allowedOrigins: ['http://localhost:8080', 'https://yourapp.com']),
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
      .addHandler(appRouter.call);

  // For running in containers, we respect the PORT environment variable.
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, ip, port);
  print('Server listening on port ${server.port}');
}
