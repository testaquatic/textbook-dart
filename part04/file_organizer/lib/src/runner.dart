import 'package:file_organizer/file_organizer.dart';

/// CLI 애플리케이션의 진입점 역할을 하는 러너
class FileOrganizerRunner {
  FileOrganizerRunner();

  Future<void> run(List<String> arguments) async {
    if (arguments.isEmpty) {
      _printUsage();
      return;
    }

    final command = arguments.first;
    switch (command) {
      case 'organize':
        print('organize 커맨드 - 아직 구현되지 않았습니다.');
      case 'stats':
        print('stats 커맨드 - 아직 구현되지 않았습니다.');
      case 'rename':
        print('rename 커맨드 - 아직 구현되지 않았습니다.');
      default:
        throw UsageException('알 수 없는 커맨드: $command', _usageText());
    }
  }

  void _printUsage() {
    print(_usageText());
  }

  String _usageText() {
    return '''
사용법: file_organizer <command> [options]

커맨드:
  organize   파일을 확장자별로 분류합니다.
  stats      디렉토리 통계를 출력합니다.
  rename     파일을 일괄 이름 변경합니다.

도움말: file_organizer <command> --help
''';
  }
}
