import 'dart:io';

import 'package:path/path.dart' as p;

/// 파일 하나의 메타데이터를 담는 값 객체
class FileInfo {
  /// 파일의 절대 경로
  final String path;

  /// 확장자를 포함한 파일 이름
  final String name;

  /// 소문자로 정규화한 확장자 (점 포함, 예: '.dart').
  final String extension;

  /// 파일 크기(바이트)
  final int sizeBytes;

  /// 마지막 수정 시간
  final DateTime modifiedAt;

  const FileInfo({
    required this.path,
    required this.name,
    required this.extension,
    required this.sizeBytes,
    required this.modifiedAt,
  });

  /// [File]로부터 [FileInfo]를 생성한다.
  static Future<FileInfo> fromFile(File file) async {
    final stat = await file.stat();
    return FileInfo(
      path: file.path,
      name: p.basename(file.path),
      extension: p.extension(file.path),
      sizeBytes: stat.size,
      modifiedAt: stat.modified,
    );
  }

  /// 파일 크기를 사람이 읽기 좋은 형태로 반환한다.
  String get humanReadableSize {
    if (sizeBytes < 1024) {
      return '$sizeBytes B';
    }
    if (sizeBytes < 1024 * 1024) {
      return '${sizeBytes / 1024} KB';
    }
    if (sizeBytes < 1024 * 1024 * 1024) {
      return '${sizeBytes / (1024 * 1024)} MB';
    }
    return '${sizeBytes / (1024 * 1024 * 1024)} GB';
  }

  @override
  String toString() {
    return 'FileInfo($name, $humanReadableSize)';
  }
}
