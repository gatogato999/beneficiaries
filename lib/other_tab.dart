import 'package:flutter/material.dart';

import 'banks.dart';
import 'common.dart';
import 'flows.dart';
import 'models.dart';
import 'native_files.dart';

class OtherTab extends StatelessWidget {
  const OtherTab({super.key});

  Future<List<Person>?> _pickPeople(BuildContext context) {
    final sel = <String>{};
    return showDialog<List<Person>>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          title: const Text('اختر السجلات'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(shrinkWrap: true, children: [
              for (final p in store.people)
                CheckboxListTile(
                  value: sel.contains(p.id),
                  title: Text(p.name),
                  onChanged: (v) => set(() {
                    if (v == true) {
                      sel.add(p.id);
                    } else {
                      sel.remove(p.id);
                    }
                  }),
                ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('إلغاء')),
            TextButton(
              onPressed: () => set(() {
                if (sel.length == store.people.length) {
                  sel.clear();
                } else {
                  sel.addAll(store.people.map((p) => p.id));
                }
              }),
              child: const Text('الكل'),
            ),
            FilledButton(
              onPressed: sel.isEmpty
                  ? null
                  : () => Navigator.pop(c, store.people.where((p) => sel.contains(p.id)).toList()),
              child: const Text('مشاركة'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _import(BuildContext context) async {
    final text = await NativeFiles.pick();
    if (text != null) await runImport(text);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final empty = store.people.isEmpty;
        return ListView(padding: const EdgeInsets.all(12), children: [
          Card(
            child: Column(children: [
              const ListTile(
                leading: Icon(Icons.swap_vert),
                title: Text('تصدير واستيراد'),
                subtitle: Text('شارك سجلاتك مع الآخرين أو استورد سجلاتهم'),
              ),
              ListTile(
                leading: const Icon(Icons.ios_share),
                title: const Text('مشاركة كل السجلات'),
                enabled: !empty,
                onTap: () => sharePeople(List.of(store.people)),
              ),
              ListTile(
                leading: const Icon(Icons.checklist),
                title: const Text('مشاركة سجلات محددة'),
                enabled: !empty,
                onTap: () async {
                  final ps = await _pickPeople(context);
                  if (ps != null) await sharePeople(ps);
                },
              ),
              ListTile(
                leading: const Icon(Icons.file_open),
                title: const Text('استيراد من ملف'),
                onTap: () => _import(context),
              ),
              ListTile(
                leading: Badge(
                  isLabelVisible: store.pending.isNotEmpty,
                  label: Text('${store.pending.length}'),
                  child: const Icon(Icons.merge_type),
                ),
                title: const Text('تعارضات معلّقة'),
                subtitle: Text(store.pending.isEmpty ? 'لا يوجد' : 'اضغط للمراجعة'),
                onTap: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const PendingPage())),
              ),
            ]),
          ),
          Card(
            child: Column(children: [
              const ListTile(leading: Icon(Icons.support_agent), title: Text('تواصل مع المطوّر')),
              ListTile(
                leading: const Icon(Icons.email_outlined),
                title: const Text(kDevEmail, textDirection: TextDirection.ltr),
                trailing: const Icon(Icons.copy, size: 18),
                onTap: () => copyText(context, kDevEmail),
              ),
              ListTile(
                leading: const Icon(Icons.phone_outlined),
                title: const Text(kDevPhone, textDirection: TextDirection.ltr),
                trailing: const Icon(Icons.copy, size: 18),
                onTap: () => copyText(context, kDevPhone),
              ),
            ]),
          ),
        ]);
      },
    );
  }
}

class PendingPage extends StatelessWidget {
  const PendingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تعارضات معلّقة'),
        actions: [
          PopupMenuButton<Resolution>(
            onSelected: store.resolveAllPending,
            itemBuilder: (_) => const [
              PopupMenuItem(value: Resolution.merge, child: Text('دمج الكل')),
              PopupMenuItem(value: Resolution.separate, child: Text('حفظ الكل منفصلة')),
              PopupMenuItem(value: Resolution.skip, child: Text('تجاهل الكل')),
            ],
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          if (store.pending.isEmpty) return const Center(child: Text('لا توجد تعارضات'));
          return ListView(padding: const EdgeInsets.all(12), children: [
            for (final p in List<Pending>.of(store.pending))
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p.incoming.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    for (final a in p.incoming.accounts)
                      Text('${bankById(a.bankId)?.name ?? a.bankId}:  ${a.number}',
                          textDirection: TextDirection.ltr),
                    const SizedBox(height: 4),
                    Text(
                      store.byId(p.localId) == null
                          ? 'السجل الأصلي حُذف'
                          : 'يشبه: ${store.byId(p.localId)!.name}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, children: [
                      FilledButton.tonal(
                          onPressed: () => store.resolvePending(p, Resolution.merge),
                          child: const Text('دمج')),
                      FilledButton.tonal(
                          onPressed: () => store.resolvePending(p, Resolution.separate),
                          child: const Text('حفظ منفصل')),
                      TextButton(
                          onPressed: () => store.resolvePending(p, Resolution.skip),
                          child: const Text('تجاهل')),
                    ]),
                  ]),
                ),
              ),
          ]);
        },
      ),
    );
  }
}
