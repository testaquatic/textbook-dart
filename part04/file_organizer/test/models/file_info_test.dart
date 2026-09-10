import 'package:file_organizer/src/models/file_info.dart';
import 'package:test/test.dart';

void main() {
  group("FileInfo.humanReadableSize", () {
    test("바이트 단위 반환", () {
      final info = FileInfo(
        path: "/tmp/a.txt",
        name: "a.txt",
        extension: ".txt",
        sizeBytes: 512,
        modifiedAt: DateTime.now(),
      );

      expect(info.humanReadableSize, equals("512 B"));
    });

    test("킬로바이트 단위 반환", () {
      final info = FileInfo(
        path: "/tmp/a.txt",
        name: "a.txt",
        extension: ".txt",
        sizeBytes: 2048,
        modifiedAt: DateTime.now(),
      );

      expect(info.humanReadableSize, equals("2.0 KB"));
    });

    test("메가바이트 단위 반환", () {
      final info = FileInfo(
        path: "/tmp/a.txt",
        name: "a.txt",
        extension: ".txt",
        sizeBytes: 1024 * 1024 * 3,
        modifiedAt: DateTime.now(),
      );

      expect(info.humanReadableSize, equals("3.0 MB"));
    });
  });
}
