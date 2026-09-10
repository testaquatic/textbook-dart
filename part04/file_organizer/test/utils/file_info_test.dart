import 'package:test/test.dart';

import '../helpers/test_helpers.dart';

void main() {
  group("humanReadableSize", () {
    test("0 바이트", () {
      final info = makeFileInfo(sizeBytes: 0);
      expect(info.humanReadableSize, equals("0 B"));
    });

    test("1023 바이트는 B단위", () {
      final info = makeFileInfo(sizeBytes: 1023);
      expect(info.humanReadableSize, equals("1023 B"));
    });

    test("1.5 KB", () {
      final info = makeFileInfo(sizeBytes: 1536);
      expect(info.humanReadableSize, equals("1.5 KB"));
    });

    test("정확히 1 MB", () {
      final info = makeFileInfo(sizeBytes: 1024 * 1024);
      expect(info.humanReadableSize, equals("1.0 MB"));
    });

    test("1 GB", () {
      final info = makeFileInfo(sizeBytes: 1024 * 1024 * 1024);
      expect(info.humanReadableSize, equals("1.0 GB"));
    });
  });

  group("toString", () {
    test("이름과 크기 포함", () {
      final info = makeFileInfo(name: "file.txt", sizeBytes: 1024);
      expect(info.toString(), "FileInfo(file.txt, 1.0 KB)");
    });
  });
}
