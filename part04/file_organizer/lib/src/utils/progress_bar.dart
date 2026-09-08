import 'dart:io';

/// 터미널 진행률 바.
///
/// 사용 예:
/// ```dart
/// final bar = ProgressBar(total: 100, "처리 중");
/// for (var i = 0; i < 100; i++) {
///   bar.update(i + 1);
///   await Future.delayed(Duration(milliseconds: 10));
/// }
/// bar.complete();
/// ```
class ProgressBar {
  final int total;
  final String label;
  final int width;
  final DateTime _startTime;

  int _current = 0;

  ProgressBar({required this.total, this.label = '', this.width = 40})
    : _startTime = DateTime.now() {
    if (!stdout.hasTerminal) {
      return;
    }
    // 커서 숨기기
    stdout.write("\x1B[?25l");
    _render(0);
  }

  /// 현재 진행 값을 업데이트 한다.
  void update(int current) {
    _current = current.clamp(0, total);
    if (!stdout.hasTerminal) {
      return;
    }
    _render(_current);
  }

  /// 진행률을 완료 상태로 표시한다.
  void complete({String? message}) {
    if (!stdout.hasTerminal) {
      if (message != null) {
        print(message);
      }
      return;
    }

    // 완료 상태로 렌더링
    _render(total);
    stdout.writeln();

    // 커서 복원
    stdout.write("\x1B[?25h");

    if (message != null) {
      print(message);
    }
  }

  /// 진행률 바를 화면에 그린다.
  void _render(int current) {
    final percent = total > 0 ? current / total : 0;
    final filled = (width * percent).toInt();
    final empty = width - filled;

    final bar = "${'█' * filled}${'░' * empty}";
    final percentStr = "${(percent * 100).toStringAsFixed(1).padLeft(5)}%";

    final elapsed = DateTime.now().difference(_startTime);
    final eta = _calculateEta(current, elapsed);

    final line =
        '\r${label.isNotEmpty ? "$label " : ""}'
        '[$bar] $percentStr $current/$total ETA: $eta';

    stdout.write(line);
  }

  String _calculateEta(int current, Duration elapsed) {
    if (current == 0) {
      return '--:--';
    }
    final totalSeconds = elapsed.inSeconds * total / current;
    final remainingSeconds = (totalSeconds - elapsed.inSeconds).round();

    if (remainingSeconds < 0) {
      return '00:00';
    }

    final m = remainingSeconds ~/ 60;
    final s = remainingSeconds % 60;

    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, "0")}}";
  }
}
