import 'package:shelf/shelf.dart';

/// CORS 헤더를 추가하는 미들웨어
Middleware cors({
  List<String> allowedOrigins = const ['*'],
  List<String> allowedMethods = const [
    'GET',
    'POST',
    'PUT',
    'DELETE',
    'OPTIONS',
  ],
  List<String> allowedHeaders = const ['Content-Type', 'Authorization'],
}) {
  return (Handler handler) {
    return (Request request) async {
      final origin = request.headers['Origin'] ?? '*';
      final isAllowed =
          allowedOrigins.contains('*') || allowedOrigins.contains(origin);

      final corsResponseHeaders = {
        'Access-Control-Allow-Origin': isAllowed ? origin : '',
        'Access-Control-Allow-Methods': allowedMethods.join(', '),
        'Access-Control-Allow-Headers': allowedHeaders.join(', '),
        'Access-Control-Max-Age': '86400',
      };

      if (request.method == "OPTIONS") {
        return Response(204, headers: corsResponseHeaders);
      }

      final response = await handler(request);

      return response.change(
        headers: {...response.headers, ...corsResponseHeaders},
      );
    };
  };
}
