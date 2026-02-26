import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/analyze_result.dart';
import '../../domain/usecases/analyze_video_usecase.dart';
import '../../../../../core/logging/log_entry.dart';
import '../../../../../core/logging/logger.dart';

part 'analyze_state.dart';

class AnalyzeCubit extends Cubit<AnalyzeState> {
  AnalyzeCubit(this._analyzeVideoUseCase, this._log) : super(const AnalyzeInitial());

  final AnalyzeVideoUseCase _analyzeVideoUseCase;
  final AppLogger _log;

  Future<void> analyze(String url, String language) async {
    _log.info('analyze_start', 'Analyzing video', layer: AppLayer.presentation, data: {'url': url, 'language': language});
    emit(const AnalyzeLoading());
    final result = await _analyzeVideoUseCase(url, language);
    result.fold(
      (failure) {
        _log.error('analyze_failure', failure.message, layer: AppLayer.presentation, data: {'url': url});
        emit(AnalyzeFailure(failure.message));
      },
      (analyzeResult) {
        _log.info('analyze_success', 'Analyze succeeded', layer: AppLayer.presentation,
            data: {'videoId': analyzeResult.video.videoId, 'transcriptSegments': analyzeResult.transcript.length});
        emit(AnalyzeSuccess(analyzeResult));
      },
    );
  }

  void reset() => emit(const AnalyzeInitial());
}
