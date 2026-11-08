import 'models.dart';

/// How the beneficiaries list is ordered (pinned records are always first).
enum SortMode { alphabetical, recent, mostUsed }

SortMode sortModeFromName(String? name) {
  for (final m in SortMode.values) {
    if (m.name == name) return m;
  }
  return SortMode.alphabetical;
}

/// Personal usage numbers used for sorting. The list works from a snapshot of these,
/// so it does not move under your finger while you copy numbers.
class Usage {
  final int uses;
  final int last;
  const Usage(this.uses, this.last);
}

Map<String, Usage> usageSnapshot(Iterable<Person> people) =>
    {for (final p in people) p.id: Usage(p.useCount, p.lastUsed)};

/// Pinned first, then by the chosen mode. Ties fall back to the name, then the id.
List<Person> sortPeople(Iterable<Person> people, SortMode mode, Map<String, Usage> usage) {
  int uses(Person p) => usage[p.id]?.uses ?? 0;
  int last(Person p) => usage[p.id]?.last ?? 0;
  int byName(Person a, Person b) {
    final c = normName(a.name).compareTo(normName(b.name));
    return c != 0 ? c : a.id.compareTo(b.id);
  }

  final all = people.toList();
  all.sort((a, b) {
    if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
    switch (mode) {
      case SortMode.alphabetical:
        return byName(a, b);
      case SortMode.recent:
        final c = last(b).compareTo(last(a));
        return c != 0 ? c : byName(a, b);
      case SortMode.mostUsed:
        final c = uses(b).compareTo(uses(a));
        if (c != 0) return c;
        final d = last(b).compareTo(last(a));
        return d != 0 ? d : byName(a, b);
    }
  });
  return all;
}
