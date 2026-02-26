part of 'analyze_cubit.dart';

sealed class AnalyzeState {
  const AnalyzeState();
}

final class AnalyzeInitial extends AnalyzeState {
  const AnalyzeInitial();
}

final class AnalyzeLoading extends AnalyzeState {
  const AnalyzeLoading();
}

final class AnalyzeSuccess extends AnalyzeState {
  const AnalyzeSuccess(this.result);
  final AnalyzeResult result;
}

final class AnalyzeFailure extends AnalyzeState {
  const AnalyzeFailure(this.message);
  final String message;
}
