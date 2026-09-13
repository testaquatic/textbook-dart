import 'dart:io';

import 'package:file_organizer/src/utils/csv_utils.dart';
import 'package:file_organizer/src/utils/file_utils.dart';
import 'package:file_organizer/src/utils/rename_utils.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory workDir;

  setUp(() async {
    workDir = await Directory.systemTemp.createTemp("fc_rename_");
  });

  tearDown(() async {
    if (workDir.existsSync()) {
      await workDir.delete(recursive: true);
    }
  });

  test("CSV 규칙 파일 - 파일 이름 변경 전체 흐름", () async {
    // 1. 테스트 파일 생성
    final files = ["IMG_001.jpg", "IMG_002.jpg", "VIDEO_001.mp4"];
    for (final name in files) {
      await File(p.join(workDir.path, name)).writeAsString("");
    }

    // 2. CSV 규칙 파일 생성
    final rulesCsv = '''pattern,replacement,description
^IMG_,photo_,iPhone 사진 변환
^VIDEO_,clip_,동영상 변환
''';

    final csvFile = File(p.join(workDir.path, "rules.csv"));
    await csvFile.writeAsString(rulesCsv);

    // 3. CSV 파싱 - 규칙 목록 생성
    final csvContent = await csvFile.readAsString();
    final rules = parseRulesFromCsv(csvContent)
        .map((r) => (pattern: r.pattern, replacement: r.replacement))
        .toList();

    // 4 파일 수집 및 이름 변경
    final fileInfos = await collectFiles(workDir);
    final renamedFiles = <String>[];

    for (final info in fileInfos) {
      if (info.name == "rules.csv") {
        continue;
      }

      final newName = applyRenameRules(info.name, rules);
      if (newName != info.name) {
        final newPath = p.join(workDir.path, newName);
        await File(info.path).rename(newPath);
        renamedFiles.add(newName);
      }
    }

    // 5. 결과 검증
    expect(
      renamedFiles,
      containsAllInOrder(['photo_001.jpg', 'photo_002.jpg', 'clip_001.mp4']),
    );

    // 원본 이름으로는 파일이 없어야 함
    for (final original in files) {
      expect(File(p.join(workDir.path, original)).existsSync(), isFalse);
    }
  });
}
