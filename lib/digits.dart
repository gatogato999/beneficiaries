/// Converts Arabic-Indic and Persian digits to 0-9.
String asciiDigits(String s) {
  final b = StringBuffer();
  for (final r in s.runes) {
    if (r >= 0x0660 && r <= 0x0669) {
      b.writeCharCode(0x30 + r - 0x0660);
    } else if (r >= 0x06F0 && r <= 0x06F9) {
      b.writeCharCode(0x30 + r - 0x06F0);
    } else {
      b.writeCharCode(r);
    }
  }
  return b.toString();
}

/// Finds an account number in pasted text: the first run of 4 to 20 digits
/// (single spaces, dashes or dots between digits are allowed). Null if there is none.
String? extractAccountNumber(String text) {
  final m = RegExp(r'\d(?:[ \-.]?\d){3,}').firstMatch(asciiDigits(text));
  if (m == null) return null;
  final digits = m.group(0)!.replaceAll(RegExp(r'\D'), '');
  return digits.length <= 20 ? digits : null;
}

/// Keeps only digits (Arabic-Indic and Persian ones become 0-9) and maps the cursor position.
({String text, int offset}) cleanDigits(String text, int cursor) {
  final out = StringBuffer();
  var offset = 0;
  var i = 0; // position in UTF-16 units, like the cursor
  final end = cursor < 0 || cursor > text.length ? text.length : cursor;
  for (final r in text.runes) {
    final c = asciiDigits(String.fromCharCode(r));
    if (c.length == 1 && c.codeUnitAt(0) >= 0x30 && c.codeUnitAt(0) <= 0x39) {
      out.write(c);
      if (i < end) offset++;
    }
    i += r > 0xFFFF ? 2 : 1;
  }
  return (text: out.toString(), offset: offset);
}
