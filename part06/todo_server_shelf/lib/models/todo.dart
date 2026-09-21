/// 할 일 모델
class Todo {
  const Todo({
    required this.id,
    required this.title,
    required this.completed,
    required this.userId,
    required this.createdAt,
    this.updatedAt,
  });

  /// 데이터베이스 행(Map)에서 [Todo]를 생성한다.
  factory Todo.fromMap(Map<String, dynamic> row) {
    return Todo(
      id: row['id'] as int,
      title: row['title'] as String,
      completed: (row['completed'] as int) == 1,
      userId: row['user_id'] as int,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: row['updated_at'] != null
          ? DateTime.parse(row['updated_at'] as String)
          : null,
    );
  }

  final int id;
  final String title;
  final bool completed;
  final int userId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// [Todo]를 Json 응답 Map으로 반환한다
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'completed': completed,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  /// 일부 필드를 변경한 새 [Todo]를 생성한다.
  Todo copyWith({String? title, bool? completed, DateTime? updatedAt}) {
    return Todo(
      id: id,
      title: title ?? this.title,
      completed: completed ?? this.completed,
      userId: userId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
