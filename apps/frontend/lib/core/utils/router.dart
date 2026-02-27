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

// Global cubit access via sl() instead of late final wrappers
void initCubits() {
  // Just pre-initialize ChatFlowCubit to trigger restoration
  sl<ChatFlowCubit>();
}

Widget _withProviders(Widget child) => MultiBlocProvider(
  providers: [
    BlocProvider.value(value: sl<AnalyzeCubit>()),
    BlocProvider.value(value: sl<PromptCubit>()),
    BlocProvider.value(value: sl<JsonPasteCubit>()),
    BlocProvider.value(value: sl<MomentsReviewCubit>()),
    BlocProvider.value(value: sl<ProcessCubit>()),
    BlocProvider.value(value: sl<ChatFlowCubit>()),
  ],
  child: child,
);

final appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final chatFlow = sl<ChatFlowCubit>();
    final chatState = chatFlow.state;
    final path = state.uri.path;
    final log = sl<AppLogger>();

    // Guard: /review requires completed state
    if (path == '/review' && chatState is! ChatFlowCompleted) {
      log.warn(
        'route_guard_review_redirect',
        'Redirected from /review to / due to incomplete chat state',
        layer: AppLayer.presentation,
        data: {'chatState': chatState.runtimeType.toString()},
      );
      // If we are still in a transient state or initial, redirect to home
      // But wait! If we just started, ChatFlowCubit might be restoring.
      // However, restoreState is called in constructor and is synchronous for localStorage.
      return '/';
    }

    // Guard: /processing and /results require active process
    if ((path == '/processing' || path == '/results') &&
        sl<ProcessCubit>().state is ProcessIdle) {
      log.warn(
        'route_guard_process_redirect',
        'Redirected due to idle process state',
        layer: AppLayer.presentation,
        data: {'path': path},
      );
      return '/';
    }

    return null;
  },
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

        final chatState = sl<ChatFlowCubit>().state;
        if (chatState is ChatFlowCompleted) {
          return _withProviders(
            MomentsReviewPage(
              youtubeUrl: chatState.youtubeUrl,
              aiPayload: chatState.aiPayload,
            ),
          );
        }

        // This fallback should rarely be hit due to redirect guard
        return _withProviders(const ChatFlowPage());
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
