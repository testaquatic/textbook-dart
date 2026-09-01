List<double> averages(List<List<int>> groups) {
  return groups.map((group) {
    if (group.isEmpty) {
      return 0.0;
    }
    final sum = group.reduce((a, b) => a + b);
    return sum / group.length;
  }).toList();
}

void main() {
  final data = [
    [1, 2, 3],
    <int>[],
    [10, 20],
  ];

  final results = averages(data);
  print(results);
}
