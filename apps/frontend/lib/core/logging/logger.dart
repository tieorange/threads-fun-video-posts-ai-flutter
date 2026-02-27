import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart' as logger_pkg;

import 'log_buffer.dart';
import 'log_entry.dart';

class AppLogger {
  AppLogger(this._buffer, {this.baseUrl})
    : _prettyLogger = logger_pkg.Logger(
        printer: logger_pkg.PrettyPrinter(
          methodCount: 0,
          errorMethodCount: 5,
          lineLength: 80,
          colors: true,
          printEmojis: true,
          dateTimeFormat: logger_pkg.DateTimeFormat.none,
        ),
      );

  final LogBuffer _buffer;
  final String? baseUrl;
  final logger_pkg.Logger _prettyLogger;
  String? _currentRoute;
  String? _currentRequestId;
  String? _currentJobId;
  final String _sessionId =
      '${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}-${Random().nextInt(1 << 20).toRadixString(36)}';
  int _sequence = 0;
  bool _isLogging = false;
  final Map<String, _RepeatState> _repeatStates = <String, _RepeatState>{};

  static const Duration _repeatWindow = Duration(seconds: 4);
  static const int _repeatKeep = 4;

  void setRoute(String route) => _currentRoute = route;
  void setRequestId(String? id) => _currentRequestId = id;
  void setJobId(String? id) => _currentJobId = id;
  String? get currentRoute => _currentRoute;

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
    if (_isLogging) return;
    _isLogging = true;

    try {
      final now = DateTime.now();
      final fingerprint = _fingerprint(event, message, stack);
      final signature =
          '$level|${layer.name}|$event|$fingerprint|${_currentRoute ?? ''}';
      final repeatState = _registerRepeat(signature, now);
      if (repeatState.shouldSuppress) {
        if (repeatState.suppressed == 1 || repeatState.suppressed % 20 == 0) {
          _writeEntry(
            LogEntry(
              timestamp: now,
              level: LogLevel.warn,
              feature: feature ?? 'video_processing',
              layer: AppLayer.core,
              event: 'log_repeat_suppressed',
              requestId: requestId ?? _currentRequestId,
              jobId: jobId ?? _currentJobId,
              route: _currentRoute,
              message: 'Suppressed repeated logs for $event',
              data: {
                'originalEvent': event,
                'fingerprint': fingerprint,
                'suppressed': repeatState.suppressed,
                'windowMs': _repeatWindow.inMilliseconds,
                'sessionId': _sessionId,
              },
              sessionId: _sessionId,
              sequence: ++_sequence,
              fingerprint: 'suppressed:$fingerprint',
            ),
          );
        }
        return;
      }

      final enrichedData = <String, dynamic>{
        ...?data,
        'fingerprint': fingerprint,
        'sessionId': _sessionId,
      };
      final entry = LogEntry(
        timestamp: now,
        level: level,
        feature: feature ?? 'video_processing',
        layer: layer,
        event: event,
        requestId: requestId ?? _currentRequestId,
        jobId: jobId ?? _currentJobId,
        route: _currentRoute,
        message: message,
        data: enrichedData,
        stack: stack,
        durationMs: durationMs,
        sessionId: _sessionId,
        sequence: ++_sequence,
        fingerprint: fingerprint,
      );
      _writeEntry(entry);
    } finally {
      _isLogging = false;
    }
  }

  _RepeatState _registerRepeat(String signature, DateTime now) {
    final existing = _repeatStates[signature];
    if (existing == null ||
        now.difference(existing.windowStart) > _repeatWindow) {
      final next = _RepeatState(
        windowStart: now,
        count: 1,
        suppressed: 0,
        shouldSuppress: false,
      );
      _repeatStates[signature] = next;
      return next;
    }

    final nextCount = existing.count + 1;
    final shouldSuppress = nextCount > _repeatKeep;
    final next = _RepeatState(
      windowStart: existing.windowStart,
      count: nextCount,
      suppressed:
          shouldSuppress ? existing.suppressed + 1 : existing.suppressed,
      shouldSuppress: shouldSuppress,
    );
    _repeatStates[signature] = next;
    return next;
  }

  String _fingerprint(String event, String message, String? stack) {
    final normalizedMessage = message.trim().replaceAll(RegExp(r'\s+'), ' ');
    final stackHead =
        stack == null
            ? ''
            : stack
                .split('\n')
                .where((line) => line.trim().isNotEmpty)
                .take(3)
                .join('|');
    return '$event|$normalizedMessage|$stackHead';
  }

  void _writeEntry(LogEntry entry) {
    _buffer.add(entry);
    if (!kReleaseMode) {
      _printBeautifully(entry);
      _sendToBackend(entry);
    }
  }

  void _printBeautifully(LogEntry entry) {
    try {
      final msg = '[${entry.layer.name}] ${entry.event} — ${entry.message}';
      final stack = entry.stack;
      switch (entry.level) {
        case LogLevel.debug:
          _prettyLogger.d(msg);
        case LogLevel.info:
          _prettyLogger.i(msg);
        case LogLevel.warn:
          _prettyLogger.w(msg);
        case LogLevel.error:
          _prettyLogger.e(
            msg,
            error: entry.data,
            stackTrace: stack != null ? StackTrace.fromString(stack) : null,
          );
      }
    } catch (e) {
      debugPrint('Failed to print log beautifully: $e');
    }
  }

  Future<void> _sendToBackend(LogEntry entry) async {
    final url = baseUrl;
    if (url == null) return;
    try {
      final dio = Dio(BaseOptions(baseUrl: url));
      await dio.post('/api/v1/system/logs', data: entry.toJson());
    } catch (e) {
      debugPrint('Failed to relay log to backend: $e');
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
  }) => _emit(
    LogLevel.debug,
    event,
    message,
    feature: feature,
    layer: layer,
    requestId: requestId,
    jobId: jobId,
    data: data,
    durationMs: durationMs,
  );

  void info(
    String event,
    String message, {
    AppLayer layer = AppLayer.core,
    String? feature,
    String? requestId,
    String? jobId,
    Map<String, dynamic>? data,
    int? durationMs,
  }) => _emit(
    LogLevel.info,
    event,
    message,
    feature: feature,
    layer: layer,
    requestId: requestId,
    jobId: jobId,
    data: data,
    durationMs: durationMs,
  );

  void warn(
    String event,
    String message, {
    AppLayer layer = AppLayer.core,
    String? feature,
    String? requestId,
    String? jobId,
    Map<String, dynamic>? data,
  }) => _emit(
    LogLevel.warn,
    event,
    message,
    feature: feature,
    layer: layer,
    requestId: requestId,
    jobId: jobId,
    data: data,
  );

  void error(
    String event,
    String message, {
    AppLayer layer = AppLayer.core,
    String? feature,
    String? requestId,
    String? jobId,
    Map<String, dynamic>? data,
    String? stack,
  }) => _emit(
    LogLevel.error,
    event,
    message,
    feature: feature,
    layer: layer,
    requestId: requestId,
    jobId: jobId,
    data: data,
    stack: stack,
  );
}

class _RepeatState {
  const _RepeatState({
    required this.windowStart,
    required this.count,
    required this.suppressed,
    required this.shouldSuppress,
  });

  final DateTime windowStart;
  final int count;
  final int suppressed;
  final bool shouldSuppress;
}
