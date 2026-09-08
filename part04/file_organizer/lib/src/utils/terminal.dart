import 'dart:io';

/// 터미널 출력 유틸리티
///
/// ANSI 이스케이프 코드를 사용한다.
/// TTY가 아닌 환경(파이프, 파일 리다이렉션)에서는 색상코드를 출력하지 않는다.
class Terminal {
  Terminal._();

  /// 현재 환경이 색상 출력을 지원하는지 여부
  static bool get supportAnsi =>
      stdout.hasTerminal && Platform.environment["NO COLOR"] == null;

  // --- 색상 출력 ---
  static String red(String text) => _colorize(text, 31);

  static String green(String text) => _colorize(text, 32);

  static String yellow(String text) => _colorize(text, 33);

  static String blue(String text) => _colorize(text, 34);

  static String magenta(String text) => _colorize(text, 35);

  static String cyan(String text) => _colorize(text, 36);

  static String white(String text) => _colorize(text, 37);

  static String gray(String text) => _colorize(text, 90);

  // --- 스타일 ----
  static String bold(String text) => _stylize(text, 1);

  static String dim(String text) => _stylize(text, 2);

  static String underline(String text) => _stylize(text, 4);

  // --- 메시지 유형 ---
  static void success(String message) => print("${green("✓")} $message");

  static void error(String message) => stderr.writeln("${red("✗")} $message");

  static void warning(String message) =>
      stderr.writeln("${yellow("⚠")} $message");

  static void info(String message) => print("${blue("ⓘ")} $message");

  // --- 내부 헬퍼 ---
  static String _colorize(String text, int colorCode) {
    if (!supportAnsi) {
      return text;
    }

    return "\x1B[$colorCode}m$text\x1B[0m";
  }

  static String _stylize(String text, int styleCode) {
    if (!supportAnsi) {
      return text;
    }
    return "\x1B[$styleCode}m$text\x1B[22m";
  }
}
