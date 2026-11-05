extension StringCapitalizeExtension on String {
  /// Converts string to Title Case (capitalizes first letter of each word)
  String toTitleCase() {
    if (trim().isEmpty) return '';
    return split(RegExp(r'\s+')).map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Sanitizes string to ensure it contains only well-formed UTF-16 code units.
  /// Replaces any isolated/unpaired surrogate code units with the replacement character U+FFFD.
  String safeUtf16() {
    if (isEmpty) return '';
    final units = codeUnits;
    final len = units.length;
    bool hasUnpaired = false;

    for (int i = 0; i < len; i++) {
      final unit = units[i];
      if (unit >= 0xD800 && unit <= 0xDBFF) {
        // High surrogate
        if (i + 1 < len) {
          final next = units[i + 1];
          if (next >= 0xDC00 && next <= 0xDFFF) {
            i++; // Valid surrogate pair
            continue;
          }
        }
        hasUnpaired = true;
        break;
      } else if (unit >= 0xDC00 && unit <= 0xDFFF) {
        // Isolated low surrogate
        hasUnpaired = true;
        break;
      }
    }

    if (!hasUnpaired) return this;

    final buffer = StringBuffer();
    for (int i = 0; i < len; i++) {
      final unit = units[i];
      if (unit >= 0xD800 && unit <= 0xDBFF) {
        if (i + 1 < len) {
          final next = units[i + 1];
          if (next >= 0xDC00 && next <= 0xDFFF) {
            buffer.writeCharCode(unit);
            buffer.writeCharCode(next);
            i++;
            continue;
          }
        }
        buffer.writeCharCode(0xFFFD);
      } else if (unit >= 0xDC00 && unit <= 0xDFFF) {
        buffer.writeCharCode(0xFFFD);
      } else {
        buffer.writeCharCode(unit);
      }
    }
    return buffer.toString();
  }
}

extension SafeNullableUtf16Extension on String? {
  /// Safely converts nullable string to a well-formed UTF-16 string
  String toSafeUtf16([String fallback = '']) {
    if (this == null) return fallback;
    return this!.safeUtf16();
  }
}

/// Helper to format user names with first letter of each word capitalized
String formatUserName(dynamic name) {
  if (name == null) return "User";
  final str = name.toString().trim().safeUtf16();
  if (str.isEmpty) return "User";
  return str.toTitleCase().safeUtf16();
}
