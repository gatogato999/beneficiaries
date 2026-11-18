import 'dart:math' as math;

import 'package:beneficiaries/bank_style.dart';
import 'package:beneficiaries/banks.dart';
import 'package:flutter_test/flutter_test.dart';

double _lin(int v) {
  final c = v / 255;
  return c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
}

/// CIE Lab colour difference (the closer to 0, the more alike two colours look).
double deltaE(int a, int b) {
  List<double> lab(int argb) {
    final r = _lin((argb >> 16) & 0xFF), g = _lin((argb >> 8) & 0xFF), bl = _lin(argb & 0xFF);
    final x = (0.4124 * r + 0.3576 * g + 0.1805 * bl) / 0.95047;
    final y = 0.2126 * r + 0.7152 * g + 0.0722 * bl;
    final z = (0.0193 * r + 0.1192 * g + 0.9505 * bl) / 1.08883;
    double f(double t) => t > 0.008856 ? math.pow(t, 1 / 3).toDouble() : 7.787 * t + 16 / 116;
    return [116 * f(y) - 16, 500 * (f(x) - f(y)), 200 * (f(y) - f(z))];
  }

  final p = lab(a), q = lab(b);
  return math.sqrt(math.pow(p[0] - q[0], 2) + math.pow(p[1] - q[1], 2) + math.pow(p[2] - q[2], 2));
}

void main() {
  group('colours', () {
    test('every built-in bank has its own hue entry, so adding a bank forces a choice', () {
      for (final b in banks) {
        expect(kBankHues.containsKey(b.id), isTrue, reason: b.id);
      }
    });

    test('the letter is readable on every built-in colour', () {
      for (final b in banks) {
        final s = bankStyle(b.id, b.name);
        expect(contrastRatio(s.argb, s.letterArgb) >= 4.5, isTrue, reason: b.id);
      }
    });

    test('the letter is readable on all 360 hues', () {
      for (var h = 0; h < 360; h++) {
        final bg = colorForHue(h);
        expect(contrastRatio(bg, letterColorFor(bg)) >= 4.5, isTrue, reason: 'hue $h');
      }
    });

    test('ids without an entry get a stable colour and spread over the whole hue range', () {
      final seen = <int>{};
      for (var i = 0; i < 20000; i++) {
        final h = hueOf('id$i');
        expect(h >= 0 && h < 360, isTrue);
        seen.add(h);
      }
      expect(seen.length > 300, isTrue);
      expect(hueOf('custom_1'), hueOf('custom_1'));
    });

    test('built-in colours are clearly different from each other', () {
      final colours = {for (final b in banks) b.id: bankStyle(b.id, b.name).argb};
      var closest = double.infinity;
      var pair = '';
      for (final a in colours.keys) {
        for (final b in colours.keys) {
          if (a.compareTo(b) < 0) {
            final d = deltaE(colours[a]!, colours[b]!);
            if (d < closest) {
              closest = d;
              pair = '$a / $b';
            }
          }
        }
      }
      expect(closest >= 20, isTrue, reason: 'closest pair is $pair at $closest');
    });

    test('the same id always gives the same colour, whatever the name', () {
      expect(bankStyle('okash', 'أوكاش').argb, bankStyle('okash', 'anything').argb);
      expect(bankStyle('custom_1', 'a').argb, bankStyle('custom_1', 'b').argb);
    });

    test('the background is fully opaque and the letter is white or black', () {
      for (final b in banks) {
        final s = bankStyle(b.id, b.name);
        expect(s.argb >> 24, 0xFF);
        expect(s.letterArgb == 0xFFFFFFFF || s.letterArgb == 0xFF000000, isTrue);
      }
    });
  });

  group('contrast helpers', () {
    test('black on white is 21 and a colour against itself is 1', () {
      expect((contrastRatio(0xFF000000, 0xFFFFFFFF) - 21).abs() < 0.01, isTrue);
      expect((contrastRatio(0xFF336699, 0xFF336699) - 1).abs() < 0.0001, isTrue);
    });

    test('dark backgrounds get a white letter, light ones a black letter', () {
      expect(letterColorFor(0xFF102030), 0xFFFFFFFF);
      expect(letterColorFor(0xFFFFEE88), 0xFF000000);
    });
  });

  group('letters', () {
    test('built-in banks', () {
      const expected = {
        'bankak': 'ب',
        'okash': 'أ',
        'fawry': 'ف',
        'mycashi': 'م',
        'mashreq': 'م',
        'amanplus': 'أ',
        'masrafak': 'م',
        'french': 'ف',
        'zirai': 'ز',
        'salam': 'س',
        'baraka': 'ب',
        'animal': 'ث',
        'aqari': 'ع',
        'industry': 'ت',
        'mal': 'م',
      };
      for (final b in banks) {
        expect(bankStyle(b.id, b.name).letter, expected[b.id], reason: b.id);
      }
    });

    test('Latin names are upper-cased and generic words are skipped', () {
      expect(bankLetter('my bank'), 'M');
      expect(bankLetter('Bank of Nile'), 'O');
      expect(bankLetter('nile'), 'N');
    });

    test('edge cases', () {
      expect(bankLetter(''), '?');
      expect(bankLetter('   '), '?');
      expect(bankLetter('بنك'), 'ب');
      expect(bankLetter('التنمية'), 'ت');
      expect(bankLetter('ال'), 'ا');
    });
  });
}
