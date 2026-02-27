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
import '../../features/video_processing/presentation/cubits/chat_flow_cubit.dart';
import '../../features/video_processing/presentation/pages/gemini_step_page.dart';
import '../../features/video_processing/presentation/pages/moments_review_page.dart';
import '../../features/video_processing/presentation/pages/processing_page.dart';
import '../../features/video_processing/presentation/pages/results_page.dart';
import '../../features/video_processing/presentation/pages/chat_flow_page.dart';

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
late final ChatFlowCubit _chatFlowCubit;

void initCubits() {
  _analyzeCubit = sl<AnalyzeCubit>();
  _promptCubit = sl<PromptCubit>();
  _jsonPasteCubit = sl<JsonPasteCubit>();
  _reviewCubit = sl<MomentsReviewCubit>();
  _processCubit = sl<ProcessCubit>();
  _chatFlowCubit = sl<ChatFlowCubit>();
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
    BlocProvider.value(value: _chatFlowCubit),
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
        return _withProviders(const ChatFlowPage());
      },
    ),
    GoRoute(
      path: '/prompt',
      builder: (_, __) {
        _logRoute('/prompt');
        return _withProviders(const GeminiStepPage());
      },
    ),
    GoRoute(
      path: '/review',
      builder: (context, state) {
        _logRoute('/review');
        
        // Primary: Get data from ChatFlowCubit completed state
        final chatState = _chatFlowCubit.state;
        if (chatState is ChatFlowCompleted) {
          return _withProviders(MomentsReviewPage(
            youtubeUrl: chatState.youtubeUrl,
            aiPayload: chatState.aiPayload,
          ));
        }
        
        // Fallback: Try extra params (for direct navigation)
        final extra = state.extra as Map<String, dynamic>?;
        if (extra != null) {
          return _withProviders(MomentsReviewPage(
            youtubeUrl: extra['youtubeUrl'] as String,
            aiPayload: extra['aiPayload'] as Map<String, dynamic>,
          ));
        }
        
        // Guard: Missing data, redirect to start
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.go('/');
        });
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
