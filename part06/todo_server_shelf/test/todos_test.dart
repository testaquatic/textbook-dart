import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';
import 'package:shelf/shelf_io.dart';
import 'package:test/test.dart';
import 'package:todo_server_shelf/config.dart';
import 'package:todo_server_shelf/database.dart';
import 'package:todo_server_shelf/dto/auth_dto.dart';

import 'package:todo_server_shelf/models/user.dart';
import 'package:todo_server_shelf/repository/todo_repository.dart';
import 'package:todo_server_shelf/repository/user_repository.dart';
import 'package:todo_server_shelf/router.dart';
import 'package:todo_server_shelf/services/auth_service.dart';

class TestContext {
  final String url;
  final TodoRepository todoRepo;
  final UserRepository userRepo;
  final AuthService authService;
  final HttpServer httpServer;
  final AppConfig appConfig;
  final String token;
  final User user;

  TestContext({
    required this.url,
    required this.todoRepo,
    required this.userRepo,
    required this.authService,
    required this.httpServer,
    required this.appConfig,
    required this.token,
    required this.user,
  });

  static Future<TestContext> init() async {
    final db = await Database.openInMemory();
    final todoRepo = TodoRepository(db);
    final userRepo = UserRepository(db);
    final appConfig = AppConfig(
      jwtSecret: "your-secret-key-at-least-32-chars",
      dbPath: "not_use",
      port: 1234,
    );
    final authService = AuthService(
      userRepository: userRepo,
      jwtSecret: appConfig.jwtSecret,
    );

    final httpServer = await serve(
      await getAppHandler(
        todoRepo: todoRepo,
        userRepo: userRepo,
        appConfig: appConfig,
      ),
      InternetAddress.anyIPv4,
      0,
    );
    final port = httpServer.port;

    const userInfo = (email: 'test@test.com', password: 'password123');
    await authService.register(
      AuthRequest(email: userInfo.email, password: userInfo.password),
    );
    final user = (await userRepo.findByEmail(userInfo.email))!;

    final loginJson = (await authService.login(
      AuthRequest(email: userInfo.email, password: userInfo.password),
    )).toJson();

    final token = loginJson['token'];

    return TestContext(
      url: 'http://localhost:$port',
      todoRepo: todoRepo,
      userRepo: userRepo,
      authService: authService,
      httpServer: httpServer,
      appConfig: appConfig,
      token: token,
      user: user,
    );
  }

  Map<String, String> bearerHeader() {
    return {'Authorization': 'Bearer $token'};
  }
}

void main() {
  group('GET /todos', () {
    test('빈 목록 반환', () async {
      final context = await TestContext.init();

      final response = await get(
        Uri.parse('${context.url}/todos'),
        headers: context.bearerHeader(),
      );
      expect(response.statusCode, HttpStatus.ok);
      final json = jsonDecode(response.body);
      expect(json['data'], isEmpty);
      expect(json['meta']['total'], 0);
    });

    test('할 일 목록 반환', () async {
      final context = await TestContext.init();
      await context.todoRepo.create(userId: context.user.id, title: '첫 번째');
      await context.todoRepo.create(userId: context.user.id, title: '두 번째');

      final response = await get(
        Uri.parse('${context.url}/todos'),
        headers: context.bearerHeader(),
      );
      expect(response.statusCode, equals(HttpStatus.ok));
      final json = jsonDecode(response.body);
      expect(json['data'], isNotEmpty);
      expect(json['meta']['total'], equals(2));
    });

    test('할 일 생성 성공', () async {
      final testContext = await TestContext.init();
      final response = await post(
        Uri.parse('${testContext.url}/todos'),
        headers: testContext.bearerHeader(),
        body: jsonEncode({'title': '새 할일'}),
      );
      expect(response.statusCode, equals(HttpStatus.created));
      final json = jsonDecode(response.body);
      expect(json['data']['title'], equals('새 할일'));
    });

    test('빈 title -> 422', () async {
      final testContext = await TestContext.init();
      final response = await post(
        Uri.parse('${testContext.url}/todos'),
        headers: testContext.bearerHeader(),
        body: jsonEncode({'title': ''}),
      );
      expect(response.statusCode, equals(HttpStatus.unprocessableEntity));
    });
  });
}
