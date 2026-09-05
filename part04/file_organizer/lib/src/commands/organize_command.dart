import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:file_organizer/src/utils/file_utils.dart';
import 'package:path/path.dart';

class OrganizeCommand extends Command<void> {
  OrganizeCommand() {
    argParser
      ..addOption('source', abbr: 's', help: '정리할 디렉토리 경로.', defaultsTo: '.')
      ..addOption('dest', abbr: 'd', help: '파일을 이동할 대상 디렉토리.')
      ..addFlag('dry-run', help: '실제로 이동하지 않고 결과만 출력한다.', negatable: false)
      ..addFlag(
        'recursive',
        abbr: 'r',
        help: '하위 디렉토리까지 탐색한다',
        negatable: false,
      );
  }

  @override
  String get name => 'organize';

  @override
  String get description => '파일을 확장자별로 분류한다.';

  @override
  Future<void> run() async {
    final source = argResults!['source'] as String;
    final dest = argResults!['dest'] as String? ?? source;
    final dryRun = argResults!['dry-run'] as bool;
    final recursive = argResults!['recursive'] as bool;

    final sourceDir = Directory(absolute(source));
    if (!sourceDir.existsSync()) {
      usageException('소스 디렉토리가 존재하지 않습니다: $source');
    }

    print('정리 시작: ${sourceDir.path}');
    if (dryRun) {
      print('[dry-run 모드] 실제 파일을 이동하지 않습니다.');
    }

    var files = await collectFiles(sourceDir, recursive: recursive);

    if (files.isEmpty) {
      print('처리할 파일이 없습니다.');
      return;
    }

    var moved = 0;
    var skipped = 0;

    for (final fileInfo in files) {
      final category = extentionToCategory(fileInfo.extension);
      final targetDir = join(absolute(dest), category);
      final targetPath = join(targetDir, fileInfo.name);

      print("   ${fileInfo.name} → $category/");

      if (!dryRun) {
        final actualPath = await moveFileSafely(File(fileInfo.path), targetDir);
        if (actualPath != targetPath) {
          print('    (이름 충돌: ${basename(actualPath)}로 저장)');
        }
        moved++;
      } else {
        skipped++;
      }
    }

    print('\n완료: ${dryRun ? '시뮬레이션' : '이동'} ${dryRun ? skipped : moved}개 파일');
  }
}
