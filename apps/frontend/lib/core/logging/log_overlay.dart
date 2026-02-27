import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/di/injection.dart';
import '../logging/log_exporter.dart';
import 'log_overlay_controller.dart';

class LogOverlay extends StatefulWidget {
  const LogOverlay({super.key, required this.child});

  final Widget child;

  @override
  State<LogOverlay> createState() => _LogOverlayState();
}

class _LogOverlayState extends State<LogOverlay> {
  bool _copied = false;

  Future<void> _copyLogs() async {
    final exporter = sl<LogExporter>();
    await Clipboard.setData(ClipboardData(text: exporter.buildAiBundle()));
    if (!mounted) return;
    setState(() {
      _copied = true;
    });
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _copied = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = sl<LogOverlayController>();

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          widget.child,
          ValueListenableBuilder<bool>(
            valueListenable: controller.isVisible,
            builder: (context, isVisible, _) {
              if (!isVisible) return const SizedBox.shrink();
              return Positioned.fill(
                child: Material(
                  color: Colors.black.withValues(alpha: 0.85),
                  child: SafeArea(
                    child: Column(
                      children: [
                        _buildHeader(controller),
                        Expanded(child: _buildLogView()),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(LogOverlayController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.blueGrey.shade900,
      child: Row(
        children: [
          const Text(
            'App Logs',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          if (_copied) ...[
            const SizedBox(width: 8),
            const Text(
              'Copied',
              style: TextStyle(color: Colors.greenAccent, fontSize: 12),
            ),
          ],
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.copy, color: Colors.white),
            onPressed: _copyLogs,
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: controller.close,
          ),
        ],
      ),
    );
  }

  Widget _buildLogView() {
    final exporter = sl<LogExporter>();
    final logs = exporter.buildAiBundle();

    return Container(
      padding: const EdgeInsets.all(8),
      width: double.infinity,
      child: SingleChildScrollView(
        child: Text(
          logs,
          style: const TextStyle(
            color: Colors.greenAccent,
            fontFamily: 'monospace',
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}
