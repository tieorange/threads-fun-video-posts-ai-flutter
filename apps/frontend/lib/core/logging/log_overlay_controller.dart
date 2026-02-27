import 'package:flutter/foundation.dart';

class LogOverlayController {
  final ValueNotifier<bool> isVisible = ValueNotifier<bool>(false);

  void toggle() => isVisible.value = !isVisible.value;

  void open() => isVisible.value = true;

  void close() => isVisible.value = false;
}
