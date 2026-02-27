import 'package:flutter/services.dart';
import 'clipboard_service_stub.dart' if (dart.library.js_util) 'clipboard_service_web.dart';

abstract class ClipboardService {
  Future<void> copy(String text);

  factory ClipboardService() => getClipboardService();
}

class DefaultClipboardService implements ClipboardService {
  @override
  Future<void> copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }
}
