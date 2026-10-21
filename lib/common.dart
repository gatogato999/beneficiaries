import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'store.dart';

final navKey = GlobalKey<NavigatorState>();
final store = Store();

const kDevEmail = String.fromEnvironment('DEV_EMAIL');
const kDevPhone = String.fromEnvironment('DEV_PHONE');

Future<void> copyText(
  BuildContext c,
  String t, [
  String msg = 'تم النسخ',
]) async {
  await Clipboard.setData(ClipboardData(text: t));
  if (!c.mounted) return;
  ScaffoldMessenger.of(c)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 1)),
    );
}

void toast(BuildContext c, String msg) => ScaffoldMessenger.of(c)
  ..hideCurrentSnackBar()
  ..showSnackBar(SnackBar(content: Text(msg)));
