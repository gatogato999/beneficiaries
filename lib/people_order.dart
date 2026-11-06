import 'models.dart';

/// Display order: pinned records first, then the rest. The order inside each group is kept.
List<Person> orderPeople(Iterable<Person> people) {
  final all = people.toList();
  return [...all.where((p) => p.pinned), ...all.where((p) => !p.pinned)];
}
