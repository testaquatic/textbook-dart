import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:file_organizer/src/utils/file_utils.dart';
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

    final files = await collectFiles(dir, recursive: recursive);

    var stats = <String, ({int count, int totalBytes})>{};

    // 카테고리별 집계
    for (final f in files) {
      final category = extentionToCategory(f.extension);
      final current = stats[category] ?? (count: 0, totalBytes: 0);
      stats[category] = (
        count: current.count + 1,
        totalBytes: current.totalBytes + f.sizeBytes,
      );
    }

    switch (format) {
      case 'table':
        _printTable(stats, files.length);
        break;
      case 'json':
        _printJson(stats);
        break;
      case 'csv':
        _printCsv(stats);
        break;
    }
  }

  void _printTable(
    Map<String, ({int count, int totalBytes})> stats,
    int total,
  ) {
    print('카테고리          파일 수    크기');
    print('-' * 40);
    for (final entry in stats.entries) {
      final mb = ((entry.value.totalBytes) / (1024 * 1024)).toStringAsFixed(1);
      print(
        '${entry.key.padRight(15)} ${entry.value.count.toString().padLeft(5)}  ${mb}MB',
      );
    }
    print('-' * 40);
    print('합계                   ${total.toString().padLeft(6)}');
  }

  void _printJson(Map<String, ({int count, int totalBytes})> stats) {
    final buffer = StringBuffer('{\n');
    final entries = stats.entries.toList();
    for (var i = 0; i < entries.length; i++) {
      final e = entries[i];
      final comma = i < entries.length - 1 ? ',' : '';
      buffer.writeln(
        '    "${e.key}": {"count": ${e.value.count}, "bytes": ${e.value.totalBytes}}$comma',
      );
    }
    buffer.write('}');
    print(buffer);
  }

  void _printCsv(Map<String, ({int count, int totalBytes})> stats) {
    print('category,count,bytes');
    for (final e in stats.entries) {
      print('${e.key},${e.value.count},${e.value.totalBytes}');
    }
  }
}
