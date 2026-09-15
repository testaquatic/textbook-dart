/// 앱 전용 기본 예외 클래스
class AppException implements Exception {
  final String message;
  final int statusCode;
  final String? code;

  const AppException({
    required this.message,
    required this.statusCode,
    this.code,
  });
}

class NotFoundException extends AppException {
  const NotFoundException(String message)
    : super(message: message, statusCode: 404, code: 'NOT_FOUND');
}

class ValidationException extends AppException {
  const ValidationException(String message)
    : super(message: message, statusCode: 422, code: 'VALIDATION_ERROR');
}

class UnauthorizedException extends AppException {
  const UnauthorizedException([String message = '인증이 필요합니다'])
    : super(message: message, statusCode: 401, code: 'UNAUTHORIZED');
}

class ForbiddenException extends AppException {
  const ForbiddenException([String message = '권한이 없습니다'])
    : super(message: message, statusCode: 403, code: 'FORBIDDEN');
}
