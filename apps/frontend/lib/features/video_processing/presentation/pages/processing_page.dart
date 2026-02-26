import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../cubits/process_cubit.dart';
import '../../../../../core/widgets/app_shell_scaffold.dart';

class ProcessingPage extends StatelessWidget {
  const ProcessingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShellScaffold(
      title: 'Generating Clips',
      body: BlocListener<ProcessCubit, ProcessState>(
        listener: (context, state) {
          if (state is ProcessDone) {
            context.go('/results');
          } else if (state is ProcessFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
                action: SnackBarAction(
                  label: 'Back',
                  onPressed: () => context.go('/review'),
                ),
              ),
            );
          }
        },
        child: BlocBuilder<ProcessCubit, ProcessState>(
          builder: (context, state) {
            final (label, progress) = switch (state) {
              ProcessSubmitting() => ('Submitting job…', 0.0),
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
                        'Downloading and cutting your selected moments.\nThis may take a few minutes depending on video length.',
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
    if (progress <= 10) return 'Fetching video info…';
    if (progress <= 30) return 'Downloading video…';
    if (progress < 100) return 'Cutting clips…';
    return 'Done!';
  }
}
