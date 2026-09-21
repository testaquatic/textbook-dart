import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:todo_server_shelf/dto/auth_dto.dart';
import 'package:todo_server_shelf/exceptions.dart';
import 'package:todo_server_shelf/models/user.dart';
import 'package:todo_server_shelf/repository/user_repository.dart';
import 'package:todo_server_shelf/services/auth_service.dart';

class MockUserRepository extends Mock implements UserRepository {}

void main() {
  late MockUserRepository mockRepo;
  late AuthService authService;

  const testSecret = 'test-secret-key-must-be-at-least-32-characters-log';

  setUp(() {
    mockRepo = MockUserRepository();
    authService = AuthService(userRepository: mockRepo, jwtSecret: testSecret);
  });

  User makeUser({int id = 1, String email = 'test@example.com'}) {
    return User(
      id: id,
      email: email,
      passwordHash: authService.hashPasswordForTest('password123'),
      createdAt: DateTime(2024),
    );
  }

  group('register', () {
    test('새 사용자 등록 성공', () async {
      final user = makeUser();

      when(() => mockRepo.findByEmail(any())).thenAnswer((_) async => null);
      when(
        () => mockRepo.create(
          email: any(named: 'email'),
          passwordHash: any(named: 'passwordHash'),
        ),
      ).thenAnswer((_) async => user);

      final request = AuthRequest.fromJson({
        'email': 'test@example.com',
        'password': 'password123',
      });

      final result = await authService.register(request);
      expect(result.token, isNotEmpty);
      expect(result.user['email'], equals('test@example.com'));
    });

    test('이미 존재하는 이메일', () {
      final user = makeUser();
      when(() => mockRepo.findByEmail(any())).thenAnswer((_) async => user);

      final request = AuthRequest.fromJson({
        'email': 'test@example.com',
        'password': 'password123',
      });

      expect(
        () async => await authService.register(request),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('login', () {
    test('올바른 자격증명으로 로그인 성공', () async {
      final user = makeUser();
      when(() => mockRepo.findByEmail(any())).thenAnswer((_) async => user);

      final request = AuthRequest.fromJson({
        'email': 'test@example.com',
        'password': 'password123',
      });

      final result = await authService.login(request);
      expect(result.token, isNotEmpty);
    });

    test('존재하지 않는 이메일 -> UnauthorizedException', () {
      when(() => mockRepo.findByEmail(any())).thenAnswer((_) async => null);

      final request = AuthRequest.fromJson({
        'email': 'nonexistent@example.com',
        'password': 'password123',
      });

      expect(
        () async => await authService.login(request),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('잘못된 비밀번호 -> UnauthorizedException', () {
      final user = makeUser();
      when(() => mockRepo.findByEmail(any())).thenAnswer((_) async => user);

      final request = AuthRequest.fromJson({
        'email': 'test@example.com',
        'password': 'wrongpassword',
      });

      expect(
        () async => await authService.login(request),
        throwsA(isA<UnauthorizedException>()),
      );
    });
  });

  group('verifyToken', () {
    test('유효한 토큰 검증 성공', () async {
      final user = makeUser();
      when(() => mockRepo.findByEmail(any())).thenAnswer((_) async => null);
      when(
        () => mockRepo.create(
          email: any(named: 'email'),
          passwordHash: any(named: 'passwordHash'),
        ),
      ).thenAnswer((_) async => user);

      final request = AuthRequest.fromJson({
        'email': 'test@example.com',
        'password': 'password123',
      });
      final authResponse = await authService.register(request);

      final userId = authService.verifyToken(authResponse.token);
      expect(userId, equals(1));
    });

    test('잘못된 토큰 -> UnauthorizedException', () async {
      expect(
        () => authService.verifyToken('invalid token'),
        throwsA(isA<UnauthorizedException>()),
      );
    });
  });
}
