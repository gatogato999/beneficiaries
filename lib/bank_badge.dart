import 'package:flutter/material.dart';

import 'badge_glyphs.dart';
import 'bank_style.dart';

/// Round badge with the bank's colour and first letter. Decorative: the bank's name is always next to it.
///
/// The letter is drawn with a bundled font and placed by its measured ink box, so it is centred and sized
/// the same on every phone whatever the system font or font scale.
class BankBadge extends StatelessWidget {
  final String bankId;
  final String name;
  final double size;
  const BankBadge({super.key, required this.bankId, required this.name, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _BadgePainter(bankStyle(bankId, name))),
      ),
    );
  }
}

class _BadgePainter extends CustomPainter {
  final BankStyle style;
  _BadgePainter(this.style);

  @override
  void paint(Canvas canvas, Size size) {
    final d = size.width;
    final r = d / 2;
    final letterColor = Color(style.letterArgb);
    canvas.drawCircle(Offset(r, r), r, Paint()..color = Color(style.argb));
    canvas.drawCircle(
      Offset(r, r),
      r - 0.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = letterColor.withValues(alpha: .35), // keeps the badge visible in dark mode
    );

    final ink = glyphInkFor(style.letter);
    final fontSize = badgeFontSize(d, ink);
    // A TextPainter ignores the system font scale, so the letter always fits the circle.
    final tp = TextPainter(
      text: TextSpan(
        text: style.letter,
        style: TextStyle(
          fontFamily: ink != null ? 'BadgeLetters' : null,
          fontWeight: FontWeight.w700,
          fontSize: fontSize,
          color: letterColor,
        ),
      ),
      textDirection: TextDirection.rtl,
    )..layout();
    final o = badgeTextOrigin(
      diameter: d,
      fontSize: fontSize,
      boxWidth: tp.width,
      boxHeight: tp.height,
      baseline: tp.computeDistanceToActualBaseline(TextBaseline.alphabetic),
      ink: ink,
    );
    tp.paint(canvas, Offset(o.x, o.y));
    tp.dispose();
  }

  @override
  bool shouldRepaint(_BadgePainter old) =>
      old.style.argb != style.argb ||
      old.style.letterArgb != style.letterArgb ||
      old.style.letter != style.letter;
}
