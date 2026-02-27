import 'package:flutter/material.dart';
import '../di/injection.dart';
import '../logging/log_exporter.dart';
import '../theme/theme_cubit.dart';
import '../utils/clipboard_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../i18n/strings.g.dart';

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
    this.resizeToAvoidBottomInset = true,
  });

  final String? title;
  final Widget? leading;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      appBar: AppBar(
        title: title != null ? Text(title!) : null,
        leading: leading,
        actions: [...?actions, const _ThemeToggleButton(), _CopyLogsButton()],
      ),
      body: SafeArea(top: false, child: body),
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
      tooltip: t.common.copyLogs,
      onPressed: () async {
        final exporter = sl<LogExporter>();
        final bundle = exporter.buildAiBundle();
        await sl<ClipboardService>().copy(bundle);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t.common.logsCopied), duration: const Duration(seconds: 3)),
          );
        }
      },
    );
  }
}

class _ThemeToggleButton extends StatelessWidget {
  const _ThemeToggleButton();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        final isDark = themeMode == ThemeMode.dark;
        return IconButton(
          icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
          tooltip: isDark ? t.common.toggleLight : t.common.toggleDark,
          onPressed: () => context.read<ThemeCubit>().toggleTheme(),
        );
      },
    );
  }
}
