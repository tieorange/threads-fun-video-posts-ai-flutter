import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../domain/entities/clip_artifact.dart';
import '../../domain/entities/funny_moment.dart';
import '../cubits/process_cubit.dart';
import '../cubits/analyze_cubit.dart';
import '../../../../../core/widgets/app_shell_scaffold.dart';

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
      title: 'Your Clips',
      leading: BackButton(
        onPressed: () {
          context.read<AnalyzeCubit>().reset();
          context.read<ProcessCubit>().reset();
          context.go('/');
        },
      ),
      actions: [
        IconButton(
          tooltip: 'Start over',
          icon: const Icon(Icons.refresh),
          onPressed: () {
            context.read<AnalyzeCubit>().reset();
            context.read<ProcessCubit>().reset();
            context.go('/');
          },
        ),
      ],
      body: jobStatus.clips.isEmpty
          ? const Center(child: Text('No clips were generated.'))
          : LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 720;
                return ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: wide ? 48 : 16, vertical: 16),
                  itemCount: jobStatus.clips.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final clip = jobStatus.clips[index];
                    final moment = moments[clip.momentId];
                    return _ClipCard(clip: clip, moment: moment);
                  },
                );
              },
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

  Future<void> _initPlayer() async {
    setState(() => _showPlayer = true);
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
      autoPlay: true,
      looping: false,
    );
    setState(() {
      _controller = controller;
      _chewie = chewie;
      _playerReady = true;
    });
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
    final uri = Uri.parse('$baseUrl${widget.clip.downloadUrl}?download=1');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _copyPostText() async {
    final text = widget.moment?.postText ?? '';
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Post text copied!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final moment = widget.moment;
    final cs = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Video player / preview
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
                          Icon(Icons.play_circle_outline, size: 56, color: cs.primary),
                          const SizedBox(height: 8),
                          Text('Tap to preview', style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (moment != null) ...[
                  Text(
                    moment.caption,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${moment.startSec.toStringAsFixed(0)}s – ${moment.endSec.toStringAsFixed(0)}s  •  ${(moment.endSec - moment.startSec).toStringAsFixed(0)}s',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  // Post text box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            moment.postText,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          tooltip: 'Copy post text',
                          icon: const Icon(Icons.copy, size: 18),
                          onPressed: _copyPostText,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // Action row
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Preview'),
                        onPressed: _showPlayer ? null : _initPlayer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.download),
                        label: const Text('Download'),
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
