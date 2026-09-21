import 'dart:io';

import 'package:shelf/shelf_io.dart';
import 'package:todo_server_shelf/router.dart';

void main(List<String> args) async {
  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.anyIPv4;

  // For running in containers, we respect the PORT environment variable.
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(await getAppHandler(), ip, port);
  print('Server listening on port ${server.port}');
}
