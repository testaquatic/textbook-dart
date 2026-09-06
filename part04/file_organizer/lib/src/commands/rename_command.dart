import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:file_organizer/src/utils/csv_utils.dart';
import 'package:file_organizer/src/utils/file_utils.dart';
import 'package:path/path.dart';

class RenameCommand extends Command<void> {
  RenameCommand() {
    argParser
      ..addOption('path', abbr: 'p', help: '대상 디렉토리 경로', defaultsTo: '.')
      ..addOption('pattern', help: '변경 전 파일 패턴 (정규식)')
      ..addOption('replacement', help: '변경 후 파일명')
      ..addOption('rules-csv', help: '규칙이 담긴 CSV 파일 경로')
      ..addFlag('dry-run', help: '실제로 변경하지 않고 결과만 출력한다.', negatable: false);
  }

  @override
  String get name => 'rename';

  @override
  String get description => '정규식 패턴으로 파일을 일괄 이름 변경합니다.';

  @override
  Future<void> run() async {
    final targetPath = argResults!['path'] as String;
    final pattern = argResults!['pattern'] as String?;
    final replacement = argResults!['replacement'] as String?;
    final rulesCsvPath = argResults!['rules-csv'] as String?;
    final dryRun = argResults!['dry-run'] as bool;

    // 규칙 수집
    final rules = <({String pattern, String replacement})>[];
    if (rulesCsvPath != null) {
      final csvContent = await File(rulesCsvPath).readAsString();
      var csvRules = parseRulesFromCsv(csvContent);
      rules.addAll(
        csvRules.map((r) => (pattern: r.pattern, replacement: r.replacement)),
      );
    }

    if (pattern != null && replacement != null) {
      rules.add((pattern: pattern, replacement: replacement));
    }

    if (rules.isEmpty) {
      usageException("--pattern/--replacement 또는 --rules-csv 중 하나를 지정해야 합니다.");
    }

    final dir = Directory(absolute(targetPath));
    if (!dir.existsSync()) {
      usageException('디렉토리가 존재하지 않습니다: $targetPath');
    }

    if (dryRun) {
      print("[dry-run 모드]\n");
    }

    final files = await collectFiles(dir);
    var renamed = 0;

    for (final fileInfo in files) {
      var newName = fileInfo.name;

      for (final rule in rules) {
        final regex = RegExp(rule.pattern);
        newName = newName.replaceAll(regex, rule.replacement);
      }

      if (newName == fileInfo.name) {
        continue;
      }

      print("    ${fileInfo.name} -> $newName");

      if (!dryRun) {
        final newPath = join(dirname(fileInfo.path), newName);
        await File(fileInfo.path).rename(newPath);
        renamed++;
      }
    }

    print("\n완료: ${dryRun ? '시뮬레이션' : '변경'} ${dryRun ? 0 : renamed}개 파일");
  }
}
