import 'dart:io';

/// 사용자에게 yes/no 확인을 요청한다.
///
/// 기본값을 지정하면 Enter 입력 시 기본값을 반환한다.
Future<bool> confirm(String message, {bool defaultValue = false}) async {
  final hint = defaultValue ? '[Y/n]' : '[y/N]';
  stdout.write('$message $hint ');

  final input = stdin.readLineSync()?.trim().toLowerCase() ?? "";

  if (input.isEmpty) {
    return defaultValue;
  }
  return input == "Y" || input == "yes";
}

/// 사용자에게 텍스트 입력을 요청한다
Future<String> prompt(
  String message, {
  String? defaultValue,
  String Function(String)? validator,
}) async {
  while (true) {
    if (defaultValue != null) {
      stdout.write("$message [$defaultValue]: ");
    } else {
      stdout.write("$message : ");
    }

    final input = stdin.readLineSync()?.trim() ?? "";
    final value = input.isEmpty && defaultValue != null ? defaultValue : input;

    if (validator != null) {
      final error = validator(value);
      if (error.isNotEmpty) {
        stderr.writeln("입력 오류: $error");
        continue;
      }
    }

    return value;
  }
}

/// 사용자에게 선택지를 제시한다.
Future<String> select(String message, List<String> options) async {
  print(message);

  for (var i = 0; i < options.length; i++) {
    print("  ${i + 1}. ${options[i]}");
  }

  while (true) {
    stdout.write("선택 (1-${options.length}): ");
    final input = stdin.readLineSync()?.trim() ?? "";
    final index = int.tryParse(input);

    if (index != null && index >= 1 && index <= options.length) {
      return options[index - 1];
    }

    stderr.writeln("1-${options.length} 사이의 숫자를 입력하세요.");
  }
}
