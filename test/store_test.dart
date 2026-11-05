import 'dart:convert';
import 'dart:io';

import 'package:beneficiaries/models.dart';
import 'package:beneficiaries/store.dart';
import 'package:flutter_test/flutter_test.dart';

Future<Store> openStore(Directory dir) async {
  final s = Store(dir);
  await s.load();
  return s;
}

Person person(String name, List<Account> accounts) => Person(newId(), name, accounts);

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('sijil_test'));
  tearDown(() => dir.deleteSync(recursive: true));

  group('delete and undo', () {
    test('restore brings the same record back', () async {
      final s = await openStore(dir);
      final p = person('أحمد', [Account('bankak', '1234567')]);
      await s.upsert(p);
      await s.delete(p.id);
      expect(s.people, isEmpty);
      await s.restore(p);
      expect(s.people.length, 1);
      expect(s.people.first.id, p.id);
      expect(s.people.first.accounts.first.number, '1234567');
    });

    test('restore twice does not duplicate', () async {
      final s = await openStore(dir);
      final p = person('أحمد', [Account('bankak', '1234567')]);
      await s.upsert(p);
      await s.delete(p.id);
      await s.restore(p);
      await s.restore(p);
      expect(s.people.length, 1);
    });

    test('delete and restore are both saved to disk', () async {
      final s = await openStore(dir);
      final p = person('أحمد', [Account('bankak', '1234567')]);
      await s.upsert(p);
      await s.delete(p.id);
      expect((await openStore(dir)).people, isEmpty);
      await s.restore(p);
      final again = await openStore(dir);
      expect(again.people.length, 1);
      expect(again.people.first.id, p.id);
    });

    test('a restored record returns to its sorted place', () async {
      final s = await openStore(dir);
      final a = person('أحمد', [Account('bankak', '1111111')]);
      final b = person('بلال', [Account('bankak', '2222222')]);
      final c = person('جمال', [Account('bankak', '3333333')]);
      for (final p in [c, a, b]) {
        await s.upsert(p);
      }
      await s.delete(b.id);
      await s.restore(b);
      expect(s.people.map((p) => p.name).toList(), ['أحمد', 'بلال', 'جمال']);
    });

    test('a pending conflict merges again after the original is restored', () async {
      final s = await openStore(dir);
      final local = person('منى', [Account('bankak', '1111111')]);
      await s.upsert(local);
      await s.importPeople(
        [person('منى', [Account('bankak', '1111111'), Account('okash', '4444444')])],
        (inc, loc) async => (Resolution.later, false),
      );
      expect(s.pending.length, 1);
      await s.delete(local.id);
      await s.restore(local);
      await s.resolvePending(s.pending.first, Resolution.merge);
      expect(s.pending, isEmpty);
      expect(s.byId(local.id)!.accounts.length, 2);
    });

    test('a pending merge becomes a separate record if the original stays deleted', () async {
      final s = await openStore(dir);
      final local = person('منى', [Account('bankak', '1111111')]);
      await s.upsert(local);
      await s.importPeople(
        [person('منى', [Account('bankak', '1111111'), Account('okash', '4444444')])],
        (inc, loc) async => (Resolution.later, false),
      );
      await s.delete(local.id);
      await s.resolvePending(s.pending.first, Resolution.merge);
      expect(s.people.length, 1);
      expect(s.people.first.accounts.length, 2);
    });
  });

  group('import rules', () {
    test('new is added, identical is skipped, extra account asks', () async {
      final s = await openStore(dir);
      await s.upsert(person('سارة', [Account('bankak', '1111111')]));
      var asked = 0;
      final r = await s.importPeople([
        person('علي', [Account('okash', '2222222')]),
        person('سارة', [Account('bankak', '1111111')]),
        person('سارة', [Account('bankak', '1111111'), Account('fawry', '33333333')]),
      ], (inc, loc) async {
        asked++;
        return (Resolution.merge, false);
      });
      expect(r.added, 1);
      expect(r.skipped, 1);
      expect(r.merged, 1);
      expect(asked, 1);
      expect(s.people.firstWhere((p) => p.name == 'سارة').accounts.length, 2);
    });

    test('the bulk choice is applied to the remaining conflicts without asking again', () async {
      final s = await openStore(dir);
      await s.upsert(person('سارة', [Account('bankak', '1111111')]));
      await s.upsert(person('هدى', [Account('okash', '5555555')]));
      var asked = 0;
      final r = await s.importPeople([
        person('سارة', [Account('bankak', '1111111'), Account('fawry', '33333333')]),
        person('هدى', [Account('okash', '5555555'), Account('bankak', '6666666')]),
      ], (inc, loc) async {
        asked++;
        return (Resolution.separate, true);
      });
      expect(asked, 1);
      expect(r.separate, 2);
      expect(s.people.length, 4);
    });
  });

  group('import file parsing', () {
    test('long names are clamped and junk account numbers are cleaned', () {
      final text = jsonEncode({
        'app': 'sijil',
        'version': 1,
        'people': [
          {
            'name': 'ا' * 300,
            'accounts': [
              {'bank': 'bankak', 'number': '12-34 567'},
              {'bank': 'bankak', 'number': 'abc'},
            ],
          },
        ],
      });
      final out = Store.parseExport(text)!;
      expect(out.length, 1);
      expect(out.first.name.length, 120);
      expect(out.first.accounts.length, 1);
      expect(out.first.accounts.first.number, '1234567');
    });

    test('other files and oversized lists are rejected', () {
      expect(Store.parseExport('not json'), isNull);
      expect(Store.parseExport('{"app":"other","people":[]}'), isNull);
      final many = jsonEncode({
        'app': 'sijil',
        'version': 1,
        'people': List.generate(
          Store.kMaxImport + 1,
          (i) => {
            'name': 'n$i',
            'accounts': [
              {'bank': 'bankak', 'number': '1234567'},
            ],
          },
        ),
      });
      expect(Store.parseExport(many), isNull);
    });
  });
}
