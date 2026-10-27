import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'models.dart';

class ImportReport {
  int added = 0, merged = 0, separate = 0, skipped = 0, later = 0;
}

class Store extends ChangeNotifier {
  final List<Person> people = [];
  final List<Pending> pending = [];
  late File _file;

  Future<void> load() async {
    final dir = await getApplicationDocumentsDirectory();
    _file = File('${dir.path}/data.json');
    if (await _file.exists()) {
      try {
        final j = jsonDecode(await _file.readAsString()) as Map<String, dynamic>;
        people.addAll((j['people'] as List).map((e) => Person.fromJson(e)));
        pending.addAll(((j['pending'] ?? []) as List).map((e) => Pending.fromJson(e)));
      } catch (_) {
        await _file.copy('${_file.path}.bak'); // keep the unreadable file
      }
    }
    _sort();
  }

  void _sort() => people.sort((a, b) => normName(a.name).compareTo(normName(b.name)));

  Future<void> _queue = Future.value();

  /// Writes are queued so two quick saves can never interleave on the temp file.
  Future<void> _save() {
    _sort();
    final data = jsonEncode({
      'version': 1,
      'people': people.map((p) => p.toJson()).toList(),
      'pending': pending.map((p) => p.toJson()).toList(),
    });
    final job = _queue.then((_) async {
      final tmp = File('${_file.path}.tmp');
      await tmp.writeAsString(data, flush: true);
      await tmp.rename(_file.path);
    });
    _queue = job.catchError((_) {});
    notifyListeners();
    return job;
  }

  Person? byId(String id) {
    for (final p in people) {
      if (p.id == id) return p;
    }
    return null;
  }

  Future<void> upsert(Person p) async {
    final i = people.indexWhere((x) => x.id == p.id);
    if (i >= 0) {
      people[i] = p;
    } else {
      people.add(p);
    }
    await _save();
  }

  Future<void> delete(String id) async {
    people.removeWhere((p) => p.id == id);
    await _save();
  }

  // ---------- export / import file format ----------
  static String exportJson(List<Person> ps) => jsonEncode({
        'app': 'sijil',
        'version': 1,
        'people': ps.map((p) => p.toJson(withId: false)).toList(),
      });

  static const kMaxImport = 5000;

  /// Clamp what comes from files made by other people (or other app versions).
  static Person _sanitize(Person p) {
    p.name = p.name.length > 120 ? p.name.substring(0, 120) : p.name;
    p.accounts = p.accounts
        .map((a) => Account(a.bankId.length > 40 ? '' : a.bankId, a.number.replaceAll(RegExp(r'\D'), '')))
        .where((a) => a.bankId.isNotEmpty && a.number.isNotEmpty && a.number.length <= 20)
        .take(50)
        .toList();
    return p;
  }

  static List<Person>? parseExport(String text) {
    try {
      final j = jsonDecode(text) as Map<String, dynamic>;
      if (j['app'] != 'sijil') return null;
      final list = j['people'] as List;
      if (list.length > kMaxImport) return null;
      return list
          .map((e) => Person.fromJson(e as Map<String, dynamic>))
          .map(_sanitize)
          .where((p) => p.name.isNotEmpty && p.accounts.isNotEmpty)
          .toList();
    } catch (_) {
      return null;
    }
  }

  // ---------- conflict handling ----------
  /// Same account (bank+number) wins over same name.
  Person? _findMatch(Person inc) {
    final keys = inc.accounts.map((a) => a.key).toSet();
    for (final p in people) {
      if (p.accounts.any((a) => keys.contains(a.key))) return p;
    }
    final n = normName(inc.name);
    for (final p in people) {
      if (normName(p.name) == n) return p;
    }
    return null;
  }

  bool _covers(Person local, Person inc) {
    if (normName(local.name) != normName(inc.name)) return false;
    final keys = local.accounts.map((a) => a.key).toSet();
    return inc.accounts.every((a) => keys.contains(a.key));
  }

  void _mergeInto(Person local, Person inc) {
    final keys = local.accounts.map((a) => a.key).toSet();
    for (final a in inc.accounts) {
      if (keys.add(a.key)) local.accounts.add(Account(a.bankId, a.number));
    }
  }

  Future<ImportReport> importPeople(
    List<Person> incoming,
    Future<(Resolution, bool)> Function(Person incoming, Person local) ask,
  ) async {
    final r = ImportReport();
    Resolution? bulk;
    for (final inc in incoming) {
      final local = _findMatch(inc);
      if (local == null) {
        inc.id = newId();
        people.add(inc);
        r.added++;
        continue;
      }
      if (_covers(local, inc)) {
        r.skipped++; // nothing new
        continue;
      }
      var res = bulk;
      if (res == null) {
        final (x, all) = await ask(inc, local);
        res = x;
        if (all) bulk = x;
      }
      switch (res) {
        case Resolution.merge:
          _mergeInto(local, inc);
          r.merged++;
        case Resolution.separate:
          inc.id = newId();
          people.add(inc);
          r.separate++;
        case Resolution.skip:
          r.skipped++;
        case Resolution.later:
          pending.add(Pending(inc, local.id));
          r.later++;
      }
    }
    await _save();
    return r;
  }

  Future<void> resolvePending(Pending p, Resolution r) async {
    pending.remove(p);
    final local = byId(p.localId);
    if (r == Resolution.merge && local != null) {
      _mergeInto(local, p.incoming);
    } else if (r == Resolution.separate || (r == Resolution.merge && local == null)) {
      p.incoming.id = newId();
      people.add(p.incoming);
    }
    await _save();
  }

  Future<void> resolveAllPending(Resolution r) async {
    for (final p in List<Pending>.from(pending)) {
      await resolvePending(p, r);
    }
  }
}
