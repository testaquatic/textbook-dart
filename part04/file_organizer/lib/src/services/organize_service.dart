import 'dart:io';

import 'package:file_organizer/src/models/file_info.dart';
import 'package:file_organizer/src/services/file_info.dart';
import 'package:file_organizer/src/utils/file_utils.dart';

/// 파일 정리 비지니스 로직
class OrganizeService {
  final FileService _fileService;

  const OrganizeService(this._fileService);

  /// 디렉토리를 정리하고 이동된 파일 목록을 반환한다
  Future<OrganizeResult> organize(
    Directory sourceDir,
    String destBasePath, {
    bool dryRun = false,
    bool recursive = false,
  }) async {
    final files = await _fileService.collectFiles(
      sourceDir,
      recursive: recursive,
    );
    final moves = <FileMoveResult>[];

    for (final fileInfo in files) {
      final category = extentionToCategory(fileInfo.extension);
      final targetDir = "$destBasePath/$category";

      if (!dryRun) {
        try {
          final movedPath = await _fileService.moveFile(
            File(fileInfo.path),
            targetDir,
          );
          moves.add(
            FileMoveResult(
              source: fileInfo,
              destPath: movedPath,
              success: true,
            ),
          );
        } catch (e) {
          moves.add(
            FileMoveResult(
              source: fileInfo,
              destPath: targetDir,
              success: false,
              error: e.toString(),
            ),
          );
        }
      } else {
        moves.add(
          FileMoveResult(
            source: fileInfo,
            destPath: targetDir,
            success: true,
            dryRun: true,
          ),
        );
      }
    }

    return OrganizeResult(moves: moves, dryRun: dryRun);
  }
}

/// 파일 이동 결과
class FileMoveResult {
  final FileInfo source;
  final String destPath;
  final bool success;
  final String? error;
  final bool dryRun;

  const FileMoveResult({
    required this.source,
    required this.destPath,
    required this.success,
    this.error,
    this.dryRun = false,
  });
}

/// 정리 작업 결과
class OrganizeResult {
  final List<FileMoveResult> moves;
  final bool dryRun;

  const OrganizeResult({required this.moves, required this.dryRun});

  int get successCount => moves.where((m) => m.success).length;
  int get failureCount => moves.where((m) => !m.success).length;
}
