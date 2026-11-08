import 'package:beneficiaries/models.dart';
import 'package:beneficiaries/people_filter.dart';
import 'package:flutter_test/flutter_test.dart';

Person person(String name, List<Account> accounts) => Person(name, name, accounts);

void main() {
  final ahmed = person('أحمد', [Account('bankak', '1234567')]);
  final sara = person('سارة', [Account('okash', '7654321'), Account('fawry', '12345678')]);

  group('personMatches', () {
    test('an empty or blank query matches everyone', () {
      expect(personMatches(ahmed, ''), isTrue);
      expect(personMatches(ahmed, '   '), isTrue);
    });

    test('names match across alef and hamza spellings', () {
      expect(personMatches(ahmed, 'احمد'), isTrue);
      expect(personMatches(ahmed, 'أحم'), isTrue);
      expect(personMatches(ahmed, 'سارة'), isFalse);
    });

    test('a number query finds the account', () {
      expect(personMatches(ahmed, '1234567'), isTrue);
      expect(personMatches(sara, '7654'), isTrue);
      expect(personMatches(sara, '9999'), isFalse);
    });

    test('Arabic-Indic digits and spaces in a number query work', () {
      expect(personMatches(ahmed, '\u0661\u0662\u0663\u0664'), isTrue);
      expect(personMatches(ahmed, '123 45'), isTrue);
    });

    test('digits inside a text query do not turn it into a number search', () {
      expect(personMatches(ahmed, 'xyz1234'), isFalse);
      expect(personMatches(sara, 'سارة9'), isFalse);
    });

    test('the bank name finds the people who have an account there', () {
      expect(personMatches(ahmed, 'بنكك'), isTrue);
      expect(personMatches(sara, 'بنكك'), isFalse);
      expect(personMatches(sara, 'اوكاش'), isTrue);
    });
  });

  group('bank filter', () {
    test('no filter keeps everyone', () {
      expect(hasBank(ahmed, null), isTrue);
    });
    test('a filter keeps the people with an account at that bank, even if it is not the first', () {
      expect(hasBank(sara, 'fawry'), isTrue);
      expect(hasBank(sara, 'okash'), isTrue);
      expect(hasBank(sara, 'bankak'), isFalse);
    });
    test('banksInUse lists each bank once', () {
      expect(banksInUse([ahmed, sara, person('x', [Account('bankak', '1111111')])]), equals({'bankak', 'okash', 'fawry'}));
      expect(banksInUse([]), isEmpty);
    });
  });
}
