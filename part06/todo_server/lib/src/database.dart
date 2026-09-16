import 'package:sqlite3/sqlite3.dart' as sqlite3;

/// SQLite 데이터베이스 관리
class Database {
  Database._(this._db);

  /// 데이터베이스를 열고 스키마를 초기화한다.
  factory Database.open(String path) {
    final db = sqlite3.sqlite3.open(path);
    final instance = Database._(db).._initialize();

    return instance;
  }

  /// 인메모리 데이터베이스를 생성한다
  factory Database.openInMemory() {
    final db = sqlite3.sqlite3.openInMemory();
    final instance = Database._(db).._initialize();

    return instance;
  }

  final sqlite3.Database _db;

  void _initialize() {
    // WAL 모드 활성화
    _db
      ..execute('PRAGMA journal_mode=WAL;')
      ..execute('PRAGMA foreign_keys=ON;')
      // 테이블 생성
      ..execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      );
      ''')
      ..execute('''
      CREATE TABLE IF NOT EXISTS todos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        completed INTEGER NOT NULL DEFAULT 0,
        user_id INTEGER NOT NULL,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        updated_at TEXT,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      );
      ''')
      // 인덱스 생성
      ..execute(
        'CREATE INDEX IF NOT EXISTS idx_todos_user_id ON todos(user_id);',
      );
  }

  /// 원시 SQL을 실행한다.
  void excute(String sql, [List<Object?> parameters = const []]) {
    _db.execute(sql, parameters);
  }

  /// SELECT 결과를 Map 목록으로 반환한다.
  List<Map<String, dynamic>> query(
    String sql, [
    List<Object?> parameters = const [],
  ]) {
    final result = _db.select(sql, parameters);
    return result.map(Map<String, dynamic>.from).toList();
  }

  /// 마지막으로 삽입된 행의 ID를 반환한다.
  int get lastInsertRowId => _db.lastInsertRowId;

  /// 변경된 행 수를 반환한다.
  int get updatedRows => _db.updatedRows;

  /// 연결을 닫는다.
  void close() => _db.close();
}
