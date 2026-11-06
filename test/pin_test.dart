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

  test('pinning is saved and survives a restart; unpinning too', () async {
    final s = await openStore(dir);
    final p = person('أحمد', [Account('bankak', '1234567')]);
    await s.upsert(p);
    await s.togglePin(p.id);
    expect((await openStore(dir)).byId(p.id)!.pinned, isTrue);
    await s.togglePin(p.id);
    expect((await openStore(dir)).byId(p.id)!.pinned, isFalse);
  });

  test('togglePin with an unknown id does nothing', () async {
    final s = await openStore(dir);
    await s.togglePin('nope');
    expect(s.people, isEmpty);
  });

  test('exported files carry no pin and no id', () async {
    final s = await openStore(dir);
    final p = person('أحمد', [Account('bankak', '1234567')]);
    await s.upsert(p);
    await s.togglePin(p.id);
    final exported = jsonDecode(Store.exportJson([s.byId(p.id)!])) as Map<String, dynamic>;
    final first = (exported['people'] as List).first as Map<String, dynamic>;
    expect(first.containsKey('pinned'), isFalse);
    expect(first.containsKey('id'), isFalse);
  });

  test('an imported file cannot pin records', () {
    final text = jsonEncode({
      'app': 'sijil',
      'version': 1,
      'people': [
        {'name': 'سارة', 'pinned': true, 'accounts': [{'bank': 'okash', 'number': '7654321'}]},
      ],
    });
    expect(Store.parseExport(text)!.first.pinned, isFalse);
  });

  test('merging an import into a pinned record keeps it pinned', () async {
    final s = await openStore(dir);
    final p = person('منى', [Account('bankak', '1111111')]);
    await s.upsert(p);
    await s.togglePin(p.id);
    await s.importPeople(
      [person('منى', [Account('bankak', '1111111'), Account('okash', '4444444')])],
      (inc, loc) async => (Resolution.merge, false),
    );
    expect(s.byId(p.id)!.pinned, isTrue);
    expect(s.byId(p.id)!.accounts.length, 2);
  });

  test('a pinned record is still pinned after delete and undo', () async {
    final s = await openStore(dir);
    final p = person('أحمد', [Account('bankak', '1234567')]);
    await s.upsert(p);
    await s.togglePin(p.id);
    await s.delete(p.id);
    await s.restore(p);
    expect((await openStore(dir)).byId(p.id)!.pinned, isTrue);
  });

  test('saving an edited copy of a pinned record keeps the pin when it is carried over', () async {
    final s = await openStore(dir);
    final p = person('أحمد', [Account('bankak', '1234567')]);
    await s.upsert(p);
    await s.togglePin(p.id);
    // what the editor does when you change the name
    await s.upsert(Person(p.id, 'أحمد علي', p.accounts, pinned: p.pinned));
    final again = await openStore(dir);
    expect(again.byId(p.id)!.name, 'أحمد علي');
    expect(again.byId(p.id)!.pinned, isTrue);
  });

  test('a file from before pins existed loads with nothing pinned', () async {
    File('${dir.path}/data.json').writeAsStringSync(jsonEncode({
      'version': 2,
      'people': [
        {'id': 'p1', 'name': 'أحمد', 'accounts': [{'bank': 'bankak', 'number': '1234567'}]},
      ],
    }));
    final s = await openStore(dir);
    expect(s.people.first.pinned, isFalse);
  });
}
