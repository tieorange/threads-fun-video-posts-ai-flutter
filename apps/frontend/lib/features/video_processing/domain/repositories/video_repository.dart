import 'package:fpdart/fpdart.dart';
import '../../../../core/failures/failure.dart';
import '../entities/analyze_result.dart';

abstract interface class IVideoRepository {
  Future<Either<Failure, AnalyzeResult>> analyzeVideo(
    String url,
    String language,
  );
}
