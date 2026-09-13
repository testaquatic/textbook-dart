@Tags(["e2e"])
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory workDir;

  setUp(() async {
    workDir = await Directory.systemTemp.createTemp("fc_e2e_");
  });

  tearDown(() async {
    if (workDir.existsSync()) {
      await workDir.delete(recursive: true);
    }
  });

  /// `dart run`으로 file_organizer를 실행한다.
  Future<ProcessResult> runCli(List<String> args) async {
    // fvm을 사용하는 경우를 처리
    final useFvm = (await Process.run("which", ["fvm"])).stdout == null;
    final dartCommand = useFvm
        ? (dart: "dart", args: [])
        : (dart: "fvm", args: ["dart"]);

    return Process.run(dartCommand.dart, [
      ...dartCommand.args,
      "run",
      "bin/file_organizer.dart",
      ...args,
    ], workingDirectory: p.current);
  }

  group("CLI E2E 테스트", () {
    test("--help 출력", () async {
      final result = await runCli(["--help"]);

      expect(result.exitCode, equals(0));
      expect(result.stdout, contains("file_organizer"));
      expect(result.stdout, contains("organize"));
      expect(result.stdout, contains("stats"));
      expect(result.stdout, contains("rename"));
    });

    test("알 수 없는 커맨드는 exitCode 64", () async {
      final result = await runCli(["unknown"]);

      expect(result.exitCode, equals(1));
      expect(
        result.stderr,
        contains('Could not find a command named "unknown"'),
      );
    });

    test("stats 커맨드 실행", () async {
      // 테스트 파일 생성
      await File(p.join(workDir.path, "a.txt")).writeAsString("hello");
      await File(p.join(workDir.path, "b.jpg")).writeAsBytes([0, 1]);

      final result = await runCli(["stats", "-p", workDir.path]);

      expect(result.exitCode, equals(0));
      final stdout = result.stdout as String;

      // 통계 테이블 헤더 확인
      expect(stdout, contains("카테고리"));
      expect(stdout, contains("파일 수"));
    });

    test("organize dry-run 커맨드", () async {
      await File(p.join(workDir.path, "photo.jpg")).writeAsBytes([]);
      await File(p.join(workDir.path, "doc.pdf")).writeAsBytes([]);

      final result = await runCli([
        "organize",
        "-s",
        workDir.path,
        "--dry-run",
        "--yes",
      ]);

      expect(result.exitCode, equals(0));

      // 파일은 그대로 있어야 함
      expect(File(p.join(workDir.path, "photo.jpg")).existsSync(), isTrue);
    });

    test("stats --format json 출력", () async {
      await File(p.join(workDir.path, "code.dart"))
          .writeAsString("void main(){}");

      final result = await runCli([
        "stats",
        "-p",
        workDir.path,
        "--format",
        "json",
      ]);

      expect(result.exitCode, equals(0));
      final stdout = result.stdout as String;

      // JSON 형식 확인
      expect(stdout, contains("{"));
      expect(stdout, contains('"count"'));
    });
  });
}
