import 'package:flutter/foundation.dart';
import 'log_buffer.dart';
import 'log_entry.dart';

class AppLogger {
  AppLogger(this._buffer);

  final LogBuffer _buffer;
  String? _currentRoute;
  String? _currentRequestId;
  String? _currentJobId;

  void setRoute(String route) => _currentRoute = route;
  void setRequestId(String? id) => _currentRequestId = id;
  void setJobId(String? id) => _currentJobId = id;

  void _emit(
    LogLevel level,
    String event,
    String message, {
    String? feature,
    required AppLayer layer,
    String? requestId,
    String? jobId,
    Map<String, dynamic>? data,
    String? stack,
    int? durationMs,
  }) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      feature: feature ?? 'video_processing',
      layer: layer,
      event: event,
      requestId: requestId ?? _currentRequestId,
      jobId: jobId ?? _currentJobId,
      route: _currentRoute,
      message: message,
      data: data,
      stack: stack,
      durationMs: durationMs,
    );
    _buffer.add(entry);
    if (kDebugMode) {
      debugPrint(entry.toString());
    }
  }

  void debug(
    String event,
    String message, {
    AppLayer layer = AppLayer.core,
    String? feature,
    String? requestId,
    String? jobId,
    Map<String, dynamic>? data,
    int? durationMs,
  }) =>
      _emit(LogLevel.debug, event, message,
          feature: feature, layer: layer, requestId: requestId, jobId: jobId, data: data, durationMs: durationMs);

  void info(
    String event,
    String message, {
    AppLayer layer = AppLayer.core,
    String? feature,
    String? requestId,
    String? jobId,
    Map<String, dynamic>? data,
    int? durationMs,
  }) =>
      _emit(LogLevel.info, event, message,
          feature: feature, layer: layer, requestId: requestId, jobId: jobId, data: data, durationMs: durationMs);

  void warn(
    String event,
    String message, {
    AppLayer layer = AppLayer.core,
    String? feature,
    String? requestId,
    String? jobId,
    Map<String, dynamic>? data,
  }) =>
      _emit(LogLevel.warn, event, message,
          feature: feature, layer: layer, requestId: requestId, jobId: jobId, data: data);

  void error(
    String event,
    String message, {
    AppLayer layer = AppLayer.core,
    String? feature,
    String? requestId,
    String? jobId,
    Map<String, dynamic>? data,
    String? stack,
  }) =>
      _emit(LogLevel.error, event, message,
          feature: feature, layer: layer, requestId: requestId, jobId: jobId, data: data, stack: stack);
}
