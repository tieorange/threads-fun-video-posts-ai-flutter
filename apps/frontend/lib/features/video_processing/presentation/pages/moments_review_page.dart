import 'dart:ui_web' as ui;
import 'package:web/web.dart' as web;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/funny_moment.dart';
import '../cubits/moments_review_cubit.dart';
import '../cubits/process_cubit.dart';
import '../../../../../core/widgets/app_shell_scaffold.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import '../../../../../i18n/strings.g.dart';

class MomentsReviewPage extends StatefulWidget {
  const MomentsReviewPage({super.key, required this.youtubeUrl, required this.aiPayload});

  final String youtubeUrl;
  final Map<String, dynamic> aiPayload;

  @override
  State<MomentsReviewPage> createState() => _MomentsReviewPageState();
}

class _MomentsReviewPageState extends State<MomentsReviewPage> {
  static const int _minMomentsToGenerate = 3;
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
    if (selected.length < _minMomentsToGenerate) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.review.minSelectionError)));
      return;
    }
    final payload = Map<String, dynamic>.from(widget.aiPayload);
    payload['moments'] = selected
        .map(
          (m) => {
            'id': m.id,
            'startSec': m.startSec,
            'endSec': m.endSec,
            'caption': m.caption,
            'postText': m.postText,
            'reason': m.reason,
          },
        )
        .toList();

    context.read<ProcessCubit>().startProcessing(widget.youtubeUrl, payload, selected);
    context.go('/processing');
  }

  @override
  Widget build(BuildContext context) {
    final videoId = _videoId(widget.youtubeUrl);

    return AppShellScaffold(
      title: t.review.title,
      leading: BackButton(onPressed: () => context.go('/paste')),
      actions: [
        BlocBuilder<MomentsReviewCubit, MomentsReviewState>(
          builder: (context, state) => TextButton(
            onPressed: state.moments.isEmpty
                ? null
                : state.selected.length == state.moments.length
                ? context.read<MomentsReviewCubit>().clearAll
                : context.read<MomentsReviewCubit>().selectAll,
            child: Text(
              state.moments.isNotEmpty && state.selected.length == state.moments.length
                  ? t.review.deselectAll
                  : t.review.selectAll,
            ),
          ),
        ),
      ],
      body: BlocBuilder<MomentsReviewCubit, MomentsReviewState>(
        builder: (context, state) {
          if (state.moments.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(t.review.noMoments, textAlign: TextAlign.center),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final crossCount = constraints.maxWidth >= 900 ? 2 : 1;

                    if (crossCount == 1) {
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        physics: const BouncingScrollPhysics(),
                        itemCount: state.moments.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _MomentCard(
                              moment: state.moments[index],
                              selected: state.isSelected(state.moments[index].id),
                              videoId: videoId,
                              iframeSrc: _iframeUrl(videoId, state.moments[index]),
                              onToggle: () => context.read<MomentsReviewCubit>().toggle(
                                state.moments[index].id,
                              ),
                              buildIframe: _buildIframe,
                            ),
                          );
                        },
                      );
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.85, // Taller cards for grid to avoid overflow
                      ),
                      itemCount: state.moments.length,
                      itemBuilder: (context, index) {
                        return _MomentCard(
                          moment: state.moments[index],
                          selected: state.isSelected(state.moments[index].id),
                          videoId: videoId,
                          iframeSrc: _iframeUrl(videoId, state.moments[index]),
                          onToggle: () =>
                              context.read<MomentsReviewCubit>().toggle(state.moments[index].id),
                          buildIframe: _buildIframe,
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

class _MomentCard extends StatefulWidget {
  const _MomentCard({
    required this.moment,
    required this.selected,
    required this.videoId,
    required this.iframeSrc,
    required this.onToggle,
    required this.buildIframe,
  });

  final FunnyMoment moment;
  final bool selected;
  final String videoId;
  final String iframeSrc;
  final VoidCallback onToggle;
  final Widget Function(String, String) buildIframe;

  @override
  State<_MomentCard> createState() => _MomentCardState();
}

class _MomentCardState extends State<_MomentCard> {
  bool _showPreview = false;

  @override
  Widget build(BuildContext context) {
    final frameId = 'yt_${widget.moment.id}';

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: widget.selected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: widget.selected
            ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              children: [
                if (_showPreview)
                  widget.buildIframe(frameId, widget.iframeSrc)
                else
                  GestureDetector(
                    onTap: () => setState(() => _showPreview = true),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          'https://img.youtube.com/vi/${widget.videoId}/0.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.black,
                            child: const Center(
                              child: Icon(Icons.video_library, color: Colors.white24, size: 48),
                            ),
                          ),
                        ),
                        Container(color: Colors.black26),
                        const Center(
                          child: Icon(Icons.play_circle_fill, size: 64, color: Colors.white),
                        ),
                        Positioned(
                          bottom: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${widget.moment.startSec.toStringAsFixed(0)}s',
                              style: const TextStyle(color: Colors.white, fontSize: 11),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: _SelectionBadge(selected: widget.selected, onTap: widget.onToggle),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.moment.caption,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.moment.startSec.toStringAsFixed(0)}s – ${widget.moment.endSec.toStringAsFixed(0)}s  •  ${t.review.clipDuration(duration: (widget.moment.endSec - widget.moment.startSec).toStringAsFixed(0))}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(widget.moment.postText, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
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
    final badge = GestureDetector(
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

    return PointerInterceptor(child: badge);
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
  static const int _minMomentsToGenerate = 3;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            Text(
              t.review.selectedInfo(selected: selectedCount, total: totalCount),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: selectedCount >= _minMomentsToGenerate ? onGenerate : null,
              icon: const Icon(Icons.auto_awesome),
              label: Text(t.review.generate(count: selectedCount)),
            ),
          ],
        ),
      ),
    );
  }
}
