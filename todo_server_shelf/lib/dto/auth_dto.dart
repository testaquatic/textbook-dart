import 'package:todo_server_shelf/exceptions.dart';

/// 회원가입/로그인 요청 DTO
class AuthRequest {
  factory AuthRequest.fromJson(Map<String, dynamic> json) {
    final email = json['email'] as String?;
    final password = json['password'] as String?;

    if (email == null || email.trim().isEmpty) {
      throw const ValidationException('email이 필요합니다');
    }
    if (!_isValidEmail(email)) {
      throw const ValidationException('올바른 이메일 형식이 아닙니다.');
    }
    if (password == null || password.isEmpty) {
      throw const ValidationException('password가 필요합니다.');
    }
    if (password.length < 8) {
      throw const ValidationException('password는 8자 이상이어야 합니다.');
    }

    return AuthRequest(email: email.trim().toLowerCase(), password: password);
  }
  const AuthRequest({required this.email, required this.password});

  final String email;
  final String password;

  static bool _isValidEmail(String email) {
    return RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(email);
  }
}

/// 회원가입/로그인 응답 DTO
class AuthResponse {
  const AuthResponse({required this.token, required this.user});

  final String token;
  final Map<String, dynamic> user;

  Map<String, dynamic> toJson() => {'token': token, 'user': user};
}
