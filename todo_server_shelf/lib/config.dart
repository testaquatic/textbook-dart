import 'dart:io';

/// 애플리케이션 설정
class AppConfig {
  const AppConfig._({
    required this.jwtSecret,
    required this.dbPath,
    required this.port,
  });

  final String jwtSecret;
  final String dbPath;
  final int port;

  /// 환경 변수에서 설정을 로드한다.
  factory AppConfig.fromEnvironment() {
    final jwtSecret = Platform.environment['JWT_SECRET'];
    if (jwtSecret == null || jwtSecret.isEmpty) {
      throw StateError(
        'JWT_SECRET 환경 변수가 설정되지 않았습니다.\n'
        '예: export JWT_SECRET="your-secret-key-at-least-32-chars',
      );
    }

    if (jwtSecret.length < 32) {
      throw StateError('JWT_SECRET는 최소 32자 이상이어야 합니다.');
    }

    return AppConfig._(
      jwtSecret: jwtSecret,
      dbPath: Platform.environment['DB_PATH'] ?? 'todo.db',
      port: int.tryParse(Platform.environment['PORT'] ?? '8080') ?? 8080,
    );
  }
}
