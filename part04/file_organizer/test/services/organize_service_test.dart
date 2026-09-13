import 'dart:io';

import 'package:file_organizer/src/models/file_info.dart';
import 'package:file_organizer/src/services/organize_service.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../mocks/mocks.mocks.dart';

void main() {
  late MockFileService mockFileService;
  late OrganizeService organizeService;

  setUp(() {
    mockFileService = MockFileService();
    organizeService = OrganizeService(mockFileService);
  });

  FileInfo makeFileInfo(String name, String ext) {
    return FileInfo(
      path: "/tmp/$name",
      name: name,
      extension: ext,
      sizeBytes: 100,
      modifiedAt: DateTime(2024),
    );
  }

  group("organize", () {
    test("파일 없으면 빈 결과 반환", () async {
      when(mockFileService.collectFiles(any)).thenAnswer((_) async {
        return [];
      });

      final result = await organizeService.organize(Directory("/tmp"), "/dest");

      expect(result.moves, isEmpty);
      expect(result.successCount, equals(0));
    });

    test("이미지 파일을 이미지 카테고리로 이동", () async {
      final file = makeFileInfo("photo.jpg", ".jpg");
      when(mockFileService.collectFiles(any)).thenAnswer((_) async => [file]);
      when(mockFileService.moveFile(any, any))
          .thenAnswer((_) async => "/dest/이미지/photo.jpg");

      final result = await organizeService.organize(Directory("/tmp"), "/dest");

      expect(result.successCount, equals(1));
      expect(result.moves.first.destPath, contains("이미지"));

      // moveFile이 올바른 대상 디렉토리로 호출는지 확인
      verify(mockFileService.moveFile(any, "/dest/이미지")).called(1);
    });

    test("dry-run 모드에서 movedFile 미호출", () async {
      final file = makeFileInfo("doc.pdf", ".pdf");
      when(mockFileService.collectFiles(any)).thenAnswer((_) async => [file]);

      final result = await organizeService.organize(
        Directory("/tmp"),
        "/dest",
        dryRun: true,
      );

      // dry-run이므로 실제 이동 없음
      verifyNever(mockFileService.moveFile(any, any));
      expect(result.moves.first.dryRun, isTrue);
    });

    test("이동 실패 시 failureCount 증가", () async {
      final file = makeFileInfo("photo.jpg", ".jpg");
      when(mockFileService.collectFiles(any)).thenAnswer((_) async => [file]);
      when(mockFileService.moveFile(any, any))
          .thenThrow(FileSystemException("권한 없음"));

      final result = await organizeService.organize(Directory("/tmp"), "/dest");

      expect(result.successCount, equals(0));
      expect(result.failureCount, equals(1));
      expect(result.moves.first.error, isNotNull);
    });

    test("여러 파일 혼합 처리", () async {
      final files = [
        makeFileInfo("photo.jpg", ".jpg"),
        makeFileInfo("doc.pdf", ".pdf"),
        makeFileInfo("video.mp4", ".mp4"),
      ];
      when(mockFileService.collectFiles(any)).thenAnswer((_) async => files);
      when(mockFileService.moveFile(any, any)).thenAnswer((inv) async {
        final destDir = inv.positionalArguments[1] as String;
        return "$destDir/file";
      });

      final result = await organizeService.organize(Directory("/tmp"), "/dest");

      expect(result.successCount, equals(3));
      final destinations = result.moves.map((m) => m.destPath).toList();
      expect(destinations.any((d) => d.contains("이미지")), isTrue);
      expect(destinations.any((d) => d.contains("문서")), isTrue);
      expect(destinations.any((d) => d.contains("비디오")), isTrue);
    });
  });
}
