import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/di/injection.dart';
import '../logging/log_exporter.dart';
import '../logging/log_overlay_controller.dart';

class LogOverlay extends StatefulWidget {
  const LogOverlay({super.key, required this.child});

  final Widget child;

  @override
  State<LogOverlay> createState() => _LogOverlayState();
}

class _LogOverlayState extends State<LogOverlay> {
  @override
  Widget build(BuildContext context) {
    final controller = sl<LogOverlayController>();
    return ValueListenableBuilder<bool>(
      valueListenable: controller.isVisible,
      builder: (context, isVisible, _) {
        if (!isVisible) return widget.child;

        return Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: [
              widget.child,
              Positioned.fill(
                child: Overlay(
                  initialEntries: [
                    OverlayEntry(
                      builder:
                          (context) => Material(
                            color: Colors.black.withValues(alpha: 0.85),
                            child: SafeArea(
                              child: Column(
                                children: [
                                  _buildHeader(context, controller),
                                  Expanded(child: _buildLogView()),
                                ],
                              ),
                            ),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, LogOverlayController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.blueGrey.shade900,
      child: Row(
        children: [
          const Text(
            'App Logs',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.copy, color: Colors.white),
            tooltip: 'Copy logs',
            onPressed: () {
              final exporter = sl<LogExporter>();
              Clipboard.setData(ClipboardData(text: exporter.buildAiBundle()));
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Logs copied to clipboard')));
            },
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            tooltip: 'Close overlay',
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
          style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 10),
        ),
      ),
    );
  }
}
