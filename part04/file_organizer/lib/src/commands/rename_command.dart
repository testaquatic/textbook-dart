import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart';

class RenameCommand extends Command<void> {
  RenameCommand() {
    argParser
      ..addOption('path', abbr: 'p', help: '대상 디렉토리 경로', defaultsTo: '.')
      ..addOption('pattern', help: '변경 전 파일 패턴 (정규식)')
      ..addOption('replacement', help: '변경 후 파일명', mandatory: true)
      ..addFlag('dry-run', help: '실제로 변경하지 않고 결과만 출력한다.', negatable: false);
  }

  @override
  String get name => 'rename';

  @override
  String get description => '정규식 패턴으로 파일을 일괄 이름 변경합니다.';

  @override
  Future<void> run() async {
    final targetPath = argResults!['path'] as String;
    final pattern = argResults!['pattern'] as String;
    final replacement = argResults!['replacement'] as String;
    final dryRun = argResults!['dry-run'] as bool;

    final dir = Directory(absolute(targetPath));
    if (!dir.existsSync()) {
      usageException('디렉토리가 존재하지 않습니다: $targetPath');
    }

    print('이름 변경: $pattern -> $replacement (dry-run: $dryRun)');
  }
}
