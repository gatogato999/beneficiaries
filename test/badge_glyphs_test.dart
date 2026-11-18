import 'dart:io';

import 'package:beneficiaries/badge_glyphs.dart';
import 'package:beneficiaries/bank_style.dart';
import 'package:beneficiaries/banks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every letter used by a built-in bank has measurements', () {
    for (final b in banks) {
      final letter = bankLetter(b.name);
      expect(glyphInkFor(letter) != null, isTrue, reason: '${b.id} -> $letter');
    }
  });

  test('the measurements are plausible', () {
    expect(kBadgeGlyphs.length >= 40, isTrue);
    for (final e in kBadgeGlyphs.entries) {
      final g = e.value;
      expect(g.cx.abs() < 0.15, isTrue, reason: 'cx of ${e.key}');
      expect(g.cy > -0.2 && g.cy < 0.7, isTrue, reason: 'cy of ${e.key}');
      expect(g.w > 0.05 && g.w < 1.5, isTrue, reason: 'w of ${e.key}');
      expect(g.h > 0.05 && g.h < 1.5, isTrue, reason: 'h of ${e.key}');
    }
  });

  group('size', () {
    test('every letter fits its box and the size stays within 30% to 62% of the diameter', () {
      const d = 100.0;
      for (final e in kBadgeGlyphs.entries) {
        final fs = badgeFontSize(d, e.value);
        expect(e.value.w * fs <= d * 0.52 + 0.01, isTrue, reason: 'width of ${e.key}');
        expect(e.value.h * fs <= d * 0.46 + 0.01, isTrue, reason: 'height of ${e.key}');
        expect(fs >= d * 0.30 - 0.001 && fs <= d * 0.62 + 0.001, isTrue, reason: 'size of ${e.key}');
      }
    });

    test('a letter without measurements gets 45% of the diameter', () {
      expect(badgeFontSize(40, null), 18);
    });

    test('the size scales with the badge', () {
      final g = glyphInkFor('ب')!;
      expect((badgeFontSize(48, g) - 2 * badgeFontSize(24, g)).abs() < 1e-9, isTrue);
    });
  });

  group('placement', () {
    test('the ink centre lands in the middle of the circle for every letter', () {
      const d = 24.0;
      for (final e in kBadgeGlyphs.entries) {
        final fs = badgeFontSize(d, e.value);
        const boxWidth = 9.3, boxHeight = 17.1, baseline = 13.4; // any layout numbers will do
        final o = badgeTextOrigin(
            diameter: d, fontSize: fs, boxWidth: boxWidth, boxHeight: boxHeight, baseline: baseline, ink: e.value);
        final inkCentreX = o.x + boxWidth / 2 + e.value.cx * fs;
        final inkCentreY = o.y + baseline - e.value.cy * fs;
        expect((inkCentreX - d / 2).abs() < 1e-9, isTrue, reason: 'x of ${e.key}');
        expect((inkCentreY - d / 2).abs() < 1e-9, isTrue, reason: 'y of ${e.key}');
      }
    });

    test('a letter without measurements is centred by its text box', () {
      final o = badgeTextOrigin(diameter: 24, fontSize: 12, boxWidth: 8, boxHeight: 14, baseline: 11);
      expect(o.x + 4, 12);
      expect(o.y + 7, 12);
    });
  });

  test('glyphInkFor only answers for a single known letter', () {
    expect(glyphInkFor('ب') != null, isTrue);
    expect(glyphInkFor('B'), isNull);
    expect(glyphInkFor(''), isNull);
    expect(glyphInkFor('بب'), isNull);
  });

  test('the font and its licence are bundled and registered in pubspec.yaml', () {
    final font = File('assets/fonts/BadgeLetters-Bold.ttf');
    expect(font.existsSync(), isTrue);
    expect(font.readAsBytesSync().sublist(0, 4), equals([0, 1, 0, 0])); // TrueType header
    expect(File('assets/fonts/OFL-NotoSansArabic.txt').existsSync(), isTrue);
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec.contains('family: BadgeLetters'), isTrue);
    expect(pubspec.contains('assets/fonts/BadgeLetters-Bold.ttf'), isTrue);
    expect(pubspec.contains('assets/fonts/OFL-NotoSansArabic.txt'), isTrue);
  });
}
