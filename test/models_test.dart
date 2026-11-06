import 'package:beneficiaries/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a pinned record keeps its pin through toJson and fromJson', () {
    final p = Person('1', 'أحمد', [Account('bankak', '1234567')], pinned: true);
    final back = Person.fromJson(p.toJson());
    expect(back.pinned, isTrue);
    expect(back.id, '1');
  });

  test('records are not pinned by default and an unpinned record writes no pin', () {
    final p = Person('1', 'أحمد', [Account('bankak', '1234567')]);
    expect(p.pinned, isFalse);
    expect(p.toJson().containsKey('pinned'), isFalse);
  });

  test('the shared form has no id and no pin', () {
    final p = Person('1', 'أحمد', [Account('bankak', '1234567')], pinned: true);
    final j = p.toJson(shared: true);
    expect(j.containsKey('id'), isFalse);
    expect(j.containsKey('pinned'), isFalse);
    expect(j['name'], 'أحمد');
  });

  test('only a real true counts as pinned', () {
    for (final v in ['yes', 1, 'true', null]) {
      final j = {'id': '1', 'name': 'x', 'accounts': [], 'pinned': v};
      expect(Person.fromJson(j).pinned, isFalse);
    }
    expect(Person.fromJson({'id': '1', 'name': 'x', 'accounts': [], 'pinned': true}).pinned, isTrue);
  });

  test('an old record without the field loads unpinned', () {
    expect(Person.fromJson({'id': '1', 'name': 'x', 'accounts': []}).pinned, isFalse);
  });
}
