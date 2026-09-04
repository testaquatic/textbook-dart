import 'dart:io';

import 'package:file_organizer/file_organizer.dart';

Future<void> main(List<String> arguments) async {
  final runner = FileOrganizerRunner();

  try {
    await runner.run(arguments);
  } on UsageException catch (e) {
    stderr.writeln(e.message);
    stderr.writeln();
    stderr.writeln(e.usage);
    exit(64);
  } catch (e) {
    stderr.writeln('오류: $e');
    exit(1);
  }
}
