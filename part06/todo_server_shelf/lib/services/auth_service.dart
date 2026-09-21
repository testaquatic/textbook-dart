import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:todo_server_shelf/dto/auth_dto.dart';
import 'package:todo_server_shelf/exceptions.dart';
import 'package:todo_server_shelf/models/user.dart';
import 'package:todo_server_shelf/repository/user_repository.dart';

class AuthService {
  AuthService({
    required UserRepository userRepository,
    required String jwtSecret,
    Duration tokenExpiry = const Duration(hours: 24),
    // ignore: prefer_initializing_formals
  }) : _userRepository = userRepository,
       // ignore: prefer_initializing_formals
       _jwtSecret = jwtSecret,
       // ignore: prefer_initializing_formals
       _tokenExpiry = tokenExpiry;

  final UserRepository _userRepository;
  final String _jwtSecret;
  final Duration _tokenExpiry;

  /// 회원가입 후 JWT를 반환한다
  Future<AuthResponse> register(AuthRequest request) async {
    // 이메일 중복 확인
    if (await _userRepository.findByEmail(request.email) != null) {
      throw const ValidationException('이미 사용 중인 이메일입니다.');
    }

    final passwordHash = _hashPassword(request.password);
    final user = await _userRepository.create(
      email: request.email,
      passwordHash: passwordHash,
    );

    final token = _generateToken(user);

    return AuthResponse(token: token, user: user.toJson());
  }

  /// 로그인 후 JWT를 반환한다.
  Future<AuthResponse> login(AuthRequest request) async {
    final user = await _userRepository.findByEmail(request.email);
    if (user == null) {
      throw const UnauthorizedException('이메일 또는 비밀번호가 올바르지 않습니다.');
    }

    if (!_verifyPassword(request.password, user.passwordHash)) {
      throw const UnauthorizedException('이메일 또는 비밀번호가 올바르지 않습니다.');
    }

    final token = _generateToken(user);

    return AuthResponse(token: token, user: user.toJson());
  }

  /// JWT를 검증하고 사용자 ID를 반환한다.
  int verifyToken(String token) {
    try {
      final jwt = JWT.verify(token, SecretKey(_jwtSecret));
      final payload = jwt.payload as Map<String, dynamic>;
      return payload['sub'] as int;
    } on JWTExpiredException {
      throw const UnauthorizedException('토큰이 만료되었습니다.');
    } on JWTException {
      throw const UnauthorizedException('유효하지 않은 토큰입니다.');
    }
  }

  String _generateToken(User user) {
    final jwt = JWT({
      'sub': user.id,
      'email': user.email,
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    });

    return jwt.sign(SecretKey(_jwtSecret), expiresIn: _tokenExpiry);
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  bool _verifyPassword(String password, String hash) {
    return _hashPassword(password) == hash;
  }

  /// 테스트 전용: 비밀번호를 해시한다
  String hashPasswordForTest(String password) {
    return _hashPassword(password);
  }
}
