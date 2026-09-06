/// 이름 변경 규칙을 나타는 값 객체
class RenameRule {
  /// 변경 전 파일명 패턴 (정규식)
  final String pattern;

  /// 변경 후 파일명 템플릿
  final String replacement;

  /// 규칙 설명(선택)
  final String? description;

  const RenameRule({
    required this.pattern,
    required this.replacement,
    this.description,
  });

  /// JSOM Map에서 [RenameRule]을 생성한다.
  factory RenameRule.fromJson(Map<String, dynamic> json) {
    return RenameRule(
      pattern: json['pattern'] as String,
      replacement: json['replacement'] as String,
      description: json['description'] as String?,
    );
  }

  /// [RenameRule]을 JSON Map으로 변환한다.
  Map<String, dynamic> toJson() {
    return {
      'pattern': pattern,
      'replacement': replacement,
      if (description != null) 'description': description,
    };
  }

  @override
  String toString() {
    return 'RenameRole($pattern -> $replacement)';
  }
}
