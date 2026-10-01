extension StringCapitalizeExtension on String {
  /// Converts string to Title Case (capitalizes first letter of each word)
  String toTitleCase() {
    if (trim().isEmpty) return '';
    return split(RegExp(r'\s+')).map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}

/// Helper to format user names with first letter of each word capitalized
String formatUserName(dynamic name) {
  if (name == null) return "User";
  final str = name.toString().trim();
  if (str.isEmpty) return "User";
  return str.toTitleCase();
}
