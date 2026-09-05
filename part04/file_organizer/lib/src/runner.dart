import 'package:args/command_runner.dart';
import 'package:file_organizer/src/commands/organize_command.dart';
import 'package:file_organizer/src/commands/rename_command.dart';
import 'package:file_organizer/src/commands/stats_command.dart';

/// CLI 애플리케이션의 진입점 역할을 하는 러너
class FileOrganizerRunner {
  late final CommandRunner<void> _runner;

  FileOrganizerRunner() {
    _runner = CommandRunner<void>("file_organizer", "파일 정리 및 변환 CLI 도구")
      ..addCommand(OrganizeCommand())
      ..addCommand(StatsCommand())
      ..addCommand(RenameCommand());

    // 전역 옵션 추가
    _runner.argParser.addFlag(
      'verbose',
      abbr: 'v',
      help: '상세 출력을 활성화합니다.',
      negatable: false,
    );
  }

  Future<void> run(List<String> arguments) async {
    await _runner.run(arguments);
  }
}
