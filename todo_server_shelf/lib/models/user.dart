class User {
  const User({
    required this.id,
    required this.email,
    required this.passwordHash,
    required this.createdAt,
  });

  factory User.fromMap(Map<String, dynamic> row) {
    return User(
      id: row['id'] as int,
      email: row['email'] as String,
      passwordHash: row['password_hash'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  final int id;
  final String email;
  final String passwordHash;
  final DateTime createdAt;

  /// 비밀번호 해시는 응답에 포함하지 않는다.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
