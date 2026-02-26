import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/failures/failure.dart';
import '../../domain/entities/analyze_result.dart';
import '../../domain/repositories/video_repository.dart';
import '../datasources/video_remote_datasource.dart';

class VideoRepositoryImpl implements IVideoRepository {
  const VideoRepositoryImpl(this._datasource);

  final VideoRemoteDatasource _datasource;

  @override
  Future<Either<Failure, AnalyzeResult>> analyzeVideo(
    String url,
    String language,
  ) async {
    try {
      final dto = await _datasource.analyzeVideo(url, language);
      return right(dto.toDomain());
    } on DioException catch (e) {
      return left(_mapDioError(e));
    } catch (e) {
      return left(UnexpectedFailure(e.toString()));
    }
  }

  Failure _mapDioError(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final code = data['code'] as String?;
      final message = data['message'] as String? ?? 'Server error';
      return ServerFailure(message, code: code);
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const NetworkFailure('Connection timed out.');
    }
    return NetworkFailure(e.message ?? 'Network error');
  }
}
