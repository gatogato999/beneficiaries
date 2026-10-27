import 'package:flutter/material.dart';

import 'common.dart';
import 'native_files.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Future<void> _open(BuildContext c, String url) async {
    final ok = await NativeFiles.openUrl(url);
    if (!ok && c.mounted) copyText(c, url, 'تعذّر فتح الرابط - تم نسخه');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('حول التطبيق')),
      body: FutureBuilder<String>(
        future: NativeFiles.appVersion(),
        builder: (context, snap) {
          final v = snap.data ?? '';
          return ListView(padding: const EdgeInsets.all(16), children: [
            Center(
              child: Text('سجل المستفيدين',
                  style: Theme.of(context).textTheme.headlineSmall),
            ),
            if (v.isNotEmpty) Center(child: Text('الإصدار $v')),
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'جميع السجلات تُحفظ على جهازك فقط، ولا يرسلها التطبيق إلى أي جهة.\n'
                  'هذا التطبيق أداة مساعدة مستقلة وغير تابعة لأي بنك أو محفظة إلكترونية، '
                  'وأسماء البنوك مذكورة للتعريف فقط. تأكد دائماً من اسم المستفيد قبل الدفع.\n\n'
                  'Your records stay on this device; the app sends them nowhere. '
                  'This is an independent helper tool, not affiliated with any bank or wallet. '
                  'Always verify the receiver name before paying.',
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('سياسة الخصوصية'),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () => _open(context, kPrivacyUrl),
            ),
            ListTile(
              leading: const Icon(Icons.gavel_outlined),
              title: const Text('شروط الاستخدام'),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () => _open(context, kTermsUrl),
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('تراخيص المصادر المفتوحة'),
              onTap: () => showLicensePage(
                context: context,
                applicationName: 'سجل المستفيدين',
                applicationVersion: v,
              ),
            ),
          ]);
        },
      ),
    );
  }
}
