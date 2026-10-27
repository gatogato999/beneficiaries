import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'banks.dart';
import 'common.dart';
import 'models.dart';

class _Row {
  String bankId;
  final TextEditingController num;
  _Row(this.bankId, String n) : num = TextEditingController(text: n);
}

class PersonEditor extends StatefulWidget {
  final Person? person;
  const PersonEditor({super.key, this.person});
  @override
  State<PersonEditor> createState() => _PersonEditorState();
}

class _PersonEditorState extends State<PersonEditor> {
  late final TextEditingController name;
  late final List<_Row> rows;

  @override
  void initState() {
    super.initState();
    final p = widget.person;
    name = TextEditingController(text: p?.name ?? '');
    rows = p == null
        ? [_Row(banks.first.id, '')]
        : p.accounts.map((a) => _Row(a.bankId, a.number)).toList();
  }

  Future<void> _save() async {
    final n = name.text.trim();
    if (n.isEmpty) return toast(context, 'اكتب اسم المستفيد');
    final accs = <Account>[];
    for (final r in rows) {
      final t = r.num.text.trim();
      if (t.isEmpty) continue;
      if (bankById(r.bankId)?.bban(t) == null) return toast(context, 'رقم الحساب غير صالح: $t');
      accs.add(Account(r.bankId, t));
    }
    if (accs.isEmpty) return toast(context, 'أضف حساباً واحداً على الأقل');
    await store.upsert(Person(widget.person?.id ?? newId(), n, accs));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.person == null ? 'مستفيد جديد' : 'تعديل المستفيد'),
        actions: [TextButton(onPressed: _save, child: const Text('حفظ'))],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        TextField(
          controller: name,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'الاسم'),
        ),
        const SizedBox(height: 16),
        for (final r in rows)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(children: [
                Row(children: [
                  Expanded(
                    child: DropdownMenu<String>(
                      initialSelection: r.bankId,
                      expandedInsets: EdgeInsets.zero,
                      label: const Text('البنك / المحفظة'),
                      dropdownMenuEntries: [
                        for (final b in banks) DropdownMenuEntry(value: b.id, label: b.label)
                      ],
                      onSelected: (v) => r.bankId = v ?? r.bankId,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'حذف الحساب',
                    onPressed: rows.length > 1 ? () => setState(() => rows.remove(r)) : null,
                  ),
                ]),
                const SizedBox(height: 12),
                TextField(
                  controller: r.num,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textDirection: TextDirection.ltr,
                  decoration:
                      const InputDecoration(border: OutlineInputBorder(), labelText: 'رقم الحساب'),
                ),
              ]),
            ),
          ),
        OutlinedButton.icon(
          onPressed: () => setState(() => rows.add(_Row(banks.first.id, ''))),
          icon: const Icon(Icons.add),
          label: const Text('إضافة حساب آخر'),
        ),
      ]),
    );
  }
}
