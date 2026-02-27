import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/di/injection.dart';
import '../logging/log_exporter.dart';

class LogOverlay extends StatefulWidget {
  const LogOverlay({super.key, required this.child});

  final Widget child;

  @override
  State<LogOverlay> createState() => _LogOverlayState();
}

class _LogOverlayState extends State<LogOverlay> {
  bool _isVisible = false;

  void _toggleOverlay() {
    setState(() {
      _isVisible = !_isVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isVisible)
          Positioned.fill(
            child: Material(
              color: Colors.black.withOpacity(0.85),
              child: SafeArea(
                child: Column(
                  children: [
                    _buildHeader(),
                    Expanded(child: _buildLogView()),
                  ],
                ),
              ),
            ),
          ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            mini: true,
            backgroundColor: _isVisible ? Colors.red : Colors.blue,
            onPressed: _toggleOverlay,
            child: Icon(_isVisible ? Icons.close : Icons.bug_report),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
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
            onPressed: () {
              final exporter = sl<LogExporter>();
              Clipboard.setData(ClipboardData(text: exporter.buildAiBundle()));
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Logs copied to clipboard')));
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: () {
              // Note: LogBuffer clearing isn't directly exposed here,
              // but we could add it if needed.
            },
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
