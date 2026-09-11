import 'dart:io';

import 'package:file_organizer/src/models/file_info.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../mocks/mocks.mocks.dart';

void main() {
  late MockFileService mockService;

  setUp(() {
    mockService = MockFileService();
  });

  group("MockFileService 기본 사용", () {
    test("collectFiles() 스텁 설정", () async {
      // 준비: collectFiles가 반환할 값 지정
      final fakeFiles = [
        FileInfo(
          path: "/tmp/photo.jpg",
          name: "photo.jpg",
          extension: ".jgp",
          sizeBytes: 1024,
          modifiedAt: DateTime(2024),
        ),
        FileInfo(
          path: "/tmp/doc.pdf",
          name: "doc.pdf",
          extension: ".pdf",
          sizeBytes: 2048,
          modifiedAt: DateTime(2024),
        ),
      ];

      when(
        mockService.collectFiles(
          any,
          recursive: anyNamed("recursive"),
          extensions: anyNamed("extensions"),
        ),
      ).thenAnswer((_) async {
        return fakeFiles;
      });

      // 실행
      final result = await mockService.collectFiles(Directory("/tmp"));

      // 확인
      expect(result, hasLength(2));
      expect(result.first.name, equals("photo.jpg"));
    });

    test("moveFile 호출 검증", () async {
      final source = File("/tmp/photo.jpg");
      final destDir = "/tmp/dest";
      final expectedPath = "/tmp/dest/photo.jpg";

      when(mockService.moveFile(source, destDir)).thenAnswer((_) async {
        return expectedPath;
      });

      await mockService.moveFile(source, destDir);

      // moveFile이 정확히 한 번 호출됐는지 확인
      verify(mockService.moveFile(source, destDir)).called(1);
    });
  });

  group("예외 처리", () {
    test("collectFiles 예외 발생 스텁", () async {
      when(mockService.collectFiles(any))
          .thenThrow(FileSystemException("권한 없음"));

      await expectLater(
        () => mockService.collectFiles(Directory("/protected")),
        throwsA(isA<FileSystemException>()),
      );
    });
  });
}
