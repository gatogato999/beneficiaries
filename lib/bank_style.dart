import 'dart:math' as math;

/// Look of a bank's round badge: a background colour, the letter, and the letter's colour.
/// No logos, so no trademark questions.
class BankStyle {
  /// Background, 0xFFRRGGBB.
  final int argb;

  /// White or black, whichever is easier to read on the background (contrast of at least 4.5).
  final int letterArgb;
  final String letter;
  const BankStyle(this.argb, this.letterArgb, this.letter);
}

/// One distinct hue (degrees) per built-in bank. A bank that is not listed here (for example a custom
/// bank added later) gets a hue from its id, so it always has the same colour.
const kBankHues = {
  'bankak': 8,
  'okash': 32,
  'fawry': 56,
  'mycashi': 80,
  'mashreq': 104,
  'amanplus': 128,
  'masrafak': 152,
  'french': 176,
  'zirai': 200,
  'salam': 224,
  'baraka': 248,
  'animal': 272,
  'aqari': 296,
  'industry': 320,
  'mal': 344,
};

int _fnv1a(String s) {
  var h = 0x811C9DC5;
  for (final u in s.codeUnits) {
    h ^= u;
    h = (h * 0x01000193) & 0xFFFFFFFF;
  }
  return h;
}

int hueOf(String bankId) => kBankHues[bankId] ?? _fnv1a(bankId) % 360;

int _hslToArgb(double h, double s, double l) {
  final c = (1 - (2 * l - 1).abs()) * s;
  final x = c * (1 - ((h / 60) % 2 - 1).abs());
  final m = l - c / 2;
  double r, g, b;
  if (h < 60) {
    r = c; g = x; b = 0;
  } else if (h < 120) {
    r = x; g = c; b = 0;
  } else if (h < 180) {
    r = 0; g = c; b = x;
  } else if (h < 240) {
    r = 0; g = x; b = c;
  } else if (h < 300) {
    r = x; g = 0; b = c;
  } else {
    r = c; g = 0; b = x;
  }
  int ch(double v) => ((v + m) * 255).round();
  return 0xFF000000 | (ch(r) << 16) | (ch(g) << 8) | ch(b);
}

// Neighbouring hues alternate between three lightness levels, so banks next to each other on the colour
// wheel still look different.
const _levels = [0.35, 0.50, 0.65];

/// The background colour for a hue in degrees (0 to 359).
int colorForHue(int hue) => _hslToArgb(hue.toDouble(), 0.8, _levels[(hue ~/ 24) % 3]);

double _linear(int v) {
  final c = v / 255;
  return c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
}

/// Relative luminance (WCAG) of a 0xFFRRGGBB colour.
double luminanceOf(int argb) =>
    0.2126 * _linear((argb >> 16) & 0xFF) + 0.7152 * _linear((argb >> 8) & 0xFF) + 0.0722 * _linear(argb & 0xFF);

/// WCAG contrast ratio between two colours (1 to 21).
double contrastRatio(int a, int b) {
  final la = luminanceOf(a), lb = luminanceOf(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// White or black, whichever has the higher contrast on [background] (always at least 4.5).
int letterColorFor(int background) =>
    contrastRatio(background, 0xFFFFFFFF) >= contrastRatio(background, 0xFF000000) ? 0xFFFFFFFF : 0xFF000000;

/// First letter of the first meaningful word: the generic word for "bank" and the Arabic "ال" are skipped,
/// so "بنك السلام السوداني" gives "س" and "Bank of Nile" gives "O".
String bankLetter(String name) {
  const generic = {'بنك', 'البنك', 'bank', 'the'};
  final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  final meaningful = words.where((w) => !generic.contains(w.toLowerCase())).toList();
  var w = meaningful.isNotEmpty ? meaningful.first : (words.isNotEmpty ? words.first : '');
  if (w.startsWith('ال') && w.length > 3) w = w.substring(2);
  if (w.isEmpty) return '?';
  return String.fromCharCode(w.runes.first).toUpperCase();
}

BankStyle bankStyle(String bankId, String name) {
  final background = colorForHue(hueOf(bankId));
  return BankStyle(background, letterColorFor(background), bankLetter(name));
}
