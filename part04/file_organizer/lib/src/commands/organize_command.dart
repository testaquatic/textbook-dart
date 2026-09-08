import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:file_organizer/src/utils/file_utils.dart';
import 'package:file_organizer/src/utils/progress_bar.dart';
import 'package:file_organizer/src/utils/terminal.dart';
import 'package:file_organizer/src/utils/prompt.dart';
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
      )
      ..addFlag("yes", abbr: "y", help: "확인 없이 바로 실행합니다.", negatable: false);
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
    final skipConfirm = argResults!['yes'] as bool;

    final sourceDir = Directory(absolute(source));
    if (!sourceDir.existsSync()) {
      usageException('소스 디렉토리가 존재하지 않습니다: $source');
    }

    Terminal.info("파일 수집 중: ${sourceDir.path}");
    var files = await collectFiles(sourceDir, recursive: recursive);

    if (files.isEmpty) {
      print('처리할 파일이 없습니다.');
      return;
    }

    Terminal.info("파일 ${Terminal.bold(files.length.toString())}개 발견");

    if (dryRun) {
      Terminal.warning("[dry-run 모드] 실제 파일을 이동하지 않습니다.");
    } else if (!skipConfirm) {
      final ok = await confirm(
        "${files.length}개 파일을 정리하시겠습니까?",
        defaultValue: true,
      );
      if (!ok) {
        Terminal.warning("취소되었습니다.");
        return;
      }
    }

    final bar = ProgressBar(total: files.length, label: "정리 중");

    var moved = 0;
    var failed = 0;

    for (var i = 0; i < files.length; i++) {
      final fileInfo = files[i];
      bar.update(i + 1);

      if (!dryRun) {
        try {
          final category = extentionToCategory(fileInfo.extension);
          final targetDir = join(absolute(dest), category);
          await moveFileSafely(File(fileInfo.path), targetDir);
          moved++;
        } catch (e) {
          failed++;
        }
      }
    }

    bar.complete();

    if (dryRun) {
      Terminal.success("시뮬레이션 완료 (${files.length}개 파일)");
    } else {
      Terminal.success("완료: $moved개 이동, $failed개 실패");
    }
  }
}
