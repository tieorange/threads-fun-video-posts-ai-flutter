import 'package:dio/dio.dart';
import '../dtos/analyze_response_dto.dart';
import '../dtos/job_status_dto.dart';

class VideoRemoteDatasource {
  VideoRemoteDatasource(this._dio);

  final Dio _dio;

  Future<AnalyzeResponseDto> analyzeVideo(String url, String language) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/videos/analyze',
      data: {'youtubeUrl': url, 'language': language},
    );
    return AnalyzeResponseDto.fromJson(response.data!);
  }

  Future<String> submitProcess(
    String youtubeUrl,
    Map<String, dynamic> aiPayload,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/videos/process',
      data: {'youtubeUrl': youtubeUrl, 'aiPayload': aiPayload},
    );
    return response.data!['jobId'] as String;
  }

  Future<JobStatusDto> getJobStatus(String jobId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/videos/process/$jobId',
    );
    return JobStatusDto.fromJson(response.data!);
  }
}
