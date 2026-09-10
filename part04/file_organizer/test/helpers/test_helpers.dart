import 'dart:io';

import 'package:file_organizer/src/models/file_info.dart';
import 'package:path/path.dart';

/// 테스트용 FileInfo 생성 헬퍼
FileInfo makeFileInfo({
  String path = "/tmp/test.txt",
  String name = "test.txt",
  String extension = ".txt",
  int sizeBytes = 0,
  DateTime? modifiedAt,
}) {
  return FileInfo(
    path: path,
    name: name,
    extension: extension,
    sizeBytes: sizeBytes,
    modifiedAt: modifiedAt ?? DateTime(2024, 1, 1),
  );
}

/// 임시 디렉토리에 테스트 파일을 생성한다
Future<File> createTestFile(
  Directory dir,
  String name, {
  String content = "test content",
}) async {
  final file = File(join(dir.path, name));
  await file.writeAsString(content);

  return file;
}
