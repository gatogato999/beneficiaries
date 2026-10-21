/// BBAN = prefix + account (left-padded with zeros to [width]) + suffix  -> always 14 digits.
/// Formats follow https://aywa.sd/bban.php
class Bank {
  final String id, name, sub, prefix, suffix;
  final int width;
  const Bank(this.id, this.name, this.sub, this.prefix, this.width, this.suffix);

  String get label => sub.isEmpty ? name : '$name ($sub)';
  String get pattern => '$prefix${'X' * width}$suffix';

  /// Returns null when the input is empty / too long for this bank.
  /// Leading zeros are dropped first, so the "short account number that starts
  /// with 0" and the long form give the same BBAN.
  String? bban(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '').replaceFirst(RegExp(r'^0+'), '');
    if (digits.isEmpty || digits.length > width) return null;
    return '$prefix${digits.padLeft(width, '0')}$suffix';
  }
}

const banks = <Bank>[
  Bank('bankak', 'بنكك', 'بنك الخرطوم', '040', 7, '0001'),
  Bank('okash', 'أوكاش', 'بنك أم درمان الوطني', '24', 7, '00001'),
  Bank('fawry', 'فوري', 'بنك فيصل الإسلامي', '02', 8, '0001'),
  // TODO: not listed on aywa.sd - width 9 is assumed so the total is 14 digits. Verify!
  Bank('mycashi', 'ماي كاشي', 'محفظة', '070', 9, '98'),
  Bank('mashreq', 'مشرق', 'بنك النيل الأزرق', '150000', 8, ''),
  Bank('amanplus', 'أمن بلس', 'البنك الإسلامي السوداني', '14000', 4, '00001'),
  Bank('masrafak', 'مصرفك', 'بنك المزارع التجاري', '222', 11, ''),
  Bank('french', 'البنك الفرنسي السوداني', '', '110', 6, '00001'),
  Bank('zirai', 'الزراعي موبايل', 'البنك الزراعي السوداني', '03', 7, '01001'),
  Bank('salam', 'بنك السلام السوداني', '', '180', 6, '00001'),
  Bank('baraka', 'بنك البركة السوداني', '', '070', 6, '00001'),
  Bank('animal', 'بنك الثروة الحيوانية', '', '090', 6, '00001'),
  Bank('aqari', 'البنك العقاري التجاري', '', '210', 6, '00001'),
  Bank('industry', 'بنك التنمية الصناعية', '', '130', 6, '00001'),
  Bank('mal', 'بنك المال المتحد', '', '170', 6, '00001'),
];

Bank? bankById(String id) {
  for (final b in banks) {
    if (b.id == id) return b;
  }
  return null;
}
