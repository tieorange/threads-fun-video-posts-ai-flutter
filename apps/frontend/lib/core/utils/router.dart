import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../di/injection.dart';
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
String _reviewYoutubeUrl = '';
Map<String, dynamic> _reviewAiPayload = {};

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
      builder: (_, __) => _withProviders(const AnalyzeInputPage()),
    ),
    GoRoute(
      path: '/prompt',
      builder: (_, __) => _withProviders(const PromptBuilderPage()),
    ),
    GoRoute(
      path: '/paste',
      builder: (_, __) => _withProviders(const AiJsonPastePage()),
    ),
    GoRoute(
      path: '/review',
      builder: (context, state) {
        final extra = state.extra;
        if (extra is Map<String, dynamic>) {
          _reviewAiPayload = extra;
        }
        // YouTube URL comes from the analyze cubit state
        final analyzeState = _analyzeCubit.state;
        if (analyzeState is AnalyzeSuccess) {
          _reviewYoutubeUrl = analyzeState.result.video.sourceUrl;
        }
        return _withProviders(
          MomentsReviewPage(
            youtubeUrl: _reviewYoutubeUrl,
            aiPayload: _reviewAiPayload,
          ),
        );
      },
    ),
    GoRoute(
      path: '/processing',
      builder: (_, __) => _withProviders(const ProcessingPage()),
    ),
    GoRoute(
      path: '/results',
      builder: (_, __) => _withProviders(const ResultsPage()),
    ),
  ],
);
