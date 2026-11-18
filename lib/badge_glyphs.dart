import 'dart:math' as math;

/// Ink box of an isolated Arabic letter in assets/fonts/BadgeLetters-Bold.ttf, in em (1 = the font size).
/// Measured with HarfBuzz and the font's outlines, so a letter can be centred by what is visible
/// instead of by its text box (dots, tails and hamzas shift the visual centre of Arabic letters).
///
/// [cx] is the ink centre minus the box centre (positive = to the right), [cy] is the ink centre above the
/// baseline, [w] and [h] are the ink size.
class GlyphInk {
  final double cx, cy, w, h;
  const GlyphInk(this.cx, this.cy, this.w, this.h);
}

const kBadgeGlyphs = <int, GlyphInk>{
  0x0621: GlyphInk(-0.0105, 0.1895, 0.4310, 0.4930), // ء
  0x0622: GlyphInk(-0.0165, 0.4340, 0.3440, 0.8680), // آ
  0x0623: GlyphInk(-0.0225, 0.4880, 0.2140, 0.9760), // أ
  0x0624: GlyphInk(-0.0080, 0.2335, 0.4260, 0.9270), // ؤ
  0x0625: GlyphInk(0.0275, 0.2115, 0.2140, 1.0410), // إ
  0x0626: GlyphInk(0.0035, 0.1485, 0.7760, 0.7590), // ئ
  0x0627: GlyphInk(0.0030, 0.3660, 0.1610, 0.7320), // ا
  0x0628: GlyphInk(-0.0090, 0.0950, 0.9420, 0.7000), // ب
  0x0629: GlyphInk(-0.0030, 0.3785, 0.4110, 0.7630), // ة
  0x062A: GlyphInk(-0.0090, 0.2780, 0.9420, 0.5980), // ت
  0x062B: GlyphInk(-0.0090, 0.3375, 0.9420, 0.7170), // ث
  0x062C: GlyphInk(-0.0075, 0.0530, 0.6400, 0.8940), // ج
  0x062D: GlyphInk(-0.0075, 0.0530, 0.6400, 0.8940), // ح
  0x062E: GlyphInk(-0.0075, 0.1735, 0.6400, 1.1350), // خ
  0x062F: GlyphInk(-0.0020, 0.2555, 0.4430, 0.5230), // د
  0x0630: GlyphInk(-0.0020, 0.3675, 0.4430, 0.7470), // ذ
  0x0631: GlyphInk(-0.0475, 0.0765, 0.3840, 0.6130), // ر
  0x0632: GlyphInk(-0.0475, 0.2015, 0.3840, 0.8630), // ز
  0x0633: GlyphInk(-0.0120, 0.1200, 1.2940, 0.7040), // س
  0x0634: GlyphInk(-0.0120, 0.2540, 1.2940, 0.9720), // ش
  0x0635: GlyphInk(-0.0065, 0.1045, 1.3570, 0.6710), // ص
  0x0636: GlyphInk(-0.0065, 0.2235, 1.3570, 0.9090), // ض
  0x0637: GlyphInk(-0.0095, 0.3595, 0.7850, 0.7450), // ط
  0x0638: GlyphInk(-0.0095, 0.3595, 0.7850, 0.7450), // ظ
  0x0639: GlyphInk(0.0455, 0.0820, 0.6290, 0.9520), // ع
  0x063A: GlyphInk(0.0455, 0.2025, 0.6290, 1.1930), // غ
  0x0641: GlyphInk(-0.0035, 0.4000, 0.9530, 0.8420), // ف
  0x0642: GlyphInk(-0.0065, 0.2485, 0.7670, 0.8730), // ق
  0x0643: GlyphInk(-0.0095, 0.3555, 0.8481, 0.7530), // ك
  0x0644: GlyphInk(-0.0138, 0.2505, 0.6615, 0.9630), // ل
  0x0645: GlyphInk(-0.0100, 0.0255, 0.4980, 0.8370), // م
  0x0646: GlyphInk(-0.0120, 0.1625, 0.6650, 0.7870), // ن
  0x0647: GlyphInk(-0.0150, 0.2744, 0.7230, 0.5651), // ه
  0x0648: GlyphInk(-0.0080, 0.0865, 0.4260, 0.6330), // و
  0x0649: GlyphInk(0.0035, 0.1230, 0.7760, 0.7080), // ى
  0x064A: GlyphInk(0.0035, 0.0070, 0.7760, 0.9400), // ي
  0x0671: GlyphInk(-0.0280, 0.4760, 0.3090, 0.9520), // ٱ
  0x067E: GlyphInk(-0.0090, 0.0435, 0.9420, 0.8030), // پ
  0x0686: GlyphInk(0.0025, 0.0530, 0.6600, 0.8940), // چ
  0x0698: GlyphInk(-0.0325, 0.2565, 0.4140, 0.9730), // ژ
  0x06A9: GlyphInk(0.0200, 0.3465, 0.8850, 0.7350), // ک
  0x06AF: GlyphInk(0.0200, 0.4235, 0.8850, 0.8890), // گ
  0x06CC: GlyphInk(0.0035, 0.1230, 0.7760, 0.7080), // ی
};

/// The measurements for a single letter, or null (Latin letters, other scripts, empty or longer text).
GlyphInk? glyphInkFor(String letter) {
  final runes = letter.runes.toList();
  return runes.length == 1 ? kBadgeGlyphs[runes.first] : null;
}

/// Font size for the letter in a badge of the given diameter: the ink is fitted into a box of 52% x 46%
/// of the circle (wide letters get wider room), which leaves clear padding all round, and the size stays
/// between 30% and 62% of the diameter. A letter without measurements gets 45%.
double badgeFontSize(double diameter, GlyphInk? ink) {
  if (ink == null) return diameter * 0.45;
  final fit = math.min(diameter * 0.52 / ink.w, diameter * 0.46 / ink.h);
  return fit.clamp(diameter * 0.30, diameter * 0.62).toDouble();
}

/// Where to paint the letter's text box so that its ink is centred in the circle.
/// [boxWidth] and [boxHeight] are the laid-out text size, [baseline] is the distance from the top of the
/// box to the baseline. A letter without measurements is centred by its text box.
({double x, double y}) badgeTextOrigin({
  required double diameter,
  required double fontSize,
  required double boxWidth,
  required double boxHeight,
  required double baseline,
  GlyphInk? ink,
}) {
  final r = diameter / 2;
  if (ink == null) return (x: r - boxWidth / 2, y: r - boxHeight / 2);
  return (x: r - boxWidth / 2 - ink.cx * fontSize, y: r + ink.cy * fontSize - baseline);
}
