import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../di/injection.dart';
import '../logging/log_exporter.dart';

/// Shared scaffold used by every page.
/// Always renders a "Copy logs" action in the AppBar so logs are
/// accessible on every screen for easy AI-assisted debugging.
class AppShellScaffold extends StatelessWidget {
  const AppShellScaffold({
    super.key,
    this.title,
    this.leading,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.resizeToAvoidBottomInset,
  });

  final String? title;
  final Widget? leading;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool? resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      appBar: AppBar(
        title: title != null ? Text(title!) : null,
        leading: leading,
        actions: [
          ...?actions,
          _CopyLogsButton(),
        ],
      ),
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

class _CopyLogsButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.bug_report_outlined),
      tooltip: 'Copy logs',
      onPressed: () async {
        final exporter = sl<LogExporter>();
        final bundle = exporter.buildAiBundle();
        await Clipboard.setData(ClipboardData(text: bundle));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Logs copied! Paste to AI to diagnose.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      },
    );
  }
}
