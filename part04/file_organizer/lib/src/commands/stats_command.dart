import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart';

class StatsCommand extends Command<void> {
  StatsCommand() {
    argParser
      ..addOption('path', abbr: 'p', help: '통계를 볼 디렉토리 경로.', defaultsTo: '.')
      ..addFlag(
        'recursive',
        abbr: 'r',
        help: '하위 디렉토리까지 포함합니다.',
        negatable: false,
      )
      ..addOption(
        'format',
        help: '출력 형식',
        allowed: ['table', 'json', 'csv'],
        defaultsTo: 'table',
        allowedHelp: {
          'table': '테이블 형식으로 출력합니다.',
          'json': 'JSON 형식으로 출력합니다.',
          'csv': 'CSV 형식으로 출력합니다.',
        },
      );
  }

  @override
  String get name => 'stats';

  @override
  String get description => '디렉토리의 파일 통계를 계산합니다.';

  @override
  Future<void> run() async {
    final targetPath = argResults!['path'] as String;
    final recursive = argResults!['recursive'] as bool;
    final format = argResults!['format'] as String;

    final dir = Directory(absolute(targetPath));
    if (!dir.existsSync()) {
      usageException('디렉토리가 존재하지 않습니다: $targetPath');
    }

    print("통계 분석: ${dir.path} (recursive: $recursive, format: $format)");
  }
}
