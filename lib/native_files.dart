import 'package:flutter/services.dart';

/// Bridge to MainActivity.kt (no third-party plugin).
class NativeFiles {
  static const _ch = MethodChannel('sd.sijil/files');

  /// File content when the app was launched by "open with".
  static Future<String?> initialFile() => _ch.invokeMethod<String>('initialFile');

  /// System file picker; returns file text or null if cancelled.
  static Future<String?> pick() => _ch.invokeMethod<String>('pick');

  /// Opens a link with the system (wa.me opens WhatsApp if installed). False on failure.
  static Future<bool> openUrl(String url) async =>
      (await _ch.invokeMethod<bool>('openUrl', url)) ?? false;

  /// System "save as" dialog. True if the file was written.
  static Future<bool> saveText(String name, String text) async =>
      (await _ch.invokeMethod<bool>('saveFile', {'name': name, 'text': text})) ?? false;

  /// "open with" while the app is already running.
  static void listen(void Function(String text) onFile) {
    _ch.setMethodCallHandler((call) async {
      if (call.method == 'fileOpened') onFile(call.arguments as String);
    });
  }
}
