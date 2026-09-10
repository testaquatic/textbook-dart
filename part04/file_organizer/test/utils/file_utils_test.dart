import 'dart:io';

import 'package:file_organizer/src/utils/file_utils.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp("file_organizer_test_");
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group("collectFiles", () {
    test("빈 디렉토리는 빈 목록 반환", () async {
      final files = await collectFiles(tempDir);
      expect(files, isEmpty);
    });

    test("파일 수집", () async {
      await File(p.join(tempDir.path, "a.txt")).writeAsString("hello");
      await File(p.join(tempDir.path, "b.dart"))
          .writeAsString("void main() {}");
      await File(p.join(tempDir.path, "c.jpg")).writeAsBytes([0, 1, 2]);

      final files = await collectFiles(tempDir);
      expect(files, hasLength(3));
    });

    test(("확장자 필터링"), () async {
      await File(p.join(tempDir.path, "a.txt")).writeAsString("hello");
      await File(p.join(tempDir.path, "b.dart")).writeAsString("dart");
      await File(p.join(tempDir.path, "c.txt")).writeAsString("world");

      final files = await collectFiles(tempDir, extensions: {".txt"});
      expect(files, hasLength(2));
      expect(files.every((f) => f.extension == ".txt"), isTrue);
    });
  });

  group("extensionToCategory", () {
    test("이미지 확장자", () {
      expect(extentionToCategory(".jpg"), equals("이미지"));
      expect(extentionToCategory(".png"), equals("이미지"));
    });

    test("알 수 없는 학장자는 기타", () {
      expect(extentionToCategory(".xyz"), equals("기타"));
    });
  });
}
