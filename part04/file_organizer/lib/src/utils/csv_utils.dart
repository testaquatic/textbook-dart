/// CSV 한 줄을 필드 목록으로 파싱한다
///
/// RFC 4180 규격을 기본으로 지원한다.
/// - 필드를 큰따옴표로 감쌀 수 있다
/// - 큰따옴표 안의 쉼표는 구분자로 처리하지 않는다
/// - 큰따옴표를 이스케이프하려면 '""'을 사용한다
List<String> parseCsvLine(String line) {
  final fields = <String>[];
  final buffer = StringBuffer();
  var inQuotes = false;

  for (var i = 0; i < line.length; i++) {
    final char = line[i];

    if (char == '"') {
      if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
        // 이스케이프된 따옴표 ("") -> 따옴표 하나로 변환
        buffer.write('"');
        i++; // 다음 따옴표 건너 뜀
      } else {
        inQuotes = !inQuotes;
      }
    } else if (char == "," && !inQuotes) {
      fields.add(buffer.toString());
      buffer.clear();
    } else {
      buffer.write(char);
    }
  }

  fields.add(buffer.toString());

  return fields;
}

/// CSV 문자열 전체를 파싱한다.
/// 첫 줄은 헤더로 처리한다.
///
/// 반환: 헤더 키를 키로 갖는 Map 목록
List<Map<String, String>> parseCsv(String content) {
  final lines = content.split('\n').where((l) => l.trim().isNotEmpty).toList();

  if (lines.isEmpty) {
    return [];
  }

  final headers = parseCsvLine(lines.first);
  final result = <Map<String, String>>[];

  for (final line in lines.skip(1)) {
    final fields = parseCsvLine(line);
    final row = <String, String>{};

    for (var i = 0; i < headers.length; i++) {
      row[headers[i]] = i < fields.length ? fields[i] : "";
    }
    result.add(row);
  }

  return result;
}

/// CSV 파일에서 이름 변경 규칙을 읽는다.
///
/// CSV 형식 (헤더 필수):
///
/// ```
/// pattern,replacement,description
/// ^IMG_(\d+),photo_$1,iPhone 사진 변환
/// ```
List<({String pattern, String replacement, String? description})>
parseRulesFromCsv(String csvContent) {
  final rows = parseCsv(csvContent);

  return rows
      .map((row) {
        final description = row['description'];
        return (
          pattern: row['pattern'] ?? "",
          replacement: row['replacement'] ?? "",
          description: (description?.isEmpty ?? true) ? null : description,
        );
      })
      .where((r) => r.pattern.isNotEmpty)
      .toList();
}

/// 데이터를 CSV 형식으로 직렬화한다.
String toCsv(List<Map<String, dynamic>> data) {
  if (data.isEmpty) {
    return '';
  }

  final headers = data.first.keys.toList();
  final buffer = StringBuffer();

  // 헤더 행
  buffer.writeln(headers.map(_escapeCsvField).join(','));

  // 데이터 행
  for (final row in data) {
    buffer.writeln(
      headers.map((h) => _escapeCsvField(row[h]?.toString() ?? "")).join(","),
    );
  }

  return buffer.toString();
}

String _escapeCsvField(String fields) {
  // 쉼표, 큰따옴표, 줄바꿈이 있으면 큰따옴표로 감쌈
  if (fields.contains(",") || fields.contains('"') || fields.contains('\n')) {
    return '"${fields.replaceAll('"', '""')}"';
  }

  return fields;
}
