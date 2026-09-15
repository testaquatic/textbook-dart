import 'package:dart_frog/dart_frog.dart';
import 'package:todo_server/src/middleware/cors_middleware.dart';
import 'package:todo_server/src/middleware/error_middlware.dart';
import 'package:todo_server/src/middleware/logging_middleware.dart';

Handler middleware(Handler handler) {
  return handler
      .use(errorHandler())
      .use(requestLogging())
      .use(
        cors(allowedOrigins: ['http://localhost:3000', 'https://yourapp.com']),
      );
}
