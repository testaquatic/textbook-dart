import 'dart:io';

import 'package:file_organizer/src/services/default_file_service.dart';
import 'package:file_organizer/src/services/organize_service.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory sourceDir;
  late Directory destDir;
  late OrganizeService service;

  setUp(() {
    service = OrganizeService(const DefaultFileService());
  });

  setUp(() async {
    sourceDir = await Directory.systemTemp.createTemp("fc_source_");
    destDir = await Directory.systemTemp.createTemp("fc_dest_");
  });

  tearDown(() async {
    if (sourceDir.existsSync()) {
      await sourceDir.delete(recursive: true);
    }
    if (destDir.existsSync()) {
      await destDir.delete(recursive: true);
    }
  });

  Future<File> createFile(String name, {String content = ""}) async {
    final file = File(p.join(sourceDir.path, name));
    await file.writeAsString(content);

    return file;
  }

  group("OrganizeService 통합테스트", () {
    test("이미지 파일 분류", () async {
      await createFile("photo.jpg");
      await createFile("screenshot.png");

      final result = await service.organize(sourceDir, destDir.path);
      stderr.writeln(result);

      expect(result.successCount, equals(2));

      final imageDir = Directory(p.join(destDir.path, "이미지"));
      expect(imageDir.existsSync(), isTrue);

      final files = imageDir.listSync().whereType<File>().toList();
      expect(files, hasLength(2));
      expect(
        files.map((f) => p.basename(f.path)),
        containsAll(["photo.jpg", "screenshot.png"]),
      );
    });

    test("다양한 파일 카테고리 분류", () async {
      await createFile("doc.pdf");
      await createFile("video.mp4");
      await createFile("archive.zip");
      await createFile("code.dart");

      final results = await service.organize(sourceDir, destDir.path);

      expect(results.successCount, equals(4));

      final categories = destDir.listSync().whereType<Directory>().toList();
      final categoryNames = categories.map((d) => p.basename(d.path)).toSet();

      expect(categoryNames, containsAll(["문서", "비디오", "압축", "코드"]));
    });

    test("이름 충돌 처리", () async {
      // 같은 이름의 파일이 대상에 이미 존재
      await createFile("photo.jpg", content: "original");
      final existingDir = Directory(p.join(destDir.path, "이미지"));
      await existingDir.create();
      await File(p.join(existingDir.path, "photo.jpg"))
          .writeAsString("existing");

      final result = await service.organize(sourceDir, destDir.path);

      expect(result.successCount, equals(1));

      // 이름 충돌로 다른 이름으로 저장됐는지 확인
      final movedFile = File(result.moves.first.destPath);
      expect(movedFile.existsSync(), isTrue);
      expect(p.basename(movedFile.path), isNot(equals("photo.jpg")));
    });

    test("dry-run 모드에서 파일 미이동", () async {
      await createFile("photo.jpg");
      await createFile("doc.pdf");

      final result = await service.organize(
        sourceDir,
        destDir.path,
        dryRun: true,
      );

      expect(result.moves, hasLength(2));
      expect(result.dryRun, isTrue);

      // 원본 파일이 그대로 있어야 함
      expect(File(p.join(sourceDir.path, "photo.jpg")).existsSync(), isTrue);
      expect(File(p.join(sourceDir.path, "doc.pdf")).existsSync(), isTrue);

      // 대상 디렉토리에 파일이 없어야 함
      expect(destDir.listSync(), isEmpty);
    });

    test("재귀 탐색 - 하위 디렉토리 파일 포함", () async {
      await createFile("root.jpg");

      // 하위 디렉토리 생성 및 파일 추가
      final subDir = await Directory(p.join(sourceDir.path, "sub")).create();
      await File(p.join(subDir.path, "nested.png")).writeAsString("...");

      // 비재귀: root.jpg만 정리됨
      final nonRecursive = await service.organize(
        sourceDir,
        p.join(destDir.path, "nonRecursive"),
      );
      expect(nonRecursive.successCount, equals(1));

      // 재귀: root.jpg와 nested.png 모두 정리됨
      await createFile("root.jpg");
      final recursive = await service.organize(
        sourceDir,
        p.join(destDir.path, "recursive"),
        recursive: true,
      );
      expect(recursive.successCount, equals(2));
    });
  });
}
