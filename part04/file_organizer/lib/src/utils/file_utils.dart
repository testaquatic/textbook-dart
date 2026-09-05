import 'dart:io';

import 'package:file_organizer/src/models/file_info.dart';
import 'package:path/path.dart';

/// 디렉토리에서 파일 목록을 수집한다.
///
/// [recursive]가 true이면 하위 디렉토리까지 탐색한다.
/// [extensions]이 지정되면 해당 확장자 파일만 반환한다.
Future<List<FileInfo>> collectFiles(
  Directory dir, {
  bool recursive = false,
  Set<String>? extensions,
}) async {
  final result = <FileInfo>[];

  await for (final entity in dir.list(recursive: recursive)) {
    if (entity is! File) {
      continue;
    }

    final ext = extension(entity.path).toLowerCase();

    if (extensions != null && !extensions.contains(ext)) {
      continue;
    }

    result.add(await FileInfo.fromFile(entity));
  }

  // 이름 기준 정렬
  result.sort((a, b) => a.name.compareTo(b.name));

  return result;
}

/// 확장자를 카테고리 이름으로 변환한다.
String extentionToCategory(String ext) {
  const categories = {
    // 이미지
    '.jpg': '이미지',
    '.jpeg': '이미지',
    '.png': '이미지',
    '.gif': '이미지',
    '.bmp': '이미지',
    '.webp': '이미지',
    '.heic': '이미지',
    '.tiff': '이미지',
    '.svg': '이미지',

    // 비디오
    '.mp4': '비디오',
    '.mkv': '비디오',
    '.mov': '비디오',
    '.wmv': '비디오',
    '.avi': '비디오',
    '.flv': '비디오',
    '.webm': '비디오',

    // 오디오
    '.mp3': '오디오',
    '.wav': '오디오',
    '.aac': '오디오',
    '.flac': '오디오',
    '.m4a': '오디오',
    '.ogg': '오디오',
    '.wma': '오디오',

    // 문서
    '.pdf': '문서',
    '.doc': '문서',
    '.docx': '문서',
    '.ppt': '문서',
    '.pptx': '문서',
    '.xls': '문서',
    '.xlsx': '문서',
    '.txt': '문서',
    '.hwp': '문서',
    '.md': '문서',

    // 코드
    '.dart': '코드',
    '.py': '코드',
    '.js': '코드',
    '.html': '코드',
    '.css': '코드',
    '.java': '코드',
    '.cpp': '코드',
    '.c': '코드',
    '.cs': '코드',
    '.ts': '코드',
    '.json': '코드',
    '.xml': '코드',
    '.yaml': '코드',
    '.yml': '코드',

    // 압축
    '.zip': '압축',
    '.rar': '압축',
    '.7z': '압축',
    '.tar': '압축',
    '.gz': '압축',

    // 설치 파일
    '.exe': '설치 파일',
    '.dmg': '설치 파일',
    '.deb': '설치 파일',
    '.rpm': '설치 파일',
  };

  return categories[ext] ?? '기타';
}

/// 디렉토리를 재귀적으로 생성한다.
/// 이미 존재하면 무시한다.
Future<Directory> ensureDirectory(String path) async {
  final dir = Directory(path);
  if (!dir.existsSync()) {
    await dir.create(recursive: true);
  }
  return dir;
}

/// 파일을 안전하게 이동한다
///
/// 대상 경로에 이미 존재하면 번호를 붙여 이름 충돌을 피한다.
Future<String> moveFileSafely(File source, String destDir) async {
  await ensureDirectory(destDir);

  final fileName = basename(source.path);
  var destPath = join(destDir, fileName);

  // 이름 충돌 처리
  var counter = 1;
  while (File(destPath).existsSync()) {
    final nameWithoutExt = basenameWithoutExtension(fileName);
    final ext = extension(fileName);
    destPath = join(destDir, '${nameWithoutExt}_$counter$ext');
    counter++;
  }

  await source.rename(destPath);
  return destPath;
}
