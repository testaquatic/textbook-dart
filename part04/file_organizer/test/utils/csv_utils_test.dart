import 'package:file_organizer/src/utils/csv_utils.dart';
import 'package:test/test.dart';

void main() {
  group("parseCsvLine", () {
    group("기본 동작", () {
      test("단일 필드", () {
        expect(parseCsvLine("hello"), equals(["hello"]));
      });

      test("다중 필드", () {
        expect(parseCsvLine("a,b,c"), equals(["a", "b", "c"]));
      });

      test("빈 문자열", () {
        expect(parseCsvLine(""), equals([""]));
      });

      test("앞뒤 공백 유지", () {
        expect(parseCsvLine(" a , b , c "), equals([" a ", " b ", " c "]));
      });
    });

    group("큰따옴표 처리", () {
      test("따옴표로 감싼 필드", () {
        expect(parseCsvLine('"hello"'), equals(["hello"]));
      });

      test("따옴표 안의 쉼표", () {
        expect(parseCsvLine('"a,b",c'), equals(["a,b", "c"]));
      });

      test('이스케이프된 따옴표 ("" => ")', () {
        expect(parseCsvLine('"say ""hello""",c'), equals(['say "hello"', "c"]));
      });

      test("빈 따옴표 필드", () {
        expect(parseCsvLine('"",b'), ['', 'b']);
      });
    });

    group("경계 케이스", () {
      test("끝에 쉼표", () {
        expect(parseCsvLine("a,b,"), equals(["a", "b", ""]));
      });
      test("쉼표만 있는 경우", () {
        expect(parseCsvLine(","), equals(["", ""]));
      });
    });
  });

  group("toCsv", () {
    test("빈 목록", () {
      expect(toCsv([]), equals(""));
    });

    test("헤더와 데이터 행 생성", () {
      final data = [
        {"name": "Alice", "age": "38"},
        {"name": "Bob", "age": "25"},
      ];
      final csv = toCsv(data);
      final lines = csv.trim().split("\n");

      expect(lines[0], equals("name,age"));
      expect(lines[1], equals("Alice,38"));
      expect(lines[2], equals("Bob,25"));
    });

    test("쉼표 포함 값은 큰 따옴표로 감쌈", () {
      final data = [
        {"desc": "hello, world"},
      ];
      final csv = toCsv(data);
      expect(csv, contains('"hello, world"'));
    });

    test("큰따옴표 포함 값은 이스케이프", () {
      final data = [
        {"desc": 'say "hi"'},
      ];
      final csv = toCsv(data);
      expect(csv, contains('"say ""hi"""'));
    });
  });

  group("parseRulesFromCsv", () {
    test("정상 규칙 파싱", () {
      const csv = '''pattern,replacement,description
^IMG_(\\d+),photo_\$1,iPhone 사진
\\s+,_,공백 변환''';

      final rules = parseRulesFromCsv(csv);

      expect(rules, hasLength(2));
      expect(rules[0].pattern, equals(r"^IMG_(\d+)"));
      expect(rules[0].replacement, equals(r"photo_$1"));
      expect(rules[0].description, equals("iPhone 사진"));
      expect(rules[1].description, equals("공백 변환"));
    });

    test("빈 패턴은 행은 무시", () {
      const csv = "pattern,replacement\n,replacement_only\nvalid,ok";
      final rules = parseRulesFromCsv(csv);
      expect(rules, hasLength(1));
      expect(rules[0].pattern, equals("valid"));
    });

    test("설명 없는 규칙", () {
      const csv = "pattern,replacement,description\nfoo,bar,";
      final rules = parseRulesFromCsv(csv);
      expect(rules[0].description, isNull);
    });
  });
}
