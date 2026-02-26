import 'log_entry.dart';

class LogBuffer {
  LogBuffer({this.maxSize = 1000});

  final int maxSize;
  final List<LogEntry> _entries = [];

  void add(LogEntry entry) {
    _entries.add(entry);
    if (_entries.length > maxSize) {
      _entries.removeAt(0);
    }
  }

  List<LogEntry> get all => List.unmodifiable(_entries);

  List<LogEntry> get errors =>
      _entries.where((e) => e.level == LogLevel.error).toList();

  List<LogEntry> get warnings =>
      _entries.where((e) => e.level == LogLevel.warn).toList();

  List<LogEntry> recent(int n) {
    final start = (_entries.length - n).clamp(0, _entries.length);
    return _entries.sublist(start);
  }

  List<LogEntry> byLayer(AppLayer layer) =>
      _entries.where((e) => e.layer == layer).toList();

  List<LogEntry> byRequestId(String requestId) =>
      _entries.where((e) => e.requestId == requestId).toList();

  List<LogEntry> byJobId(String jobId) =>
      _entries.where((e) => e.jobId == jobId).toList();

  void clear() => _entries.clear();
}
