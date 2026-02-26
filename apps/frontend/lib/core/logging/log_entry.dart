enum LogLevel { debug, info, warn, error }

enum AppLayer { presentation, domain, data, infrastructure, core }

class LogEntry {
  const LogEntry({
    required this.timestamp,
    required this.level,
    required this.feature,
    required this.layer,
    required this.event,
    this.requestId,
    this.jobId,
    this.route,
    required this.message,
    this.data,
    this.stack,
    this.durationMs,
  });

  final DateTime timestamp;
  final LogLevel level;
  final String feature;
  final AppLayer layer;
  final String event;
  final String? requestId;
  final String? jobId;
  final String? route;
  final String message;
  final Map<String, dynamic>? data;
  final String? stack;
  final int? durationMs;

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'level': level.name,
        'app': 'frontend',
        'feature': feature,
        'layer': layer.name,
        'event': event,
        if (requestId != null) 'requestId': requestId,
        if (jobId != null) 'jobId': jobId,
        if (route != null) 'route': route,
        'message': message,
        if (data != null) 'data': data,
        if (stack != null) 'stack': stack,
        if (durationMs != null) 'durationMs': durationMs,
      };

  @override
  String toString() {
    final lvl = level.name.toUpperCase().padRight(5);
    final rid = requestId != null ? ' rid=${requestId!.substring(0, requestId!.length.clamp(0, 8))}' : '';
    final jid = jobId != null ? ' job=$jobId' : '';
    final dur = durationMs != null ? ' ${durationMs}ms' : '';
    return '[${timestamp.toIso8601String()}] $lvl [${layer.name}] $event$rid$jid$dur — $message';
  }
}
