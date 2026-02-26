import 'package:fpdart/fpdart.dart';
import '../../../../core/failures/failure.dart';
import '../entities/analyze_result.dart';
import '../repositories/video_repository.dart';

class AnalyzeVideoUseCase {
  const AnalyzeVideoUseCase(this._repository);

  final IVideoRepository _repository;

  Future<Either<Failure, AnalyzeResult>> call(String url, String language) =>
      _repository.analyzeVideo(url, language);
}
