import 'dart:io';

import 'package:file_organizer/src/models/file_info.dart';
import 'package:file_organizer/src/services/file_info.dart';
import 'package:file_organizer/src/utils/file_utils.dart' as file_utils;

/// [FileService]의 실제 구현체
class DefaultFileService implements FileService {
  const DefaultFileService();

  @override
  Future<List<FileInfo>> collectFiles(
    Directory dir, {
    bool recursive = false,
    Set<String>? extensions,
  }) {
    return file_utils.collectFiles(
      dir,
      recursive: recursive,
      extensions: extensions,
    );
  }

  @override
  Future<String> moveFile(File source, String destDir) {
    return file_utils.moveFileSafely(source, destDir);
  }

  @override
  Future<String> readAsString(File file) {
    return file.readAsString();
  }

  @override
  Future<void> writeAsString(File file, String content) {
    return file.writeAsString(content);
  }
}
