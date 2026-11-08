import 'package:beneficiaries/models.dart';
import 'package:beneficiaries/sorting.dart';
import 'package:flutter_test/flutter_test.dart';

Person p(String id, String name, {bool pinned = false, int uses = 0}) =>
    Person(id, name, [Account('bankak', '1234567')], pinned: pinned, useCount: uses);

List<String> ids(List<Person> ps) => ps.map((x) => x.id).toList();

void main() {
  group('alphabetical', () {
    test('uses the spelling-tolerant name so alef variants sit together', () {
      final out = sortPeople(
        [p('1', 'بلال'), p('2', 'أحمد'), p('3', 'احمد خالد'), p('4', 'جمال')],
        SortMode.alphabetical,
        {},
      );
      expect(ids(out), ['2', '3', '1', '4']);
    });

    test('equal names fall back to the id so the order is stable', () {
      final out = sortPeople([p('b', 'سارة'), p('a', 'سارة')], SortMode.alphabetical, {});
      expect(ids(out), ['a', 'b']);
    });
  });

  group('recent', () {
    final usage = {'1': const Usage(1, 100), '2': const Usage(5, 300), '3': const Usage(0, 0)};
    test('newest copy first, never used last (by name)', () {
      final out = sortPeople([p('3', 'ب'), p('1', 'ج'), p('2', 'أ'), p('4', 'ا')], SortMode.recent, usage);
      expect(ids(out), ['2', '1', '4', '3']);
    });
  });

  group('most used', () {
    test('highest count first, then newest, then name', () {
      final usage = {
        '1': const Usage(3, 100),
        '2': const Usage(3, 200),
        '3': const Usage(9, 50),
        '4': const Usage(3, 200),
      };
      final out = sortPeople([p('1', 'د'), p('2', 'ج'), p('3', 'هـ'), p('4', 'ب')], SortMode.mostUsed, usage);
      expect(ids(out), ['3', '4', '2', '1']);
    });
  });

  test('pinned records are first in every mode', () {
    final usage = {'1': const Usage(9, 900), '2': const Usage(0, 0)};
    for (final mode in SortMode.values) {
      final out = sortPeople([p('1', 'أ'), p('2', 'ب', pinned: true)], mode, usage);
      expect(ids(out), ['2', '1'], reason: mode.name);
    }
  });

  test('sorting works from the snapshot it is given, not from the live counters', () {
    final live = p('1', 'أ', uses: 99);
    final other = p('2', 'ب');
    final out = sortPeople([live, other], SortMode.mostUsed, {'2': const Usage(5, 1)});
    expect(ids(out), ['2', '1']);
  });

  test('usageSnapshot copies the counters', () {
    final a = Person('1', 'أ', [], useCount: 4, lastUsed: 77);
    final snap = usageSnapshot([a]);
    a.useCount = 10;
    expect(snap['1']!.uses, 4);
    expect(snap['1']!.last, 77);
  });

  test('the input list is not modified', () {
    final input = [p('2', 'ب'), p('1', 'أ')];
    sortPeople(input, SortMode.alphabetical, {});
    expect(ids(input), ['2', '1']);
  });

  test('sortModeFromName reads saved values and falls back to alphabetical', () {
    expect(sortModeFromName('mostUsed'), SortMode.mostUsed);
    expect(sortModeFromName('recent'), SortMode.recent);
    expect(sortModeFromName(null), SortMode.alphabetical);
    expect(sortModeFromName('garbage'), SortMode.alphabetical);
  });
}
