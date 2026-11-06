import 'package:beneficiaries/digits.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('asciiDigits', () {
    test('Arabic-Indic and Persian digits become 0-9', () {
      expect(asciiDigits('\u0661\u0662\u0663\u0664\u0665\u0666\u0667'), '1234567');
      expect(asciiDigits('\u06F1\u06F2\u06F3'), '123');
    });
    test('other characters are untouched', () {
      expect(asciiDigits('ab 12 -'), 'ab 12 -');
    });
  });

  group('extractAccountNumber', () {
    test('plain number', () => expect(extractAccountNumber('1234567'), '1234567'));
    test('four digits is the shortest accepted number', () {
      expect(extractAccountNumber('1234'), '1234');
      expect(extractAccountNumber('x 1234 y'), '1234');
    });
    test('number inside text', () => expect(extractAccountNumber('Account: 1234567, thanks'), '1234567'));
    test('Arabic-Indic digits inside Arabic text', () {
      expect(extractAccountNumber('\u0631\u0642\u0645 \u0627\u0644\u062D\u0633\u0627\u0628: \u0661\u0662\u0663\u0664\u0665\u0666\u0667'), '1234567');
    });
    test('single spaces and dashes inside the number are removed', () {
      expect(extractAccountNumber('123 4567'), '1234567');
      expect(extractAccountNumber('123-4567'), '1234567');
    });
    test('too short or no digits gives null', () {
      expect(extractAccountNumber('123'), isNull);
      expect(extractAccountNumber('no number here'), isNull);
      expect(extractAccountNumber(''), isNull);
    });
    test('a very long digit string is refused', () {
      expect(extractAccountNumber('1' * 25), isNull);
    });
    test('the first number wins', () {
      expect(extractAccountNumber('1111111 and 2222222'), '1111111');
    });
  });

  group('cleanDigits', () {
    test('digits only and the cursor follows', () {
      final r = cleanDigits('12a34', 4);
      expect(r.text, '1234');
      expect(r.offset, 3);
    });
    test('Arabic-Indic digits are converted and the cursor is kept', () {
      final r = cleanDigits('\u0661\u0662\u0663', 3);
      expect(r.text, '123');
      expect(r.offset, 3);
    });
    test('a bad cursor goes to the end', () {
      expect(cleanDigits('123', -1).offset, 3);
    });
    test('nothing left gives an empty string', () {
      expect(cleanDigits('abc', 3).text, '');
    });
  });
}
