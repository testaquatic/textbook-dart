import 'package:todo_server/src/exceptions.dart';
import 'package:todo_server/src/models/todo.dart';

/// 할일 생성 요청 DTO
class CreateTodoRequest {
  const CreateTodoRequest({
    required this.title,
  });

  final String title;

  /// JSON Map에서 파싱하고 유효성을 검사한다.
  factory CreateTodoRequest.fromJson(Map<String, dynamic> json) {
    final title = json['title'];

    if (title == null) {
      throw const ValidationException('title 필드가 필요합니다.');
    }
    if (title is! String) {
      throw const ValidationException('title은 문자열이어야 합니다.');
    }
    if (title.trim().isEmpty) {
      throw const ValidationException('title은 비어 있을 수 업습니다.');
    }
    if (title.length > 500) {
      throw const ValidationException('title은 500자를 초과할 수 없습니다.');
    }

    return CreateTodoRequest(title: title.trim());
  }
}

/// 할 일 수정 요청 DTO
class UpdateTodoRequest {
  const UpdateTodoRequest({this.title, this.completed});

  final String? title;
  final bool? completed;

  factory UpdateTodoRequest.fromJson(Map<String, dynamic> json) {
    final title = json['title'] as String?;
    final completed = json['completed'] as bool?;

    if (title == null && completed == null) {
      throw const ValidationException('title 또는 completed 중 하나 이상 포함해야 합니다.');
    }

    if (title != null && title.trim().isEmpty) {
      throw const ValidationException('title은 비어 있을 수 없습니다.');
    }

    return UpdateTodoRequest(title: title?.trim(), completed: completed);
  }

  /// 기존 [Todo]에 수정 사항을 적용합니다.
  Todo applyTo(Todo todo) {
    return todo.copyWith(
      title: title,
      completed: completed,
      updatedAt: DateTime.now(),
    );
  }
}
