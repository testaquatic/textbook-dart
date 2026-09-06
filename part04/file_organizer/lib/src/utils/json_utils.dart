import 'dart:convert';
import 'dart:io';

import 'package:file_organizer/src/models/rename_rule.dart';

/// JSON 파일에서 이름 변경 규칙 목록을 읽는다.
Future<List<RenameRule>> loadRulesFromJson(String filepath) async {
  final file = File(filepath);
  if (!file.existsSync()) {
    throw FileSystemException("파일을 찾을 수 없습니다", filepath);
  }

  final content = await file.readAsString();
  final dynamic raw = jsonDecode(content);

  if (raw is! List) {
    throw FormatException("최상위 요소는 배열이어야 합니다: $filepath");
  }

  return raw.cast<Map<String, dynamic>>().map(RenameRule.fromJson).toList();
}

/// 이름 변경 규칙 목록을 JSON 파일로 저장한다.
Future<void> saveRulesToJson(List<RenameRule> rules, String filepath) async {
  const encoder = JsonEncoder.withIndent("  ");
  final content = encoder.convert(rules.map((r) => r.toJson()).toList());

  await File(filepath).writeAsString(content);
}

/// JSON 규칙 파일의 예제를 생성한다.
Future<void> createSampleRulesFile(String filepath) async {
  final sample = [
    RenameRule(
      pattern: r"^IMG_(\d+)",
      replacement: "photo_\$1",
      description: "iPhone 사진 파일명 변환",
    ),
    RenameRule(pattern: r"\s+", replacement: "_", description: "공백을 밑줄로 변경"),
  ];

  await saveRulesToJson(sample, filepath);
  print("예제 규격 파일 생성: $filepath");
}
