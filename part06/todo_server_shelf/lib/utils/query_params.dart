/// 쿼리 파라미터에서 정수 값을 안전하게 추출한다
int parseIntParams(
  Map<String, String> params,
  String key, {
  required int defaultValue,
  int? min,
  int? max,
}) {
  final raw = params[key];
  if (raw == null) {
    return defaultValue;
  }

  final value = int.tryParse(raw) ?? defaultValue;
  if (min != null && value < min) {
    return min;
  }
  if (max != null && value > max) {
    return max;
  }

  return value;
}

/// 쿼리 파라미터에서 불리언 값을 추출한다.
bool? parseBoolQueryParam(Map<String, String> params, String key) {
  final raw = params[key];
  if (raw == null) {
    return null;
  }

  return raw == 'true' || raw == '1';
}
