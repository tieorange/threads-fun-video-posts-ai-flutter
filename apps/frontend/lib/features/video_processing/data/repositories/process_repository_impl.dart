import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/failures/failure.dart';
import '../../domain/entities/funny_moment.dart';
import '../../domain/entities/job_status.dart';
import '../../domain/repositories/process_repository.dart';
import '../datasources/video_remote_datasource.dart';

class ProcessRepositoryImpl implements IProcessRepository {
  const ProcessRepositoryImpl(this._datasource);

  final VideoRemoteDatasource _datasource;

  @override
  Future<Either<Failure, String>> submitProcess(
    String youtubeUrl,
    Map<String, dynamic> aiPayload,
  ) async {
    try {
      final jobId = await _datasource.submitProcess(youtubeUrl, aiPayload);
      return right(jobId);
    } on DioException catch (e) {
      return left(_mapDioError(e));
    } catch (e) {
      return left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, JobStatus>> getJobStatus(
    String jobId,
    List<FunnyMoment> moments,
  ) async {
    try {
      final dto = await _datasource.getJobStatus(jobId);
      return right(dto.toDomain(moments));
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
