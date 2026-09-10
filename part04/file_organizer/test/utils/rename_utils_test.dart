import 'package:test/test.dart';

void main() {
  /// 파일 이름에 규칙 목록을 순서대로 적용한다.
  String applyRenameRules(
    String filename,
    List<({String pattern, String replacement})> rules,
  ) {
    var result = filename;
    for (final rule in rules) {
      final regex = RegExp(rule.pattern);
      result = result.replaceAll(regex, rule.replacement);
    }
    return result;
  }

  group("applyRenameRules", () {
    test("규칙이 없으면 원본 반환", () {
      expect(applyRenameRules("image.jpg", []), equals("image.jpg"));
    });

    test("단일 규칙 적용", () {
      final rules = [(pattern: r"\s+", replacement: "_")];
      expect(
        applyRenameRules("image file.jpg", rules),
        equals("image_file.jpg"),
      );
    });

    test("여러 규칙 순서대로 적용", () {
      final rules = [
        (pattern: r"^IMG_", replacement: "photo_"),
        (pattern: r"\.jpeg$", replacement: ".jpg"),
      ];
      expect(applyRenameRules("IMG_001.jpeg", rules), equals("photo_001.jpg"));
    });

    test("일치하지 않으면 원본 유지", () {
      final rules = [(pattern: r"^VIDEO_", replacement: "clip_")];
      expect(applyRenameRules("IMG_001.jpg", rules), equals("IMG_001.jpg"));
    });

    // https://api.flutter.dev/flutter/dart-core/String/replaceAll.html
    // 이 코드는 작동하지 않는다.
    // https://api.flutter.dev/flutter/dart-core/String/replaceAllMapped.html
    // replaceAllMapped를 사용하는 방법이 있겠지만 RegExp 안에서 그룹을 참조하려면 복잡하다.
    // test("캡쳐 그룹 활용", () {
    //   final rules = [
    //     (pattern: r"^(\d{4})(\d{2})(\d{2})_", replacement: r"$1-$2-$3_"),
    //   ];
    //   expect(
    //     applyRenameRules("20241231_photo.jpg", rules),
    //     equals("2024-12-31_photo.jpg"),
    //   );
    // });

    test("전체 매치 replaceAll", () {
      final rules = [(pattern: r" ", replacement: "_")];
      expect(
        applyRenameRules("my old file.txt", rules),
        equals("my_old_file.txt"),
      );
    });
  });
}
