import 'package:todo_server_shelf/database.dart';
import 'package:todo_server_shelf/exceptions.dart';
import 'package:todo_server_shelf/models/todo.dart';

class TodoRepository {
  const TodoRepository(this._db);

  final Database _db;

  /// 사용자의 모든 할 일을 조회한다.
  Future<List<Todo>> findByUserId(
    int userId, {
    bool? completed,
    int limit = 20,
    int offset = 0,
  }) async {
    final buffer = StringBuffer('SELECT * FROM todos WHERE user_id = ?');
    final params = <Object?>[userId];

    if (completed != null) {
      buffer.write(' AND completed = ?');
      params.add(completed ? 1 : 0);
    }

    buffer.write(' ORDER BY created_at DESC LIMIT ? OFFSET ?');
    params.addAll([limit, offset]);

    final rows = await _db.db.rawQuery(buffer.toString(), params);

    return rows.map(Todo.fromMap).toList();
  }

  /// 특정 할 일을 ID로 조회한다.
  Future<Todo?> findById(int id) async {
    final rows = await _db.db.rawQuery('SELECT * FROM todos WHERE id = ?', [
      id,
    ]);

    if (rows.isEmpty) {
      return null;
    }

    return Todo.fromMap(rows.first);
  }

  /// 새로운 할 일을 생성한다.
  /// 반환값은 생성된 할 일 객체이다.
  Future<Todo> create({required int userId, required String title}) async {
    return _db.db
        .rawQuery(
          '''
          INSERT INTO todos (title, user_id) 
          VALUES (?, ?)
          RETURNING id, title, completed, user_id, created_at, updated_at;
          ''',
          [title, userId],
        )
        .then((rows) => Todo.fromMap(rows.first));
  }

  /// 할 일을 수정한다.
  Future<Todo> update({required int id, String? title, bool? completed}) async {
    final existing = await findById(id);
    if (existing == null) {
      throw const NotFoundException('할 일을 찾을 수 없습니다.');
    }

    final newTitle = title ?? existing.title;
    final newCompleted = completed ?? existing.completed;

    return _db.db
        .rawQuery(
          '''
          UPDATE todos 
          SET title = ?, completed = ?, updated_at = datetime('now') 
          WHERE id = ?
          RETURNING id, title, completed, user_id, created_at, updated_at;
          ''',
          [newTitle, if (newCompleted) 1 else 0, id],
        )
        .then((rows) => Todo.fromMap(rows.first));
  }

  /// 할 일을 삭제한다.
  /// 반환값은 삭제한 행수이다.
  Future<int> delete(int id) async {
    if ((await _db.db.rawQuery(
      '''SELECT '1' FROM todos WHERE id = ?''',
      [id],
    )).isEmpty) {
      throw const NotFoundException('할 일을 찾을 수 없습니다.');
    }
    return _db.db.rawDelete('DELETE FROM todos WHERE id = ?', [id]);
  }

  /// 사용자의 할 일 수를 반환한다.
  Future<int> countByUserId(int userId, {bool? completed}) async {
    var sql = 'SELECT COUNT(*) as cnt FROM todos WHERE user_id = ?';
    final params = <Object?>[userId];

    if (completed != null) {
      sql += ' AND completed = ?';
      params.add(completed ? 1 : 0);
    }

    final rows = await _db.db.rawQuery(sql, params);
    return rows.first['cnt'] as int;
  }
}
