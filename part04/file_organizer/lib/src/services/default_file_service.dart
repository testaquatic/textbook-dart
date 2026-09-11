import 'dart:io';

import 'package:file_organizer/src/models/file_info.dart';
import 'package:file_organizer/src/services/file_info.dart';
import 'package:file_organizer/src/utils/file_utils.dart';

/// [FileService]의 실제 구현체
class DefaultFileService implements FileService {
  const DefaultFileService();

  @override
  Future<List<FileInfo>> collectFiles(
    Directory? dir, {
    bool recursive = false,
    Set<String> extensions = const {},
  }) {
    return collectFiles(dir, recursive: recursive, extensions: extensions);
  }

  @override
  Future<String> moveFile(File source, String destDir) {
    return moveFileSafely(source, destDir);
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
