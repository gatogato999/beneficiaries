import 'package:flutter/material.dart';

import 'banks.dart';
import 'common.dart';
import 'flows.dart';
import 'models.dart';
import 'person_editor.dart';

class PeopleTab extends StatefulWidget {
  const PeopleTab({super.key});
  @override
  State<PeopleTab> createState() => _PeopleTabState();
}

class _PeopleTabState extends State<PeopleTab> {
  String q = '';

  bool _match(Person p) {
    if (q.trim().isEmpty) return true;
    final n = normName(q);
    final digits = q.replaceAll(RegExp(r'\D'), '');
    if (normName(p.name).contains(n)) return true;
    return p.accounts.any((a) =>
        (digits.isNotEmpty && a.number.contains(digits)) ||
        normName(bankById(a.bankId)?.label ?? '').contains(n));
  }

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
    if (ok == true) await store.delete(p.id);
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
          onPressed: () => copyText(context, a.number),
          icon: const Icon(Icons.copy, size: 18),
          label: const Text('نسخ'),
        ),
        FilledButton.tonalIcon(
          onPressed: bban == null ? null : () => copyText(context, bban, 'تم نسخ BBAN'),
          icon: const Icon(Icons.copy_all, size: 18),
          label: const Text('نسخ bban'),
        ),
      ]),
    ];
  }

  Widget _card(Person p) => Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 4, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                  child: Text(p.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold))),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'edit') _edit(p);
                  if (v == 'share') sharePeople([p]);
                  if (v == 'delete') _confirmDelete(p);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('تعديل')),
                  PopupMenuItem(value: 'share', child: Text('مشاركة')),
                  PopupMenuItem(value: 'delete', child: Text('حذف')),
                ],
              ),
            ]),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            onChanged: (v) => setState(() => q = v),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'بحث بالاسم أو رقم الحساب أو البنك',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        Expanded(
          child: ListenableBuilder(
            listenable: store,
            builder: (context, _) {
              final list = store.people.where(_match).toList();
              if (list.isEmpty) {
                return Center(child: Text(store.people.isEmpty ? 'لا يوجد مستفيدون بعد' : 'لا نتائج'));
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
