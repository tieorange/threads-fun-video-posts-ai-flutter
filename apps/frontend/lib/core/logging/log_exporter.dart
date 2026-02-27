import 'dart:convert';
import 'log_buffer.dart';
import 'log_entry.dart';

class LogExporter {
  const LogExporter(this._buffer);

  final LogBuffer _buffer;

  String buildAiBundle() {
    final all = _buffer.all;
    final errors = _buffer.errors;
    final warnings = _buffer.warnings;
    final recent = _buffer.recent(300);
    final networkLogs = recent.where((e) => e.layer == AppLayer.data).toList();
    final stateLogs =
        recent
            .where(
              (e) =>
                  e.layer == AppLayer.presentation &&
                  (e.event.contains('state_') || e.event.contains('cubit_')),
            )
            .toList();
    final errorGroups = _groupRecurringErrors(recent);
    final suppressionLogs =
        recent.where((e) => e.event == 'log_repeat_suppressed').toList();

    final sb = StringBuffer();
    sb.writeln(
      'AI task: find root cause, point to likely layer/file, propose fix + test.',
    );
    sb.writeln();

    // Issue summary
    _section(sb, 'Issue summary');
    if (errors.isEmpty) {
      sb.writeln('No errors captured.');
    } else {
      sb.writeln('${errors.length} error(s):');
      for (final e in errors.reversed.take(5)) {
        sb.writeln('  [${e.event}] ${e.message}  (route=${e.route ?? "??"})');
        if (e.data != null) sb.writeln('    data: ${jsonEncode(e.data)}');
        final stack = e.stack;
        if (stack != null) {
          final lines = stack.split('\n').take(4).join(' | ');
          sb.writeln('    stack: $lines');
        }
      }
    }
    if (warnings.isNotEmpty) {
      sb.writeln('\n${warnings.length} warning(s):');
      for (final w in warnings.reversed.take(3)) {
        sb.writeln('  [${w.event}] ${w.message}');
      }
    }

    _section(sb, 'Top recurring errors');
    if (errorGroups.isEmpty) {
      sb.writeln('No recurring errors detected.');
    } else {
      for (final group in errorGroups.take(8)) {
        sb.writeln(
          '  ${group.count}x [${group.sample.event}] ${group.sample.message} '
          '(route=${group.sample.route ?? "??"})',
        );
        if (group.sample.fingerprint != null) {
          sb.writeln('    fingerprint: ${group.sample.fingerprint}');
        }
      }
    }
    if (suppressionLogs.isNotEmpty) {
      sb.writeln('Suppression events: ${suppressionLogs.length}');
      for (final s in suppressionLogs.reversed.take(3)) {
        sb.writeln('  [${s.timestamp.toIso8601String()}] ${s.message}');
        if (s.data != null) sb.writeln('    ${jsonEncode(s.data)}');
      }
    }

    // Repro timeline
    _section(sb, 'Repro timeline (last ${recent.length} events)');
    for (final e in recent) {
      final dur = e.durationMs != null ? ' ${e.durationMs}ms' : '';
      final ridValue = e.requestId;
      final rid =
          ridValue != null
              ? ' rid=${ridValue.substring(0, ridValue.length.clamp(0, 8))}'
              : '';
      final jid = e.jobId != null ? ' job=${e.jobId}' : '';
      sb.writeln(
        '  [${e.timestamp.toIso8601String()}] ${e.level.name.toUpperCase().padRight(5)} '
        '[${e.layer.name}] ${e.event}$rid$jid$dur — ${e.message}',
      );
    }

    // Network timeline
    _section(sb, 'Network timeline (${networkLogs.length} events)');
    for (final e in networkLogs) {
      final dur = e.durationMs != null ? ' ${e.durationMs}ms' : '';
      sb.writeln(
        '  [${e.timestamp.toIso8601String()}] ${e.event}$dur — ${e.message}',
      );
    }

    // State transitions
    _section(sb, 'State transitions (${stateLogs.length} events)');
    for (final e in stateLogs) {
      sb.writeln(
        '  [${e.timestamp.toIso8601String()}] ${e.event}: ${e.message}',
      );
      if (e.data != null) sb.writeln('    ${jsonEncode(e.data)}');
    }

    // Raw JSONL
    _section(sb, 'Raw JSONL (last ${recent.length} entries)');
    for (final e in recent) {
      sb.writeln(jsonEncode(e.toJson()));
    }

    _section(sb, 'Stats');
    sb.writeln('Total buffered: ${all.length}');
    sb.writeln('Errors: ${errors.length}  Warnings: ${warnings.length}');

    return sb.toString();
  }

  void _section(StringBuffer sb, String title) {
    final bar = '=' * 60;
    sb.writeln('\n$bar');
    sb.writeln('## $title');
    sb.writeln(bar);
  }

  List<_ErrorGroup> _groupRecurringErrors(List<LogEntry> entries) {
    final groups = <String, List<LogEntry>>{};
    for (final entry in entries) {
      if (entry.level != LogLevel.error) continue;
      final key = entry.fingerprint ?? '${entry.event}|${entry.message}';
      groups.putIfAbsent(key, () => []).add(entry);
    }

    final result =
        groups.entries
            .map(
              (entry) => _ErrorGroup(
                count: entry.value.length,
                sample: entry.value.last,
              ),
            )
            .toList();
    result.sort((a, b) => b.count.compareTo(a.count));
    return result;
  }
}

class _ErrorGroup {
  const _ErrorGroup({required this.count, required this.sample});

  final int count;
  final LogEntry sample;
}
