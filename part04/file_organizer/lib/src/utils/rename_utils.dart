String applyRenameRules(
  String name,
  Iterable<({String pattern, String replacement})> rules,
) {
  var newName = name;

  for (final rule in rules) {
    final regex = RegExp(rule.pattern);
    newName = newName.replaceAll(regex, rule.replacement);
  }

  return newName;
}
