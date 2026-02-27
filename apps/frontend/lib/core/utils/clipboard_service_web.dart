import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'clipboard_service.dart';

class WebClipboardService implements ClipboardService {
  @override
  Future<void> copy(String text) async {
    // 1. Try modern Navigator API first
    try {
      final nav = web.window.navigator;
      // In package:web, we use the clipboard field directly.
      // Some browsers might not support it, so we check nullness if possible or catch.
      await nav.clipboard.writeText(text).toDart;
      return;
    } catch (e) {
      // Fallback if modern API fails or is restricted
    }

    // 2. Synchronous textarea fallback (most reliable for iOS Safari)
    _copyToClipboardFallback(text);
  }

  void _copyToClipboardFallback(String text) {
    final textArea = web.document.createElement('textarea') as web.HTMLTextAreaElement;
    textArea.value = text;

    // Ensure it's not visible but still part of the DOM
    textArea.style.position = 'fixed';
    textArea.style.left = '-9999px';
    textArea.style.top = '0';
    textArea.style.opacity = '0';

    web.document.body?.appendChild(textArea);

    textArea.focus();
    textArea.select();

    try {
      // ignore: deprecated_member_use_from_same_package
      web.document.execCommand('copy');
    } catch (err) {
      // Fail silently or log
    }

    web.document.body?.removeChild(textArea);
  }
}

ClipboardService getClipboardService() => WebClipboardService();
