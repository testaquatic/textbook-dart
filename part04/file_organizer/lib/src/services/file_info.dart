import 'dart:io';

import 'package:file_organizer/src/models/file_info.dart';

/// 파일 작업을 추상화하는 서비스 인터페이스
///
/// 테스트에서는 MockFileService로 대체된다.
abstract interface class FileService {
  /// 디렉토리에서 파일 목록을 수집한다.
  Future<List<FileInfo>> collectFiles(
    Directory dir, {
    bool recursive = false,
    Set<String> extensions,
  });

  /// 파일을 안전하게 이동한다
  Future<String> moveFile(File source, String destDir);

  /// 파일의 내용을 문자열로 읽는다
  Future<String> readAsString(File file);

  /// 파일에 내용을 쓴다
  Future<void> writeAsString(File file, String content);
}
