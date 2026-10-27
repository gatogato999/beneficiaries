import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'banks.dart';
import 'common.dart';
import 'models.dart';
import 'native_files.dart';
import 'store.dart';

const kMime = 'application/x-sijil+json';

Future<void> sharePeople(List<Person> ps) async {
  if (ps.isEmpty) return;
  final dir = await getTemporaryDirectory();
  for (final e in dir.listSync()) {
    // do not leave old exports (they contain personal data) lying in the cache
    if (e is File && e.path.endsWith('.sijil')) {
      try {
        e.deleteSync();
      } catch (_) {}
    }
  }
  final stamp =
      DateTime.now().toIso8601String().substring(0, 16).replaceAll(RegExp(r'[-:T]'), '');
  final f = File('${dir.path}/sijil_$stamp.sijil');
  await f.writeAsString(Store.exportJson(ps), flush: true);
  await SharePlus.instance.share(
    ShareParams(files: [XFile(f.path, mimeType: kMime)], subject: 'سجل المستفيدين'),
  );
}

Widget _block(String title, Person p) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(p.name),
        for (final a in p.accounts)
          Text('${bankById(a.bankId)?.name ?? a.bankId}:  ${a.number}',
              textDirection: TextDirection.ltr),
      ],
    );

Future<(Resolution, bool)> askConflict(Person inc, Person local) async {
  var all = false;
  final res = await showDialog<Resolution>(
    context: navKey.currentContext!,
    barrierDismissible: false,
    builder: (c) => StatefulBuilder(
      builder: (c, set) => AlertDialog(
        title: const Text('سجل مشابه موجود'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Align(alignment: AlignmentDirectional.centerStart, child: _block('لديك:', local)),
            const Divider(height: 24),
            Align(alignment: AlignmentDirectional.centerStart, child: _block('المستورد:', inc)),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: all,
              onChanged: (v) => set(() => all = v ?? false),
              title: const Text('تطبيق نفس القرار على باقي التعارضات'),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, Resolution.merge), child: const Text('دمج')),
          TextButton(
              onPressed: () => Navigator.pop(c, Resolution.separate),
              child: const Text('حفظ منفصل')),
          TextButton(onPressed: () => Navigator.pop(c, Resolution.skip), child: const Text('تخطي')),
          TextButton(onPressed: () => Navigator.pop(c, Resolution.later), child: const Text('لاحقاً')),
        ],
      ),
    ),
  );
  return (res ?? Resolution.later, all);
}

Future<void> runImport(String text) async {
  if (navKey.currentContext == null) return;
  final incoming = Store.parseExport(text);
  if (incoming == null) {
    toast(navKey.currentContext!, 'هذا ليس ملف سجل المستفيدين');
    return;
  }
  ImportReport r;
  try {
    r = await store.importPeople(incoming, askConflict);
  } catch (_) {
    if (navKey.currentContext != null) {
      toast(navKey.currentContext!, 'تعذّر الاستيراد، حاول مرة أخرى');
    }
    return;
  }
  if (navKey.currentContext == null) return;
  await showDialog<void>(
    context: navKey.currentContext!,
    builder: (c) => AlertDialog(
      title: const Text('تم الاستيراد'),
      content: Text('أُضيف: ${r.added}\nدُمج: ${r.merged}\nحُفظ منفصلاً: ${r.separate}\n'
          'تم تخطيه: ${r.skipped}\nمعلّق: ${r.later}'),
      actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('حسناً'))],
    ),
  );
}

Future<void> saveToDevice(List<Person> ps) async {
  if (ps.isEmpty) return;
  final stamp =
      DateTime.now().toIso8601String().substring(0, 16).replaceAll(RegExp(r'[-:T]'), '');
  final ok = await NativeFiles.saveText('sijil_$stamp.sijil', Store.exportJson(ps));
  final c = navKey.currentContext;
  if (c != null && c.mounted) toast(c, ok ? 'تم حفظ الملف' : 'لم يتم الحفظ');
}
