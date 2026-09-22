import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shelf/shelf_io.dart';
import 'package:todo_server_shelf/config.dart';
import 'package:todo_server_shelf/database.dart';
import 'package:todo_server_shelf/repository/todo_repository.dart';
import 'package:todo_server_shelf/repository/user_repository.dart';
import 'package:todo_server_shelf/router.dart';

void main(List<String> args) async {
  // 설정 파일 로딩
  final appConfig = AppConfig.fromEnvironment();

  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.anyIPv4;

  // 데이터베이스 설정
  final currentPath = p.join(Directory.current.path, appConfig.dbPath);
  final db = await Database.open(currentPath);
  final todoRepo = TodoRepository(db);
  final userRepo = UserRepository(db);

  final server = await serve(
    await getAppHandler(
      todoRepo: todoRepo,
      userRepo: userRepo,
      appConfig: appConfig,
    ),
    ip,
    appConfig.port,
  );
  print('Server listening on port ${server.port}');
}
