import 'banks.dart';
import 'digits.dart';
import 'models.dart';

/// Search of the beneficiaries list: the name (spelling tolerant), an account number
/// (only when the query is made of digits), or the bank name.
bool personMatches(Person p, String query) {
  final q = query.trim();
  if (q.isEmpty) return true;
  final n = normName(q);
  if (normName(p.name).contains(n)) return true;
  final ascii = asciiDigits(q);
  final digitsOnly = RegExp(r'^[\d\s\-.]+$').hasMatch(ascii);
  final digits = ascii.replaceAll(RegExp(r'\D'), '');
  return p.accounts.any((a) =>
      (digitsOnly && digits.isNotEmpty && a.number.contains(digits)) ||
      normName(bankById(a.bankId)?.label ?? '').contains(n));
}

/// True when no bank is chosen (null) or the person has an account at that bank.
bool hasBank(Person p, String? bankId) => bankId == null || p.accounts.any((a) => a.bankId == bankId);

/// Bank ids that appear in at least one saved account (the choices the filter offers).
Set<String> banksInUse(Iterable<Person> people) => {
      for (final p in people)
        for (final a in p.accounts) a.bankId,
    };
