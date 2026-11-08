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

  group('recordUse', () {
    test('counts, stamps the time, and survives a restart', () async {
      final s = await openStore(dir);
      final p = person('أحمد', [Account('bankak', '1234567')]);
      await s.upsert(p);
      await s.recordUse(p.id, now: DateTime.fromMillisecondsSinceEpoch(5000));
      await s.recordUse(p.id, now: DateTime.fromMillisecondsSinceEpoch(9000));
      final again = (await openStore(dir)).byId(p.id)!;
      expect(again.useCount, 2);
      expect(again.lastUsed, 9000);
    });

    test('is silent: listeners are not told and the revision does not change', () async {
      final s = await openStore(dir);
      final p = person('أحمد', [Account('bankak', '1234567')]);
      await s.upsert(p);
      var calls = 0;
      s.addListener(() => calls++);
      final rev = s.revision;
      await s.recordUse(p.id);
      expect(calls, 0);
      expect(s.revision, rev);
      await s.togglePin(p.id);
      expect(calls, 1);
      expect(s.revision, rev + 1);
    });

    test('an unknown id does nothing', () async {
      final s = await openStore(dir);
      await s.recordUse('nope');
      expect(s.people, isEmpty);
    });

    test('usage is not exported and an imported file cannot set it', () async {
      final s = await openStore(dir);
      final p = person('أحمد', [Account('bankak', '1234567')]);
      await s.upsert(p);
      await s.recordUse(p.id);
      final exported = jsonDecode(Store.exportJson([s.byId(p.id)!])) as Map<String, dynamic>;
      final first = (exported['people'] as List).first as Map<String, dynamic>;
      expect(first.containsKey('uses'), isFalse);
      expect(first.containsKey('lastUsed'), isFalse);

      final text = jsonEncode({
        'app': 'sijil',
        'version': 1,
        'people': [
          {'name': 'سارة', 'uses': 50, 'lastUsed': 123456, 'accounts': [{'bank': 'okash', 'number': '7654321'}]},
        ],
      });
      final imported = Store.parseExport(text)!.first;
      expect(imported.useCount, 0);
      expect(imported.lastUsed, 0);
    });

    test('merging an import keeps the local usage; undo keeps it too', () async {
      final s = await openStore(dir);
      final p = person('منى', [Account('bankak', '1111111')]);
      await s.upsert(p);
      await s.recordUse(p.id);
      await s.importPeople(
        [person('منى', [Account('bankak', '1111111'), Account('okash', '4444444')])],
        (inc, loc) async => (Resolution.merge, false),
      );
      expect(s.byId(p.id)!.useCount, 1);
      await s.delete(p.id);
      await s.restore(p);
      expect((await openStore(dir)).byId(p.id)!.useCount, 1);
    });
  });

  group('sort mode preference', () {
    test('is saved and reloaded; setting the same value again changes nothing', () async {
      final s = await openStore(dir);
      expect(s.sortModeName, isNull);
      await s.setSortMode('mostUsed');
      expect((await openStore(dir)).sortModeName, 'mostUsed');
      final rev = s.revision;
      await s.setSortMode('mostUsed');
      expect(s.revision, rev);
    });
  });

  group('personal fields in the model', () {
    test('they round-trip through toJson and fromJson', () {
      final p = Person('1', 'أ', [], useCount: 3, lastUsed: 42);
      final back = Person.fromJson(p.toJson());
      expect(back.useCount, 3);
      expect(back.lastUsed, 42);
    });

    test('the shared form leaves them out', () {
      final j = Person('1', 'أ', [], useCount: 3, lastUsed: 42).toJson(shared: true);
      expect(j.containsKey('uses'), isFalse);
      expect(j.containsKey('lastUsed'), isFalse);
    });

    test('negative or junk values load as zero, old records have no usage', () {
      final j = {'id': '1', 'name': 'x', 'accounts': [], 'uses': -5, 'lastUsed': 'soon'};
      expect(Person.fromJson(j).useCount, 0);
      expect(Person.fromJson(j).lastUsed, 0);
      expect(Person.fromJson({'id': '1', 'name': 'x', 'accounts': []}).useCount, 0);
    });

    test('copyWith keeps the id, the pin and the usage, and changes only what is asked', () {
      final p = Person('7', 'أحمد', [Account('bankak', '1234567')], pinned: true, useCount: 4, lastUsed: 88);
      final q = p.copyWith(name: 'أحمد علي');
      expect(q.id, '7');
      expect(q.name, 'أحمد علي');
      expect(q.accounts.length, 1);
      expect(q.pinned, isTrue);
      expect(q.useCount, 4);
      expect(q.lastUsed, 88);
      expect(p.copyWith(accounts: []).name, 'أحمد');
    });
  });
}
