import 'dart:ui_web' as ui;
import 'package:web/web.dart' as web;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/funny_moment.dart';
import '../cubits/moments_review_cubit.dart';
import '../cubits/process_cubit.dart';
import '../../../../../core/widgets/app_shell_scaffold.dart';

class MomentsReviewPage extends StatefulWidget {
  const MomentsReviewPage({super.key, required this.youtubeUrl, required this.aiPayload});

  final String youtubeUrl;
  final Map<String, dynamic> aiPayload;

  @override
  State<MomentsReviewPage> createState() => _MomentsReviewPageState();
}

class _MomentsReviewPageState extends State<MomentsReviewPage> {
  final _registeredFrames = <String>{};

  String _videoId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return '';
    if (uri.host.contains('youtu.be')) return uri.pathSegments.first;
    return uri.queryParameters['v'] ?? '';
  }

  String _iframeUrl(String videoId, FunnyMoment moment) {
    final start = moment.startSec.floor();
    final end = moment.endSec.ceil();
    return 'https://www.youtube.com/embed/$videoId?start=$start&end=$end&autoplay=0&rel=0';
  }

  Widget _buildIframe(String frameId, String iframeSrc) {
    if (!_registeredFrames.contains(frameId)) {
      _registeredFrames.add(frameId);
      // ignore: undefined_prefixed_name
      ui.platformViewRegistry.registerViewFactory(frameId, (int _) {
        final iframe = web.HTMLIFrameElement();
        iframe.src = iframeSrc;
        iframe.style.border = 'none';
        iframe.style.width = '100%';
        iframe.style.height = '100%';
        iframe.allowFullscreen = true;
        iframe.setAttribute(
          'allow',
          'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture',
        );
        return iframe;
      });
    }
    return HtmlElementView(viewType: frameId);
  }

  void _generate() {
    final selected = context.read<MomentsReviewCubit>().state.selectedMoments;
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one moment to generate.')),
      );
      return;
    }
    final payload = Map<String, dynamic>.from(widget.aiPayload);
    payload['moments'] = selected
        .map((m) => {
              'id': m.id,
              'startSec': m.startSec,
              'endSec': m.endSec,
              'caption': m.caption,
              'postText': m.postText,
              'reason': m.reason,
            })
        .toList();

    context.read<ProcessCubit>().startProcessing(
          widget.youtubeUrl,
          payload,
          selected,
        );
    context.go('/processing');
  }

  @override
  Widget build(BuildContext context) {
    final videoId = _videoId(widget.youtubeUrl);

    return AppShellScaffold(
      title: 'Review Moments',
      leading: BackButton(onPressed: () => context.go('/paste')),
      actions: [
        BlocBuilder<MomentsReviewCubit, MomentsReviewState>(
          builder: (context, state) => TextButton(
            onPressed: state.selected.length == state.moments.length
                ? context.read<MomentsReviewCubit>().clearAll
                : context.read<MomentsReviewCubit>().selectAll,
            child: Text(
              state.selected.length == state.moments.length
                  ? 'Deselect All'
                  : 'Select All',
            ),
          ),
        ),
      ],
      body: BlocBuilder<MomentsReviewCubit, MomentsReviewState>(
        builder: (context, state) {
          return Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final crossCount = constraints.maxWidth >= 900 ? 2 : 1;
                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossCount,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: crossCount == 2 ? 1.1 : 1.5,
                      ),
                      itemCount: state.moments.length,
                      itemBuilder: (context, index) {
                        final moment = state.moments[index];
                        final selected = state.isSelected(moment.id);
                        final frameId = 'yt_${moment.id}';
                        final iframeSrc = _iframeUrl(videoId, moment);

                        return Card(
                          clipBehavior: Clip.antiAlias,
                          elevation: selected ? 4 : 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: selected
                                ? BorderSide(
                                    color: Theme.of(context).colorScheme.primary,
                                    width: 2,
                                  )
                                : BorderSide.none,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Stack(
                                  children: [
                                    _buildIframe(frameId, iframeSrc),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: _SelectionBadge(
                                        selected: selected,
                                        onTap: () => context
                                            .read<MomentsReviewCubit>()
                                            .toggle(moment.id),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        moment.caption,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(fontWeight: FontWeight.bold),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${moment.startSec.toStringAsFixed(0)}s – ${moment.endSec.toStringAsFixed(0)}s  •  ${(moment.endSec - moment.startSec).toStringAsFixed(0)}s clip',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        moment.postText,
                                        style:
                                            Theme.of(context).textTheme.bodySmall,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              _BottomBar(
                selectedCount: state.selected.length,
                totalCount: state.moments.length,
                onGenerate: _generate,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SelectionBadge extends StatelessWidget {
  const _SelectionBadge({required this.selected, required this.onTap});
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
            width: 2,
          ),
        ),
        child: Icon(
          selected ? Icons.check : Icons.add,
          size: 16,
          color: selected
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.selectedCount,
    required this.totalCount,
    required this.onGenerate,
  });
  final int selectedCount;
  final int totalCount;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            Text(
              '$selectedCount of $totalCount selected',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: selectedCount > 0 ? onGenerate : null,
              icon: const Icon(Icons.auto_awesome),
              label: Text('Generate $selectedCount Post${selectedCount == 1 ? '' : 's'}'),
            ),
          ],
        ),
      ),
    );
  }
}
