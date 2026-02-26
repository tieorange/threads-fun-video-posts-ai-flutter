import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/analyze_result.dart';
import '../../domain/usecases/analyze_video_usecase.dart';

part 'analyze_state.dart';

class AnalyzeCubit extends Cubit<AnalyzeState> {
  AnalyzeCubit(this._analyzeVideoUseCase) : super(const AnalyzeInitial());

  final AnalyzeVideoUseCase _analyzeVideoUseCase;

  Future<void> analyze(String url, String language) async {
    emit(const AnalyzeLoading());
    final result = await _analyzeVideoUseCase(url, language);
    result.fold(
      (failure) => emit(AnalyzeFailure(failure.message)),
      (analyzeResult) => emit(AnalyzeSuccess(analyzeResult)),
    );
  }

  void reset() => emit(const AnalyzeInitial());
}
