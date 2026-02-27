import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import '../../domain/entities/clip_artifact.dart';
import '../../domain/entities/funny_moment.dart';
import '../cubits/process_cubit.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/utils/clipboard_service.dart';
import '../../../../../core/utils/launch_service.dart';
import '../../../../../core/widgets/app_shell_scaffold.dart';
import '../../../../../i18n/strings.g.dart';

class ResultsPage extends StatelessWidget {
  const ResultsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ProcessCubit>().state;
    if (state is! ProcessDone) {
      return const AppShellScaffold(body: Center(child: CircularProgressIndicator()));
    }

    final jobStatus = state.jobStatus;
    final moments = {for (final m in jobStatus.moments) m.id: m};

    return AppShellScaffold(
      title: t.results.title,
      leading: BackButton(
        onPressed: () {
          context.read<ProcessCubit>().resetAll(context);
          context.go('/');
        },
      ),
      actions: [
        IconButton(
          tooltip: t.results.startOver,
          icon: const Icon(Icons.refresh),
          onPressed: () {
            context.read<ProcessCubit>().resetAll(context);
            context.go('/');
          },
        ),
      ],
      body: jobStatus.clips.isEmpty
          ? Center(child: Text(t.results.noClips))
          : LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 640;
                final horizontalPadding = compact ? 16.0 : 48.0;

                return Column(
                  children: [
                    _ResultsSummary(clipsCount: jobStatus.clips.length),
                    Expanded(
                      child: ListView.separated(
                        padding: EdgeInsets.fromLTRB(horizontalPadding, 12, horizontalPadding, 24),
                        physics: const BouncingScrollPhysics(),
                        itemCount: jobStatus.clips.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final clip = jobStatus.clips[index];
                          final moment = moments[clip.momentId];
                          return _ClipCard(clip: clip, moment: moment);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _ResultsSummary extends StatelessWidget {
  const _ResultsSummary({required this.clipsCount});

  final int clipsCount;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.35))),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          Chip(
            avatar: Icon(Icons.video_collection_outlined, size: 18, color: cs.primary),
            label: Text(t.results.clipsReady.replaceFirst('{count}', clipsCount.toString())),
          ),
          Text(
            t.results.downloadHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _ClipCard extends StatefulWidget {
  const _ClipCard({required this.clip, this.moment});

  final ClipArtifact clip;
  final FunnyMoment? moment;

  @override
  State<_ClipCard> createState() => _ClipCardState();
}

class _ClipCardState extends State<_ClipCard> {
  VideoPlayerController? _controller;
  ChewieController? _chewie;
  bool _playerReady = false;
  bool _showPlayer = false;
  bool _loadingPlayer = false;

  Future<void> _initPlayer() async {
    if (_showPlayer || _loadingPlayer) return;
    setState(() {
      _showPlayer = true;
      _loadingPlayer = true;
    });

    try {
      final baseUrl = const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://localhost:3000',
      );

      final controller = VideoPlayerController.networkUrl(
        Uri.parse('$baseUrl${widget.clip.downloadUrl}'),
      );
      await controller.initialize();

      final chewie = ChewieController(
        videoPlayerController: controller,
        autoPlay: false,
        looping: false,
      );

      if (!mounted) {
        chewie.dispose();
        controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _chewie = chewie;
        _playerReady = true;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.results.playerLoadFailed)));
      setState(() => _showPlayer = false);
    } finally {
      if (mounted) {
        setState(() => _loadingPlayer = false);
      }
    }
  }

  @override
  void dispose() {
    _chewie?.dispose();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _download() async {
    final baseUrl = const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:3000',
    );
    final uri = '$baseUrl${widget.clip.downloadUrl}?download=1';

    try {
      await sl<LaunchService>().launchUrl(uri);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.results.downloadBlocked)));
    }
  }

  Future<void> _copyPostText() async {
    final text = widget.moment?.postText ?? '';
    await sl<ClipboardService>().copy(text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.results.postTextCopied)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final moment = widget.moment;
    final cs = Theme.of(context).colorScheme;
    final compact = MediaQuery.sizeOf(context).width < 640;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: _showPlayer && _playerReady && _chewie != null
                ? Chewie(controller: _chewie!)
                : InkWell(
                    onTap: _initPlayer,
                    child: ColoredBox(
                      color: cs.surfaceContainerHighest,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_loadingPlayer)
                            const SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(strokeWidth: 2.5),
                            )
                          else
                            Icon(Icons.play_circle_outline, size: 60, color: cs.primary),
                          const SizedBox(height: 10),
                          Text(
                            t.results.tapToPreview,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (moment != null) ...[
                  SelectableText(
                    moment.caption,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ClipMetaChip(
                        icon: Icons.schedule,
                        text:
                            '${moment.startSec.toStringAsFixed(0)}s - ${moment.endSec.toStringAsFixed(0)}s',
                      ),
                      _ClipMetaChip(
                        icon: Icons.timer,
                        text: '${(moment.endSec - moment.startSec).toStringAsFixed(0)} s',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SelectableText(
                      moment.postText,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _copyPostText,
                      icon: const Icon(Icons.copy_all_outlined),
                      label: Text(t.results.copyPostText),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (compact)
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.play_arrow),
                          label: Text(t.results.preview),
                          onPressed: _showPlayer ? null : _initPlayer,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          icon: const Icon(Icons.download),
                          label: Text(t.results.download),
                          onPressed: _download,
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.play_arrow),
                          label: Text(t.results.preview),
                          onPressed: _showPlayer ? null : _initPlayer,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          icon: const Icon(Icons.download),
                          label: Text(t.results.download),
                          onPressed: _download,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClipMetaChip extends StatelessWidget {
  const _ClipMetaChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: cs.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            text,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
