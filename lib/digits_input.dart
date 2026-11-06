import 'package:flutter/services.dart';

import 'digits.dart';

/// Accepts only digits and turns Arabic-Indic or Persian digits into 0-9 while typing or pasting.
class AsciiDigitsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final r = cleanDigits(newValue.text, newValue.selection.end);
    if (r.text == newValue.text) return newValue;
    return TextEditingValue(text: r.text, selection: TextSelection.collapsed(offset: r.offset));
  }
}
