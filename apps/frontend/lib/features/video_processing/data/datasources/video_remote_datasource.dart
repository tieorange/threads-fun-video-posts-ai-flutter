import 'package:dio/dio.dart';
import '../../../../core/logging/logger.dart';
import '../../../../core/logging/log_entry.dart';
import '../dtos/analyze_response_dto.dart';
import '../dtos/job_status_dto.dart';

class VideoRemoteDatasource {
  VideoRemoteDatasource(this._dio, this._log);

  final Dio _dio;
  final AppLogger _log;

  Future<AnalyzeResponseDto> analyzeVideo(String url, String language) async {
    final start = DateTime.now().millisecondsSinceEpoch;
    _log.info('http_analyze_start', 'POST /api/v1/videos/analyze',
        layer: AppLayer.data, data: {'url': url, 'language': language});
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/videos/analyze',
        data: {'youtubeUrl': url, 'language': language},
      );
      _log.info('http_analyze_done', 'Analyze response received',
          layer: AppLayer.data,
          durationMs: DateTime.now().millisecondsSinceEpoch - start,
          data: {'status': response.statusCode});
      return AnalyzeResponseDto.fromJson(response.data!);
    } on DioException catch (e) {
      _log.error('http_analyze_failed', e.message ?? 'Dio error',
          layer: AppLayer.data,
          data: {'statusCode': e.response?.statusCode, 'url': url});
      rethrow;
    }
  }

  Future<String> submitProcess(
    String youtubeUrl,
    Map<String, dynamic> aiPayload,
  ) async {
    final start = DateTime.now().millisecondsSinceEpoch;
    _log.info('http_process_start', 'POST /api/v1/videos/process',
        layer: AppLayer.data, data: {'url': youtubeUrl});
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/videos/process',
        data: {'youtubeUrl': youtubeUrl, 'aiPayload': aiPayload},
      );
      final jobId = response.data!['jobId'] as String;
      _log.info('http_process_done', 'Process job queued',
          layer: AppLayer.data,
          durationMs: DateTime.now().millisecondsSinceEpoch - start,
          jobId: jobId);
      return jobId;
    } on DioException catch (e) {
      _log.error('http_process_failed', e.message ?? 'Dio error',
          layer: AppLayer.data,
          data: {'statusCode': e.response?.statusCode});
      rethrow;
    }
  }

  Future<JobStatusDto> getJobStatus(String jobId) async {
    _log.debug('http_job_status_start', 'GET /api/v1/videos/process/$jobId',
        layer: AppLayer.data, jobId: jobId);
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/videos/process/$jobId',
      );
      final dto = JobStatusDto.fromJson(response.data!);
      _log.debug('http_job_status_done', 'Status: ${dto.status}',
          layer: AppLayer.data, jobId: jobId, data: {'status': dto.status});
      return dto;
    } on DioException catch (e) {
      _log.error('http_job_status_failed', e.message ?? 'Dio error',
          layer: AppLayer.data,
          jobId: jobId,
          data: {'statusCode': e.response?.statusCode});
      rethrow;
    }
  }
}
