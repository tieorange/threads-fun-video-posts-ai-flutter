import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../cubits/process_cubit.dart';
import '../../../../../core/widgets/app_shell_scaffold.dart';
import '../../../../../i18n/strings.g.dart';

class ProcessingPage extends StatelessWidget {
  const ProcessingPage({super.key});

  void _showStartOver(BuildContext ctx) {
    showDialog<bool>(
      context: ctx,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.chat.resetConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(t.common.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(t.results.startOver),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && ctx.mounted) {
        ctx.read<ProcessCubit>().resetAll(ctx);
        ctx.go('/');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppShellScaffold(
      title: t.processing.title,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: t.results.startOver,
          onPressed: () => _showStartOver(context),
        ),
      ],
      body: BlocListener<ProcessCubit, ProcessState>(
        listener: (context, state) {
          if (state is ProcessDone) {
            context.go('/results');
          } else if (state is ProcessFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
                action: SnackBarAction(label: 'Back', onPressed: () => context.go('/review')),
              ),
            );
          }
        },
        child: BlocBuilder<ProcessCubit, ProcessState>(
          builder: (context, state) {
            if (state is ProcessFailure) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          t.processing.errorTitle,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          state.message,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 32),
                        FilledButton.icon(
                          onPressed: () => context.go('/review'),
                          icon: const Icon(Icons.arrow_back),
                          label: Text(t.processing.goBack),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            final (label, progress) = switch (state) {
              ProcessSubmitting() => (t.processing.submitting, 0.0),
              ProcessRunning(:final progress) => (_progressLabel(progress), progress / 100.0),
              _ => ('Starting…', 0.0),
            };

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.movie_creation_outlined, size: 64),
                      const SizedBox(height: 24),
                      Text(
                        label,
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      LinearProgressIndicator(
                        value: progress > 0 ? progress : null,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 12),
                      if (state is ProcessRunning)
                        Text(
                          '${state.progress}%',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      const SizedBox(height: 32),
                      Text(
                        t.processing.disclaimer,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _progressLabel(int progress) {
    if (progress <= 10) return t.processing.fetchingInfo;
    if (progress <= 50) return t.processing.downloading;
    if (progress < 100) return t.processing.cutting;
    return t.common.done;
  }
}
