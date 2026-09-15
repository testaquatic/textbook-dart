import 'package:dart_frog/dart_frog.dart';

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
    return (RequestContext context) async {
      final origin = context.request.headers['Origin'] ?? '*';
      final isAllowed =
          allowedOrigins.contains('*') || allowedOrigins.contains(origin);

      final corsResponseHeaders = {
        'Access-Control-Allow-Origin': isAllowed ? origin : '',
        'Access-Control-Allow-Methods': allowedMethods.join(', '),
        'Access-Control-Allow-Headers': allowedHeaders.join(', '),
        'Access-Control-Max-Age': '86400',
      };

      if (context.request.method == HttpMethod.options) {
        return Response(statusCode: 204, headers: corsResponseHeaders);
      }

      final response = await handler(context);

      // 기존 헤더에 CORS 헤더 추가
      return response.copyWith(
        headers: {...response.headers, ...corsResponseHeaders},
      );
    };
  };
}
