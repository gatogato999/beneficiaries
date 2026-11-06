import 'dart:convert';
import 'dart:io';

import 'package:beneficiaries/schema.dart';
import 'package:beneficiaries/store.dart';
import 'package:flutter_test/flutter_test.dart';

Future<Store> openStore(Directory dir) async {
  final s = Store(dir);
  await s.load();
  return s;
}

Map<String, dynamic> readData(Directory dir) =>
    jsonDecode(File('${dir.path}/data.json').readAsStringSync()) as Map<String, dynamic>;

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('sijil_test'));
  tearDown(() => dir.deleteSync(recursive: true));

  test('the last bank is empty at first, then saved and reloaded', () async {
    final s = await openStore(dir);
    expect(s.lastBank, isNull);
    await s.setLastBank('okash');
    expect(s.lastBank, 'okash');
    expect((await openStore(dir)).lastBank, 'okash');
    expect(readData(dir)['version'], kSchemaVersion);
  });

  test('a v1 file is migrated: data kept, backup made, new version saved on the next write', () async {
    final original = jsonEncode({
      'version': 1,
      'people': [
        {'id': 'p1', 'name': 'أحمد', 'accounts': [{'bank': 'bankak', 'number': '1234567'}]},
      ],
      'pending': [],
    });
    File('${dir.path}/data.json').writeAsStringSync(original);
    final s = await openStore(dir);
    expect(s.people.length, 1);
    expect(s.lastBank, isNull);
    expect(File('${dir.path}/data.json.premigrate.bak').readAsStringSync(), original);
    await s.setLastBank('okash');
    final saved = readData(dir);
    expect(saved['version'], 2);
    expect((saved['prefs'] as Map)['lastBank'], 'okash');
    expect((saved['people'] as List).length, 1);
  });

  test('a file from a newer app is backed up before this version can overwrite it', () async {
    final original = jsonEncode({
      'version': 99,
      'people': [
        {'id': 'p1', 'name': 'سارة', 'accounts': [{'bank': 'okash', 'number': '7654321'}]},
      ],
      'future': true,
    });
    File('${dir.path}/data.json').writeAsStringSync(original);
    final s = await openStore(dir);
    expect(s.people.length, 1);
    expect(File('${dir.path}/data.json.newer.bak').readAsStringSync(), original);
  });

  test('a corrupt file is kept as data.json.bak and the app starts empty', () async {
    File('${dir.path}/data.json').writeAsStringSync('not json {');
    final s = await openStore(dir);
    expect(s.people, isEmpty);
    expect(File('${dir.path}/data.json.bak').readAsStringSync(), 'not json {');
  });

  test('a file with a broken record is not half loaded', () async {
    File('${dir.path}/data.json').writeAsStringSync(jsonEncode({
      'version': 2,
      'people': [
        {'id': 'p1', 'name': 'أحمد', 'accounts': []},
        'this is not a record',
      ],
    }));
    final s = await openStore(dir);
    expect(s.people, isEmpty);
    expect(File('${dir.path}/data.json.bak').existsSync(), isTrue);
  });
}
