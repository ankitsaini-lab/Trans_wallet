import 'package:flutter_test/flutter_test.dart';
import 'package:transwallet/utilities/string_extensions.dart';

void main() {
  test('safeUtf16 preserves well-formed strings', () {
    const normal = "Transaction +₹500.00";
    expect(normal.safeUtf16(), equals(normal));

    const withEmoji = "Payment to John 💳";
    expect(withEmoji.safeUtf16(), equals(withEmoji));
  });

  test('safeUtf16 sanitizes unpaired high surrogates', () {
    // 0xD800 alone without low surrogate
    final malformed = String.fromCharCodes([0x0041, 0xD800, 0x0042]);
    final safe = malformed.safeUtf16();
    expect(safe, equals("A\uFFFD\u0042"));
  });

  test('safeUtf16 sanitizes unpaired low surrogates', () {
    // 0xDC00 alone without preceding high surrogate
    final malformed = String.fromCharCodes([0x0041, 0xDC00, 0x0042]);
    final safe = malformed.safeUtf16();
    expect(safe, equals("A\uFFFD\u0042"));
  });

  test('formatUserName sanitizes malformed input', () {
    final malformed = String.fromCharCodes([0x0061, 0xD800, 0x0062]);
    final formatted = formatUserName(malformed);
    expect(formatted, isNotEmpty);
  });
}
