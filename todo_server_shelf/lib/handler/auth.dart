import 'package:shelf/shelf.dart';
import 'package:todo_server_shelf/dto/auth_dto.dart';
import 'package:todo_server_shelf/middleware/injection_middlewae.dart';
import 'package:todo_server_shelf/services/auth_service.dart';
import 'package:todo_server_shelf/utils/request_utils.dart';
import 'package:todo_server_shelf/utils/response_utils.dart';

Future<Response> register(Request request) async {
  final json = await request.json();
  final authRequest = AuthRequest.fromJson(json);

  final authService = getState<AuthService>(request);
  final response = await authService.register(authRequest);

  return createdResponse(response.toJson());
}

Future<Response> login(Request request) async {
  final json = await request.json();
  final loginRequest = AuthRequest.fromJson(json);

  final authService = getState<AuthService>(request);
  final response = await authService.login(loginRequest);

  return okResponse(response.toJson());
}
