import 'dart:ffi';
import 'dart:math';

import 'package:sqflite_common_ffi/sqflite_common_ffi.dart'
    as sqflite_common_ffi;

/// SQLite 데이터베이스 관리
class Database {
  Database._(this.db);

  /// 데이터베이스를 열고 스키마를 초기화한다.
  static Future<Database> open(String path) async {
    var databaseFactory = sqflite_common_ffi.databaseFactoryFfi;

    final db = await databaseFactory.openDatabase(path);

    final instance = Database._(db);

    await instance._initialize();
    return instance;
  }

  /// 인메모리 데이터베이스를 생성한다
  static Future<Database> openInMemory() async {
    var databaseFactory = sqflite_common_ffi.databaseFactoryFfi;

    // 겹치면 로또부터 사자
    final db = await databaseFactory.openDatabase(
      '${Random().nextInt(4294967296)}:memory:',
    );
    final instance = Database._(db);

    await instance._initialize();

    return instance;
  }

  final sqflite_common_ffi.Database db;

  Future<void> _initialize() async {
    await db.execute('PRAGMA journal_mode=WAL;');
    await db.execute('PRAGMA foreign_keys=ON;');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      );
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS todos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        completed INTEGER NOT NULL DEFAULT 0,
        user_id INTEGER NOT NULL,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        updated_at TEXT,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      );
    ''');
    // 인덱스 생성
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_todos_user_id ON todos(user_id);',
    );
  }

  /// 연결을 닫는다.
  void close() => db.close();
}
