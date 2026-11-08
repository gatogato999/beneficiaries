import 'package:flutter/material.dart';

import 'banks.dart';
import 'common.dart';
import 'flows.dart';
import 'models.dart';
import 'people_filter.dart';
import 'person_editor.dart';
import 'sorting.dart';

class PeopleTab extends StatefulWidget {
  const PeopleTab({super.key});
  @override
  State<PeopleTab> createState() => _PeopleTabState();
}

class _PeopleTabState extends State<PeopleTab> {
  String q = '';

  SortMode _sort = sortModeFromName(store.sortModeName);
  String? _bankFilter;

  // Sorting by use works from a snapshot that is refreshed only when the data really changes
  // (add, edit, delete, pin, import, sort choice). Copying a number counts a use silently,
  // so cards do not jump around while you work with them.
  Map<String, Usage> _usage = {};
  int _seenRevision = -1;

  // Cards are collapsed by default. While a search is active they start expanded
  // (so a match by account number shows the account). `_flipped` holds the people
  // whose state was reversed by tapping the toggle.
  final Set<String> _flipped = {};

  bool _isOpen(Person p) => _flipped.contains(p.id);
  void _toggle(Person p) => setState(() {
        if (!_flipped.remove(p.id)) _flipped.add(p.id);
      });

  String _count(int n) {
    if (n == 1) return 'حساب واحد';
    if (n == 2) return 'حسابان';
    return n <= 10 ? '$n حسابات' : '$n حساباً';
  }

  bool _match(Person p) => personMatches(p, q) && hasBank(p, _bankFilter);

  String _sortLabel(SortMode m) => switch (m) {
        SortMode.alphabetical => 'الاسم',
        SortMode.recent => 'الأحدث استخداماً',
        SortMode.mostUsed => 'الأكثر استخداماً',
      };

  void _edit([Person? p]) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => PersonEditor(person: p)));

  Future<void> _confirmDelete(Person p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('حذف ${p.name}؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('حذف')),
        ],
      ),
    );
    if (ok != true) return;
    await store.delete(p.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('تم حذف ${p.name}'),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(label: 'تراجع', onPressed: () => store.restore(p)),
      ));
  }

  List<Widget> _account(Person p, Account a) {
    final bank = bankById(a.bankId);
    final bban = bank?.bban(a.number);
    return [
      const Divider(),
      Text(bank?.label ?? a.bankId, style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: 2),
      Text(a.number,
          textDirection: TextDirection.ltr,
          style: const TextStyle(fontSize: 18, letterSpacing: 1)),
      const SizedBox(height: 6),
      Wrap(spacing: 8, children: [
        FilledButton.tonalIcon(
          onPressed: () {
            copyText(context, a.number);
            store.recordUse(p.id);
          },
          icon: const Icon(Icons.copy, size: 18),
          label: const Text('نسخ'),
        ),
        FilledButton.tonalIcon(
          onPressed: bban == null
              ? null
              : () {
                  copyText(context, bban, 'تم نسخ BBAN');
                  store.recordUse(p.id);
                },
          icon: const Icon(Icons.copy_all, size: 18),
          label: const Text('نسخ bban'),
        ),
      ]),
    ];
  }

  Widget _card(Person p) {
    final open = _isOpen(p);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 4, 4, open ? 12 : 4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: InkWell(
                onTap: () => _toggle(p),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    Text(_count(p.accounts.length), style: Theme.of(context).textTheme.bodySmall),
                  ]),
                ),
              ),
            ),
            IconButton(
              tooltip: p.pinned ? 'إلغاء التثبيت' : 'تثبيت في الأعلى',
              icon: Icon(p.pinned ? Icons.push_pin : Icons.push_pin_outlined),
              color: p.pinned ? Theme.of(context).colorScheme.primary : null,
              onPressed: () => store.togglePin(p.id),
            ),
            IconButton(
              tooltip: open ? 'إخفاء الحسابات' : 'عرض الحسابات',
              icon: Icon(open ? Icons.expand_less : Icons.expand_more),
              onPressed: () => _toggle(p),
            ),
            PopupMenuButton<String>(
              tooltip: 'خيارات',
              onSelected: (v) {
                if (v == 'edit') _edit(p);
                if (v == 'share') sharePeople([p]);
                if (v == 'save') saveToDevice([p]);
                if (v == 'delete') _confirmDelete(p);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('تعديل')),
                PopupMenuItem(value: 'share', child: Text('مشاركة')),
                PopupMenuItem(value: 'save', child: Text('حفظ في الجهاز')),
                PopupMenuItem(value: 'delete', child: Text('حذف')),
              ],
            ),
          ]),
          if (open)
            Padding(
              padding: const EdgeInsets.only(right: 0, left: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [for (final a in p.accounts) ..._account(p, a)],
              ),
            ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            onChanged: (v) => setState(() {
              q = v;
              _flipped.clear();
            }),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'بحث بالاسم أو رقم الحساب أو البنك',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
          child: Wrap(spacing: 8, children: [
            PopupMenuButton<SortMode>(
              tooltip: 'ترتيب القائمة',
              onSelected: (m) {
                setState(() {
                  _sort = m;
                  _seenRevision = -1;
                });
                store.setSortMode(m.name);
              },
              itemBuilder: (_) => [
                for (final m in SortMode.values) PopupMenuItem(value: m, child: Text(_sortLabel(m))),
              ],
              child: Chip(
                avatar: const Icon(Icons.sort, size: 18),
                label: Text('ترتيب: ${_sortLabel(_sort)}'),
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'تصفية حسب البنك',
              onSelected: (v) => setState(() => _bankFilter = v.isEmpty ? null : v),
              itemBuilder: (_) {
                final inUse = banksInUse(store.people);
                return [
                  const PopupMenuItem(value: '', child: Text('كل البنوك')),
                  for (final b in banks)
                    if (inUse.contains(b.id)) PopupMenuItem(value: b.id, child: Text(b.name)),
                ];
              },
              child: Chip(
                avatar: const Icon(Icons.filter_list, size: 18),
                label: Text(_bankFilter == null ? 'كل البنوك' : (bankById(_bankFilter!)?.name ?? _bankFilter!)),
                onDeleted: _bankFilter == null ? null : () => setState(() => _bankFilter = null),
              ),
            ),
          ]),
        ),
        Expanded(
          child: ListenableBuilder(
            listenable: store,
            builder: (context, _) {
              if (_seenRevision != store.revision) {
                _usage = usageSnapshot(store.people);
                _seenRevision = store.revision;
              }
              final list = sortPeople(store.people.where(_match), _sort, _usage);
              if (list.isEmpty) {
                if (store.people.isEmpty) return const Center(child: Text('لا يوجد مستفيدون بعد'));
                return Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text('لا نتائج'),
                    if (_bankFilter != null)
                      TextButton(
                        onPressed: () => setState(() => _bankFilter = null),
                        child: const Text('إزالة تصفية البنك'),
                      ),
                  ]),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 88),
                itemCount: list.length,
                itemBuilder: (_, i) => _card(list[i]),
              );
            },
          ),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _edit,
        icon: const Icon(Icons.person_add),
        label: const Text('إضافة'),
      ),
    );
  }
}
