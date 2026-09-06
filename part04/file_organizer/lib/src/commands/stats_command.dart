import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:file_organizer/src/utils/csv_utils.dart';
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
      )
      ..addOption("output", abbr: "o", help: "결과를 저장할 파일 경로 (생략 시 stdout)");
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
    final outputPath = argResults!['output'] as String?;

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

    String output = switch (format) {
      'table' => _toTable(stats, files.length),
      'json' => _toJson(stats),
      'csv' => _toCsv(stats),
      _ => throw UnimplementedError('알 수 없는 형식: $format'),
    };

    if (outputPath != null) {
      await File(outputPath).writeAsString(output);
      print("결과 저장: $outputPath");
    } else {
      print(output);
    }
  }

  String _toJson(Map<String, ({int count, int totalBytes})> stats) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert({
      for (final e in stats.entries)
        e.key: {"count": e.value.count, "bytes": e.value.totalBytes},
    });
  }

  String _toCsv(Map<String, ({int count, int totalBytes})> stats) {
    return toCsv([
      for (final e in stats.entries)
        {
          "category": e.key,
          "count": e.value.count,
          "bytes": e.value.totalBytes,
        },
    ]);
  }

  String _toTable(Map<String, ({int count, int totalBytes})> stats, int total) {
    final buffer = StringBuffer();
    buffer.writeln("카테고리        파일 수    크기");
    for (final entry in stats.entries) {
      final mb = (entry.value.totalBytes / (1024 * 1024)).toStringAsFixed(1);
      buffer.writeln(
        "${entry.key.padRight(16)} ${entry.value.count.toString().padLeft(8)}    $mb MB",
      );
    }
    buffer.writeln("-" * 40);
    buffer.write("합계                    ${total.toString().padLeft(6)}");
    return buffer.toString();
  }
}
