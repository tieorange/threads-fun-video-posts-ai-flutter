import 'dart:ui_web' as ui;
import 'package:web/web.dart' as web;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/funny_moment.dart';
import '../cubits/moments_review_cubit.dart';
import '../cubits/process_cubit.dart';
import '../../../../../core/widgets/app_shell_scaffold.dart';
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
    if (uri.host.contains('youtu.be') && uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.first;
    }
    return uri.queryParameters['v'] ?? '';
  }

  String _iframeUrl(String videoId, FunnyMoment moment) {
    final start = moment.startSec.floor();
    final end = moment.endSec.ceil();
    return 'https://www.youtube.com/embed/$videoId?start=$start&end=$end&autoplay=1&rel=0';
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
    // Guard: don't submit a new job if one is already running
    final processState = context.read<ProcessCubit>().state;
    if (processState is! ProcessIdle) {
      // If job done, just go to results; if still running go back to processing
      if (processState is ProcessDone) {
        context.go('/results');
      } else {
        context.go('/processing');
      }
      return;
    }

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

  String _selectedInfoText(int selected, int total) {
    return t.review.selectedInfo
        .replaceFirst('{selected}', selected.toString())
        .replaceFirst('{total}', total.toString());
  }

  String _generateText(int selected) {
    return t.review.generate.replaceFirst('{count}', selected.toString());
  }

  @override
  Widget build(BuildContext context) {
    final videoId = _videoId(widget.youtubeUrl);
    final isCompact = MediaQuery.sizeOf(context).width < 640;

    return AppShellScaffold(
      title: t.review.title,
      leading: BackButton(onPressed: () => context.go('/')),
      actions: [
        if (!isCompact)
          BlocBuilder<MomentsReviewCubit, MomentsReviewState>(
            builder: (context, state) {
              final allSelected =
                  state.moments.isNotEmpty && state.selected.length == state.moments.length;
              return TextButton(
                onPressed: state.moments.isEmpty
                    ? null
                    : allSelected
                    ? context.read<MomentsReviewCubit>().clearAll
                    : context.read<MomentsReviewCubit>().selectAll,
                child: Text(allSelected ? t.review.deselectAll : t.review.selectAll),
              );
            },
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

          final allSelected = state.selected.length == state.moments.length;

          return Column(
            children: [
              _SelectionSummaryBar(
                selectedCount: state.selected.length,
                totalCount: state.moments.length,
                selectedInfoText: _selectedInfoText(state.selected.length, state.moments.length),
                allSelected: allSelected,
                onToggleAll: allSelected
                    ? context.read<MomentsReviewCubit>().clearAll
                    : context.read<MomentsReviewCubit>().selectAll,
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final crossCount = constraints.maxWidth >= 920 ? 2 : 1;
                    final listBottomPadding = isCompact ? 156.0 : 120.0;

                    if (crossCount == 1) {
                      return ListView.builder(
                        padding: EdgeInsets.fromLTRB(16, 12, 16, listBottomPadding),
                        physics: const BouncingScrollPhysics(),
                        itemCount: state.moments.length,
                        itemBuilder: (context, index) {
                          final moment = state.moments[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _MomentCard(
                              moment: moment,
                              selected: state.isSelected(moment.id),
                              videoId: videoId,
                              iframeSrc: _iframeUrl(videoId, moment),
                              onToggle: () => context.read<MomentsReviewCubit>().toggle(moment.id),
                              buildIframe: _buildIframe,
                            ),
                          );
                        },
                      );
                    }

                    return GridView.builder(
                      padding: EdgeInsets.fromLTRB(16, 12, 16, listBottomPadding),
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.86,
                      ),
                      itemCount: state.moments.length,
                      itemBuilder: (context, index) {
                        final moment = state.moments[index];
                        return _MomentCard(
                          moment: moment,
                          selected: state.isSelected(moment.id),
                          videoId: videoId,
                          iframeSrc: _iframeUrl(videoId, moment),
                          onToggle: () => context.read<MomentsReviewCubit>().toggle(moment.id),
                          buildIframe: _buildIframe,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: BlocBuilder<MomentsReviewCubit, MomentsReviewState>(
        builder: (context, reviewState) {
          return BlocBuilder<ProcessCubit, ProcessState>(
            builder: (context, processState) {
              final isProcessing = processState is! ProcessIdle;
              return _BottomBar(
                selectedCount: reviewState.selected.length,
                totalCount: reviewState.moments.length,
                generateText: _generateText(reviewState.selected.length),
                selectedInfoText: _selectedInfoText(
                  reviewState.selected.length,
                  reviewState.moments.length,
                ),
                onGenerate: isProcessing ? null : _generate,
                isProcessingActive: isProcessing,
              );
            },
          );
        },
      ),
    );
  }
}

class _SelectionSummaryBar extends StatelessWidget {
  const _SelectionSummaryBar({
    required this.selectedCount,
    required this.totalCount,
    required this.selectedInfoText,
    required this.allSelected,
    required this.onToggleAll,
  });

  final int selectedCount;
  final int totalCount;
  final String selectedInfoText;
  final bool allSelected;
  final VoidCallback onToggleAll;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.35))),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Chip(
            avatar: Icon(Icons.checklist_rounded, size: 18, color: cs.primary),
            label: Text(selectedInfoText),
          ),
          OutlinedButton.icon(
            onPressed: totalCount == 0 ? null : onToggleAll,
            icon: Icon(allSelected ? Icons.clear_all : Icons.done_all),
            label: Text(allSelected ? t.review.deselectAll : t.review.selectAll),
          ),
          if (selectedCount < 1)
            Text(
              t.review.minSelectionError,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
        ],
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
  bool _expandedPostText = false;

  @override
  Widget build(BuildContext context) {
    final frameId = 'yt_${widget.moment.id}';
    final cs = Theme.of(context).colorScheme;
    final durationSec = (widget.moment.endSec - widget.moment.startSec).toStringAsFixed(0);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: widget.selected ? 3 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: widget.selected ? cs.primary : cs.outlineVariant.withValues(alpha: 0.55),
          width: widget.selected ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_showPreview)
                  widget.buildIframe(frameId, widget.iframeSrc)
                else
                  InkWell(
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
                        Container(
                          color: Colors.black45,
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.play_circle_fill, size: 66, color: Colors.white),
                              const SizedBox(height: 8),
                              Text(
                                t.review.tapToLoadPreview,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                Positioned(
                  left: 10,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${widget.moment.startSec.toStringAsFixed(0)}s → ${widget.moment.endSec.toStringAsFixed(0)}s',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        widget.moment.caption,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: widget.selected ? cs.primary : cs.surfaceContainerHigh,
                        foregroundColor: widget.selected ? cs.onPrimary : cs.onSurface,
                        minimumSize: const Size(40, 40),
                      ),
                      onPressed: widget.onToggle,
                      icon: Icon(widget.selected ? Icons.check : Icons.add),
                      tooltip: widget.selected ? t.review.deselectMoment : t.review.selectMoment,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetaChip(icon: Icons.timer_outlined, text: '$durationSec s'),
                    _MetaChip(
                      icon: Icons.content_cut,
                      text: t.review.clipDuration.replaceFirst('{duration}', durationSec),
                    ),
                    if (widget.selected)
                      _MetaChip(
                        icon: Icons.check_circle,
                        text: t.review.selected,
                        highlighted: true,
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 170),
                  crossFadeState: _expandedPostText
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: Text(
                    widget.moment.postText,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  secondChild: Text(
                    widget.moment.postText,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => setState(() => _expandedPostText = !_expandedPostText),
                    child: Text(_expandedPostText ? t.review.showLess : t.review.showMore),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.text, this.highlighted = false});

  final IconData icon;
  final String text;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: highlighted ? cs.primaryContainer : cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: highlighted ? cs.onPrimaryContainer : cs.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            text,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: highlighted ? cs.onPrimaryContainer : cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.selectedCount,
    required this.totalCount,
    required this.generateText,
    required this.selectedInfoText,
    required this.onGenerate,
  });

  final int selectedCount;
  final int totalCount;
  final String generateText;
  final String selectedInfoText;
  final VoidCallback onGenerate;
  static const int _minMomentsToGenerate = 3;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surface,
      elevation: 8,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(selectedInfoText, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: selectedCount >= _minMomentsToGenerate ? onGenerate : null,
                icon: const Icon(Icons.auto_awesome),
                label: Text(totalCount == 0 ? t.review.generateDisabled : generateText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
