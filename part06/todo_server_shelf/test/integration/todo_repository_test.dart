import 'package:test/test.dart';
import 'package:todo_server_shelf/database.dart';
import 'package:todo_server_shelf/exceptions.dart';
import 'package:todo_server_shelf/repository/todo_repository.dart';
import 'package:todo_server_shelf/repository/user_repository.dart';

void main() {
  late Database db;
  late TodoRepository todoRepo;
  late UserRepository userRepo;
  late int testUserId;

  setUp(() async {
    // 인메모리 DB 사용
    db = await Database.openInMemory();
    todoRepo = TodoRepository(db);
    userRepo = UserRepository(db);

    // 테스트 사용자 생성
    final user = await userRepo.create(
      email: "test@example.com",
      passwordHash: 'hash',
    );
    testUserId = user.id;
  });

  tearDown(() async => db.close());

  group('create', () {
    test('할 일 생성 성공', () async {
      final todo = await todoRepo.create(userId: testUserId, title: '테스트 할 일');

      expect(todo.id, greaterThan(0));
      expect(todo.title, equals('테스트 할 일'));
      expect(todo.completed, isFalse);
      expect(todo.userId, equals(testUserId));
    });
  });

  group('findByUserId', () {
    test('사용자 할 일 목록 조회', () async {
      await todoRepo.create(userId: testUserId, title: '할 일 1');
      await todoRepo.create(userId: testUserId, title: '할 일 2');

      final todos = await todoRepo.findByUserId(testUserId);
      expect(todos, hasLength(2));
    });

    test('완료 필터링', () async {
      await todoRepo.create(userId: testUserId, title: '미완료');
      final todo2 = await todoRepo.create(userId: testUserId, title: '완료');
      await todoRepo.update(id: todo2.id, completed: true);
      final incomplete = await todoRepo.findByUserId(
        testUserId,
        completed: false,
      );
      expect(incomplete, hasLength(1));
      expect(incomplete.first.title, equals('미완료'));
    });

    test('다른 사용자의 할 일 미포함', () async {
      await userRepo.create(email: 'other@example.com', passwordHash: 'h');
      await todoRepo.create(userId: testUserId, title: '내 할 일');

      final myTodos = await todoRepo.findByUserId(testUserId);
      expect(myTodos, hasLength(1));
      expect(myTodos.first.title, equals('내 할 일'));
    });
  });

  group('update', () {
    test('제목 수정', () async {
      final todo = await todoRepo.create(userId: testUserId, title: '현재 제목');
      final updated = await todoRepo.update(id: todo.id, title: '새 제목');

      expect(updated.title, equals('새 제목'));
      expect(updated.updatedAt, isNotNull);
    });

    test('완료 상태 변경', () async {
      final todo = await todoRepo.create(userId: testUserId, title: '할 일');
      final updated = await todoRepo.update(id: todo.id, completed: true);

      expect(updated.completed, isTrue);
    });

    test('존재하지 않는 ID - NotFoundException', () async {
      expect(
        () async => await todoRepo.update(id: 9999, title: '없는 할 일'),
        throwsA(isA<NotFoundException>()),
      );
    });
  });

  group('delete', () {
    test('할 일 삭제', () async {
      final todo = await todoRepo.create(userId: testUserId, title: '삭제할 일');
      await todoRepo.delete(todo.id);

      final found = await todoRepo.findById(todo.id);
      expect(found, isNull);
    });

    test('존재하지 않는 ID - NotFoundException', () async {
      expect(
        () async => await todoRepo.delete(9999),
        throwsA(isA<NotFoundException>()),
      );
    });
  });
}
