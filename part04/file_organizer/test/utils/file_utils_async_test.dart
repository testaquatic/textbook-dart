import 'dart:io';

import 'package:file_organizer/src/utils/file_utils.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp("file_utils_test_");
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group("ensureDirectory", () {
    test("존재하지 않는 디렉토리 생성", () async {
      final newPath = p.join(tempDir.path, "new", "nested", "dir");
      expect(Directory(newPath).existsSync(), isFalse);

      await ensureDirectory(newPath);

      expect(Directory(newPath).existsSync(), isTrue);
    });

    test("이미 존재하는 디렉토리는 그대로", () async {
      // 두번 호출해도 에러 없음
      await ensureDirectory(tempDir.path);
      await ensureDirectory(tempDir.path);

      expect(Directory(tempDir.path).existsSync(), isTrue);
    });

    test("생성된 디렉토리 반환", () async {
      final newPath = p.join(tempDir.path, "created");
      final result = await ensureDirectory(newPath);
      expect(result.path, equals(newPath));
    });
  });

  group("moveFileSafely", () {
    test("파일 이동", () async {
      final source = File(p.join(tempDir.path, "source.txt"));
      await source.writeAsString("hello");

      final destDir = p.join(tempDir.path, "dest");
      await moveFileSafely(source, destDir);

      expect(source.existsSync(), isFalse);
      expect(File(p.join(destDir, "source.txt")).existsSync(), isTrue);
    });

    test("이름 충돌 시 번호 추가", () async {
      final source1 = File(p.join(tempDir.path, "existing.txt"));
      final destDir = p.join(tempDir.path, "dest");

      await ensureDirectory(destDir);

      // 대상에 파일 미리 생성
      await File(p.join(destDir, "existing.txt")).writeAsString("existing");
      await source1.writeAsString("new");

      final movedPath = await moveFileSafely(source1, destDir);

      // 원본 이름이 아닌 다른 이름으로 저장
      expect(p.basename(movedPath), isNot(equals("existing.txt")));
      expect(File(movedPath).existsSync(), isTrue);
    });
  });
}
