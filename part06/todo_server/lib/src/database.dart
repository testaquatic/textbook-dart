import 'package:sqlite_async/sqlite_async.dart';

/// SQLite 데이터베이스 관리
class Database {
  Database._(this._db);

  /// 데이터베이스를 열고 스키마를 초기화한다.
  factory Database.open(String path) {
    final db = SqliteDatabase(path: path);
    final instance = Database._(db);

    instance._initialize().whenComplete(
      () => instance._isInitalized = true,
    );
    while (!instance._isInitalized) {}
    return instance;
  }

  /// 인메모리 데이터베이스를 생성한다
  static Future<Database> openInMemory() async {
    final db = SqliteDatabase(path: ':memory:');
    final instance = Database._(db);

    await instance._initialize();

    return instance;
  }

  final SqliteDatabase _db;
  var _isInitalized = false;

  Future<void> _initialize() async {
    // WAL 모드 활성화
    await _db.execute('PRAGMA journal_mode=WAL;');
    await _db.execute('PRAGMA foreign_keys=ON;');
    // 테이블 생성
    await _db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      );
      ''');
    await _db.execute('''
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
    await _db.execute(
      'CREATE INDEX IF NOT EXISTS idx_todos_user_id ON todos(user_id);',
    );
  }

  /// 원시 SQL을 실행한다.
  Future<void> excute(String sql, [List<Object?> parameters = const []]) async {
    await _db.execute(sql, parameters);
  }

  /// SELECT 결과를 Map 목록으로 반환한다.
  Future<List<Map<String, dynamic>>> query(
    String sql, [
    List<Object?> parameters = const [],
  ]) async {
    final result = await _db.getAll(sql, parameters);

    return result.map(Map<String, dynamic>.from).toList();
  }

  /// 연결을 닫는다.
  void close() => _db.close();
}
