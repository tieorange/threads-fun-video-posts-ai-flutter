import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../di/injection.dart';
import '../logging/log_entry.dart';
import '../logging/logger.dart';
import '../../features/video_processing/presentation/cubits/analyze_cubit.dart';
import '../../features/video_processing/presentation/cubits/prompt_cubit.dart';
import '../../features/video_processing/presentation/cubits/json_paste_cubit.dart';
import '../../features/video_processing/presentation/cubits/moments_review_cubit.dart';
import '../../features/video_processing/presentation/cubits/process_cubit.dart';
import '../../features/video_processing/presentation/pages/analyze_input_page.dart';
import '../../features/video_processing/presentation/pages/prompt_builder_page.dart';
import '../../features/video_processing/presentation/pages/ai_json_paste_page.dart';
import '../../features/video_processing/presentation/pages/moments_review_page.dart';
import '../../features/video_processing/presentation/pages/processing_page.dart';
import '../../features/video_processing/presentation/pages/results_page.dart';

void _logRoute(String path) {
  final log = sl<AppLogger>();
  log.setRoute(path);
  log.info('route_enter', 'Navigated to $path', layer: AppLayer.presentation);
}

// Shared cubit instances that persist across route transitions
late final AnalyzeCubit _analyzeCubit;
late final PromptCubit _promptCubit;
late final JsonPasteCubit _jsonPasteCubit;
late final MomentsReviewCubit _reviewCubit;
late final ProcessCubit _processCubit;

void initCubits() {
  _analyzeCubit = sl<AnalyzeCubit>();
  _promptCubit = sl<PromptCubit>();
  _jsonPasteCubit = sl<JsonPasteCubit>();
  _reviewCubit = sl<MomentsReviewCubit>();
  _processCubit = sl<ProcessCubit>();
}

// Extra data passed via GoRouter for the review page
// Data is extracted from state.extra or cubit states during build.

Widget _withProviders(Widget child) => MultiBlocProvider(
  providers: [
    BlocProvider.value(value: _analyzeCubit),
    BlocProvider.value(value: _promptCubit),
    BlocProvider.value(value: _jsonPasteCubit),
    BlocProvider.value(value: _reviewCubit),
    BlocProvider.value(value: _processCubit),
  ],
  child: child,
);

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) {
        _logRoute('/');
        return _withProviders(const AnalyzeInputPage());
      },
    ),
    GoRoute(
      path: '/prompt',
      builder: (_, __) {
        _logRoute('/prompt');
        return _withProviders(const PromptBuilderPage());
      },
    ),
    GoRoute(
      path: '/paste',
      builder: (_, __) {
        _logRoute('/paste');
        return _withProviders(const AiJsonPastePage());
      },
    ),
    GoRoute(
      path: '/review',
      builder: (context, state) {
        _logRoute('/review');
        final extra = state.extra;

        // Try to get payload from extra (direct navigation) or persisted cubit state (refresh)
        final aiPayload = extra is Map<String, dynamic> ? extra : _reviewCubit.state.aiPayload;

        // YouTube URL comes from the analyze cubit state
        final analyzeState = _analyzeCubit.state;
        final youtubeUrl = analyzeState is AnalyzeSuccess
            ? analyzeState.result.video.sourceUrl
            : null;

        if (aiPayload == null || youtubeUrl == null) {
          // Guard: if data is missing (e.g. direct nav or stale), go back to start
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/');
          });
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        return _withProviders(MomentsReviewPage(youtubeUrl: youtubeUrl, aiPayload: aiPayload));
      },
    ),
    GoRoute(
      path: '/processing',
      builder: (_, __) {
        _logRoute('/processing');
        return _withProviders(const ProcessingPage());
      },
    ),
    GoRoute(
      path: '/results',
      builder: (_, __) {
        _logRoute('/results');
        return _withProviders(const ResultsPage());
      },
    ),
  ],
);
