import 'package:todo_server_shelf/database.dart';
import 'package:todo_server_shelf/models/user.dart';

class UserRepository {
  const UserRepository(this._db);

  final Database _db;

  Future<User?> findByEmail(String email) async {
    final rows = await _db.db.rawQuery('SELECT * FROM users WHERE email = ?', [
      email,
    ]);

    if (rows.isEmpty) {
      return null;
    }

    return User.fromMap(rows.first);
  }

  Future<User?> findById(int id) async {
    final rows = await _db.db.rawQuery('SELECT * FROM users WHERE id = ?', [
      id,
    ]);
    if (rows.isEmpty) {
      return null;
    }

    return User.fromMap(rows.first);
  }

  Future<User> create({
    required String email,
    required String passwordHash,
  }) async {
    final rows = await _db.db.rawQuery(
      '''
      INSERT INTO users (email, password_hash) 
      VALUES (?, ?) 
      RETURNING id, email, password_hash, created_at;''',
      [email, passwordHash],
    );

    return User.fromMap(rows.first);
  }
}
