import 'package:beneficiaries/banks.dart';
import 'package:flutter_test/flutter_test.dart';

Bank bank(String id) => bankById(id)!;

void main() {
  test('every bank gives a 14-digit BBAN', () {
    for (final b in banks) {
      final v = b.bban('1234');
      expect(v, isNotNull, reason: b.id);
      expect(v!.length, 14, reason: b.id);
    }
  });

  test('bankak example from aywa.sd', () {
    expect(bank('bankak').bban('1234567'), '04012345670001');
  });

  test('aman plus: normal 7-digit account and shorter ones (VERIFY with real BBANs)', () {
    expect(bank('amanplus').bban('1234567'), '14012345670001');
    expect(bank('amanplus').bban('1234'), '14000012340001');
  });

  test('leading zeros do not change the result', () {
    expect(bank('amanplus').bban('0001234'), bank('amanplus').bban('1234'));
  });

  test('too long or empty input gives null', () {
    expect(bank('amanplus').bban('12345678'), isNull);
    expect(bank('bankak').bban(''), isNull);
  });
}
