import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'banks.dart';
import 'common.dart';
import 'digits.dart';
import 'digits_input.dart';

class ConverterTab extends StatefulWidget {
  const ConverterTab({super.key});
  @override
  State<ConverterTab> createState() => _ConverterTabState();
}

class _ConverterTabState extends State<ConverterTab> {
  late Bank bank = bankById(store.lastBank ?? '') ?? banks.first;
  final ctrl = TextEditingController();

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  /// Reads the clipboard only when the button is tapped.
  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final number = extractAccountNumber(data?.text ?? '');
    if (!mounted) return;
    if (number == null) {
      toast(context, 'لا يوجد رقم حساب في الحافظة');
      return;
    }
    setState(() {
      ctrl.text = number;
      ctrl.selection = TextSelection.collapsed(offset: number.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bban = bank.bban(ctrl.text);
    final tooLong = ctrl.text.isNotEmpty && bban == null && ctrl.text.replaceAll('0', '').isNotEmpty;
    final cs = Theme.of(context).colorScheme;
    return ListView(padding: const EdgeInsets.all(16), children: [
      DropdownMenu<Bank>(
        initialSelection: bank,
        expandedInsets: EdgeInsets.zero,
        label: const Text('البنك / المحفظة'),
        dropdownMenuEntries: [for (final b in banks) DropdownMenuEntry(value: b, label: b.label)],
        onSelected: (b) {
          setState(() => bank = b ?? bank);
          store.setLastBank(bank.id);
        },
      ),
      const SizedBox(height: 16),
      TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        inputFormatters: [AsciiDigitsFormatter()],
        textDirection: TextDirection.ltr,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: 'رقم الحساب',
          helperText: 'عادةً 7 أرقام',
          suffixIcon: IconButton(
            tooltip: 'لصق من الحافظة',
            icon: const Icon(Icons.content_paste),
            onPressed: _paste,
          ),
          errorText: tooLong ? 'الرقم أطول من المتوقع (الحد الأقصى ${bank.width} أرقام)' : null,
        ),
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 16),
      if (bban != null)
        Card(
          color: cs.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              const Text('رقم الـ BBAN'),
              const SizedBox(height: 8),
              SelectableText(bban,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 4),
              Text(bank.pattern,
                  textDirection: TextDirection.ltr,
                  style: TextStyle(color: cs.onPrimaryContainer.withValues(alpha: .85))),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => copyText(context, bban),
                icon: const Icon(Icons.copy),
                label: const Text('نسخ'),
              ),
            ]),
          ),
        ),
      const SizedBox(height: 8),
      const Card(
        child: ListTile(
          leading: Icon(Icons.info_outline),
          title: Text('تأكد من اسم المستفيد في تطبيق البنك قبل تأكيد الدفع.'),
        ),
      ),
    ]);
  }
}
