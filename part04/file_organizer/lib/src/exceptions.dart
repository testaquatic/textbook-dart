/// 잘못된 사용법에 대한 예외
class UsageException implements Exception {
  final String message;
  final String usage;

  const UsageException(this.message, this.usage);

  @override
  String toString() => 'UsageException: $message';
}
