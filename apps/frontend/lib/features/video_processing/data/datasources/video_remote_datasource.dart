import 'dart:math';
import 'package:dio/dio.dart';
import '../../../../core/logging/logger.dart';
import '../../../../core/logging/log_entry.dart';
import '../dtos/analyze_response_dto.dart';
import '../dtos/job_status_dto.dart';

class VideoRemoteDatasource {
  VideoRemoteDatasource(this._dio, this._log);

  final Dio _dio;
  final AppLogger _log;
  final Random _random = Random();

  Map<String, dynamic> _payloadSummary(Map<String, dynamic> aiPayload) {
    final rawMoments = aiPayload['moments'];
    final moments = rawMoments is List ? rawMoments : const [];
    final ids = moments
        .whereType<Map>()
        .map((m) => m['id'])
        .whereType<String>()
        .take(5)
        .toList();
    return {
      'language': aiPayload['language'],
      'videoTitleLength': (aiPayload['videoTitle'] as String?)?.length ?? 0,
      'momentCount': moments.length,
      'sampleMomentIds': ids,
    };
  }

  Map<String, dynamic> _extractServerError(DioException e) {
    final responseData = e.response?.data;
    if (responseData is Map<String, dynamic>) {
      final details = responseData['details'];
      return {
        'statusCode': e.response?.statusCode,
        'code': responseData['code'],
        'message': responseData['message'],
        'details': details,
      };
    }
    return {
      'statusCode': e.response?.statusCode,
      'message': e.message,
      'rawResponseType': responseData.runtimeType.toString(),
    };
  }

  String _newCorrelationId() {
    final ts = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    // Keep bound web-safe: Flutter web can fail on large nextInt() limits.
    final rnd = _random.nextInt(0x7fffffff).toRadixString(36);
    return 'fe-$ts-$rnd';
  }

  String? _responseRequestId(Response<dynamic>? response) {
    if (response == null) return null;
    final byCanonical = response.headers.value('x-request-id');
    if (byCanonical != null && byCanonical.isNotEmpty) return byCanonical;
    return response.headers.value('x-correlation-id');
  }

  Future<AnalyzeResponseDto> analyzeVideo(String url, String language) async {
    final start = DateTime.now().millisecondsSinceEpoch;
    final requestId = _newCorrelationId();
    _log.info('http_analyze_start', 'POST /api/v1/videos/analyze',
        layer: AppLayer.data,
        requestId: requestId,
        data: {'url': url, 'language': language});
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/videos/analyze',
        data: {'youtubeUrl': url, 'language': language},
        options: Options(
          headers: {
            'x-request-id': requestId,
            'x-client-request-id': requestId,
          },
        ),
      );
      final serverRequestId = _responseRequestId(response);
      _log.info('http_analyze_done', 'Analyze response received',
          layer: AppLayer.data,
          requestId: requestId,
          durationMs: DateTime.now().millisecondsSinceEpoch - start,
          data: {
            'status': response.statusCode,
            'serverRequestId': serverRequestId,
          });
      return AnalyzeResponseDto.fromJson(response.data!);
    } on DioException catch (e) {
      _log.error('http_analyze_failed', e.message ?? 'Dio error',
          layer: AppLayer.data,
          requestId: requestId,
          data: {
            ..._extractServerError(e),
            'url': url,
            'serverRequestId': _responseRequestId(e.response),
          });
      rethrow;
    }
  }

  Future<String> submitProcess(
    String youtubeUrl,
    Map<String, dynamic> aiPayload,
  ) async {
    final start = DateTime.now().millisecondsSinceEpoch;
    final requestId = _newCorrelationId();
    _log.info('http_process_start', 'POST /api/v1/videos/process',
        layer: AppLayer.data,
        requestId: requestId,
        data: {'url': youtubeUrl, 'payloadSummary': _payloadSummary(aiPayload)});
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/videos/process',
        data: {'youtubeUrl': youtubeUrl, 'aiPayload': aiPayload},
        options: Options(
          headers: {
            'x-request-id': requestId,
            'x-client-request-id': requestId,
          },
        ),
      );
      final jobId = response.data!['jobId'] as String;
      final serverRequestId = _responseRequestId(response);
      _log.info('http_process_done', 'Process job queued',
          layer: AppLayer.data,
          requestId: requestId,
          durationMs: DateTime.now().millisecondsSinceEpoch - start,
          jobId: jobId,
          data: {'serverRequestId': serverRequestId});
      return jobId;
    } on DioException catch (e) {
      _log.error('http_process_failed', e.message ?? 'Dio error',
          layer: AppLayer.data,
          requestId: requestId,
          data: {
            ..._extractServerError(e),
            'serverRequestId': _responseRequestId(e.response),
          });
      rethrow;
    }
  }

  Future<JobStatusDto> getJobStatus(String jobId) async {
    final requestId = _newCorrelationId();
    _log.debug('http_job_status_start', 'GET /api/v1/videos/process/$jobId',
        layer: AppLayer.data, requestId: requestId, jobId: jobId);
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/videos/process/$jobId',
        queryParameters: {
          // Prevent browser/proxy cache from turning polls into stale 304 loops.
          '_ts': DateTime.now().millisecondsSinceEpoch,
        },
        options: Options(
          headers: {
            'x-request-id': requestId,
            'x-client-request-id': requestId,
          },
        ),
      );
      final dto = JobStatusDto.fromJson(response.data!);
      final serverRequestId = _responseRequestId(response);
      _log.debug('http_job_status_done', 'Status: ${dto.status} (${dto.progress}%)',
          layer: AppLayer.data,
          requestId: requestId,
          jobId: jobId,
          data: {'status': dto.status, 'progress': dto.progress, 'serverRequestId': serverRequestId});
      return dto;
    } on DioException catch (e) {
      _log.error('http_job_status_failed', e.message ?? 'Dio error',
          layer: AppLayer.data,
          requestId: requestId,
          jobId: jobId,
          data: {
            ..._extractServerError(e),
            'serverRequestId': _responseRequestId(e.response),
          });
      rethrow;
    }
  }
}
