import 'package:beneficiaries/models.dart';
import 'package:beneficiaries/people_order.dart';
import 'package:flutter_test/flutter_test.dart';

Person p(String name, {bool pinned = false}) =>
    Person(name, name, [Account('bankak', '1234567')], pinned: pinned);

List<String> names(List<Person> ps) => ps.map((x) => x.name).toList();

void main() {
  test('pinned records come first, the order inside each group is kept', () {
    final out = orderPeople([p('a'), p('b', pinned: true), p('c'), p('d', pinned: true)]);
    expect(names(out), ['b', 'd', 'a', 'c']);
  });

  test('nothing pinned keeps the order', () {
    expect(names(orderPeople([p('a'), p('b'), p('c')])), ['a', 'b', 'c']);
  });

  test('everything pinned keeps the order', () {
    expect(names(orderPeople([p('a', pinned: true), p('b', pinned: true)])), ['a', 'b']);
  });

  test('an empty list stays empty and the input is not modified', () {
    expect(orderPeople([]), isEmpty);
    final input = [p('a'), p('b', pinned: true)];
    orderPeople(input);
    expect(names(input), ['a', 'b']);
  });
}
