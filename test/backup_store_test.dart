import 'dart:convert';
import 'dart:io';

import 'package:beneficiaries/models.dart';
import 'package:beneficiaries/store.dart';
import 'package:flutter_test/flutter_test.dart';

Person person(String name, List<Account> accounts) => Person(newId(), name, accounts);

void main() {
  late Directory dir;
  late DateTime now;
  setUp(() {
    dir = Directory.systemTemp.createTempSync('sijil_test');
    now = DateTime(2026, 3, 1, 9);
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Future<Store> openStore() async {
    final s = Store(dir, () => now);
    await s.load();
    return s;
  }

  void later(int days) => now = now.add(Duration(days: days));

  test('an empty store never reminds, and the first record starts the clock', () async {
    final s = await openStore();
    later(60);
    expect(s.backupDue(), isFalse);
    await s.upsert(person('أحمد', [Account('bankak', '1234567')]));
    expect(s.backupDue(), isFalse);
    later(13);
    expect(s.backupDue(), isFalse);
    later(1);
    expect(s.backupDue(), isTrue);
    expect(s.daysSinceUnsavedChange(), 14);
  });

  test('records from before the reminder existed start their 14 days at the first launch and keep them', () async {
    File('${dir.path}/data.json').writeAsStringSync(jsonEncode({
      'version': 2,
      'people': [
        {'id': 'p1', 'name': 'أحمد', 'accounts': [{'bank': 'bankak', 'number': '1234567'}]},
      ],
    }));
    var s = await openStore();
    expect(s.backupDue(), isFalse);
    later(10);
    s = await openStore(); // restarting must not restart the clock
    expect(s.daysSinceUnsavedChange(), 10);
    later(4);
    s = await openStore();
    expect(s.backupDue(), isTrue);
  });

  test('later changes do not move the start of the clock', () async {
    final s = await openStore();
    await s.upsert(person('أحمد', [Account('bankak', '1234567')]));
    later(10);
    await s.upsert(person('سارة', [Account('okash', '7654321')]));
    later(4);
    expect(s.backupDue(), isTrue);
    expect(s.daysSinceUnsavedChange(), 14);
  });

  test('a full backup clears the reminder; the next change starts a new clock', () async {
    final s = await openStore();
    await s.upsert(person('أحمد', [Account('bankak', '1234567')]));
    later(20);
    expect(s.backupDue(), isTrue);
    await s.markExported();
    expect(s.backupDue(), isFalse);
    expect(s.lastExport, now);
    later(30);
    expect(s.backupDue(), isFalse); // nothing changed since the backup
    final p = s.people.first;
    await s.upsert(p.copyWith(name: 'أحمد علي'));
    later(14);
    expect(s.backupDue(), isTrue);
    expect(s.daysSinceUnsavedChange(), 14);
  });

  test('pins, usage, sort choice and last bank are not changes', () async {
    final s = await openStore();
    final p = person('أحمد', [Account('bankak', '1234567')]);
    await s.upsert(p);
    await s.markExported();
    later(30);
    await s.togglePin(p.id);
    await s.recordUse(p.id);
    await s.setSortMode('mostUsed');
    await s.setLastBank('okash');
    expect(s.backupDue(), isFalse);
    expect(s.daysSinceUnsavedChange(), 0);
  });

  test('delete, restore and edit are changes', () async {
    final s = await openStore();
    final p = person('أحمد', [Account('bankak', '1234567')]);
    await s.upsert(p);
    await s.markExported();
    await s.delete(p.id);
    later(14);
    expect(s.daysSinceUnsavedChange(), 14);
    await s.markExported();
    await s.restore(p);
    later(14);
    expect(s.backupDue(), isTrue);
  });

  test('deleting every record switches the reminder off', () async {
    final s = await openStore();
    final p = person('أحمد', [Account('bankak', '1234567')]);
    await s.upsert(p);
    later(20);
    await s.delete(p.id);
    expect(s.backupDue(), isFalse);
  });

  test('an import that changes nothing is not a change; one that adds is', () async {
    final s = await openStore();
    await s.upsert(person('سارة', [Account('bankak', '1111111')]));
    await s.markExported();
    await s.importPeople([person('سارة', [Account('bankak', '1111111')])], (i, l) async => (Resolution.skip, false));
    later(14);
    expect(s.backupDue(), isFalse);
    await s.importPeople([person('علي', [Account('okash', '2222222')])], (i, l) async => (Resolution.skip, false));
    later(14);
    expect(s.backupDue(), isTrue);
  });

  test('pending conflicts: skipping is not a change, merging or keeping separate is', () async {
    final s = await openStore();
    final local = person('منى', [Account('bankak', '1111111')]);
    await s.upsert(local);
    await s.importPeople(
      [person('منى', [Account('bankak', '1111111'), Account('okash', '4444444')])],
      (i, l) async => (Resolution.later, false),
    );
    await s.markExported();
    await s.resolvePending(s.pending.first, Resolution.skip);
    later(14);
    expect(s.backupDue(), isFalse);

    await s.importPeople(
      [person('منى', [Account('bankak', '1111111'), Account('fawry', '55555555')])],
      (i, l) async => (Resolution.later, false),
    );
    await s.markExported();
    await s.resolvePending(s.pending.first, Resolution.merge);
    later(14);
    expect(s.backupDue(), isTrue);
  });

  test('"later" hides the banner for 7 days, then it returns', () async {
    final s = await openStore();
    await s.upsert(person('أحمد', [Account('bankak', '1234567')]));
    later(20);
    expect(s.backupDue(), isTrue);
    await s.snoozeBackupReminder();
    expect(s.backupDue(), isFalse);
    later(6);
    expect(s.backupDue(), isFalse);
    later(1);
    expect(s.backupDue(), isTrue);
  });

  test('everything survives a restart: last backup, clock and snooze', () async {
    var s = await openStore();
    await s.upsert(person('أحمد', [Account('bankak', '1234567')]));
    await s.markExported();
    expect((await openStore()).lastExport, now);
    await s.upsert(person('سارة', [Account('okash', '7654321')]));
    later(20);
    await s.snoozeBackupReminder();
    s = await openStore();
    expect(s.backupDue(), isFalse);
    later(7);
    expect(s.backupDue(), isTrue);
  });
}
