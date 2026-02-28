import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/logging/logger.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/clip_artifact.dart';
import '../../domain/entities/funny_moment.dart';
import '../../domain/entities/job_status.dart';

/// Local storage datasource for persisting chat state
class ChatLocalStorageDatasource {
  ChatLocalStorageDatasource(this._logger);

  final AppLogger _logger;
  static const String _storageKey = 'chat_flow_state';
  static const String _messagesKey = 'chat_flow_messages';
  static const String _jobKey = 'active_job_state';

  /// Save chat state to SharedPreferences
  Future<void> saveState({
    required String currentStep,
    required List<ChatMessage> messages,
    String? url,
    String? language,
    String? youtubeUrl,
    Map<String, dynamic>? aiPayload,
    Map<String, dynamic>? analyzeResult,
    String? prompt,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stateData = <String, dynamic>{
        'currentStep': currentStep,
        'url': url,
        'language': language,
        'youtubeUrl': youtubeUrl,
        'aiPayload': aiPayload,
        'analyzeResult': analyzeResult,
        'prompt': prompt,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await prefs.setString(_storageKey, jsonEncode(stateData));

      final messagesData = messages.map((m) => _messageToJson(m)).toList();
      await prefs.setString(_messagesKey, jsonEncode(messagesData));
    } catch (e) {
      _logger.error('local_storage_error', 'Failed to save chat state: $e');
    }
  }

  /// Load chat state from SharedPreferences
  Future<ChatPersistenceData?> loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stateJson = prefs.getString(_storageKey);
      final messagesJson = prefs.getString(_messagesKey);

      if (stateJson == null || messagesJson == null) {
        return null;
      }

      final stateData = jsonDecode(stateJson) as Map<String, dynamic>;
      final messagesData = jsonDecode(messagesJson) as List<dynamic>;

      final timestamp = DateTime.parse(stateData['timestamp'] as String);
      if (DateTime.now().difference(timestamp).inHours > 24) {
        await clearState();
        return null;
      }

      final messages = messagesData
          .map((m) => _messageFromJson(m as Map<String, dynamic>))
          .toList();

      return ChatPersistenceData(
        currentStep: stateData['currentStep'] as String,
        messages: messages,
        url: stateData['url'] as String?,
        language: stateData['language'] as String?,
        youtubeUrl: stateData['youtubeUrl'] as String?,
        aiPayload: stateData['aiPayload'] as Map<String, dynamic>?,
        analyzeResult: stateData['analyzeResult'] as Map<String, dynamic>?,
        prompt: stateData['prompt'] as String?,
      );
    } catch (e) {
      _logger.error('local_storage_error', 'Failed to load chat state: $e');
      return null;
    }
  }

  /// Clear saved state
  Future<void> clearState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      await prefs.remove(_messagesKey);
    } catch (e) {
      _logger.error('local_storage_error', 'Failed to clear chat state: $e');
    }
  }

  /// Save active job to SharedPreferences.
  /// Pass [doneStatus] when the job has completed to enable refresh-safe results.
  Future<void> saveJob({
    required String jobId,
    required List<FunnyMoment> moments,
    required String youtubeUrl,
    JobStatus? doneStatus,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jobData = <String, dynamic>{
        'jobId': jobId,
        'moments': moments.map((m) => m.toJson()).toList(),
        'youtubeUrl': youtubeUrl,
        'timestamp': DateTime.now().toIso8601String(),
      };
      if (doneStatus != null) {
        jobData['doneStatus'] = _jobStatusToJson(doneStatus);
      }
      await prefs.setString(_jobKey, jsonEncode(jobData));
    } catch (e) {
      _logger.error('local_storage_error', 'Failed to save job state: $e');
    }
  }

  /// Load active job from SharedPreferences
  Future<JobPersistenceData?> loadJob() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jobJson = prefs.getString(_jobKey);
      if (jobJson == null) return null;

      final data = jsonDecode(jobJson) as Map<String, dynamic>;

      final timestamp = DateTime.parse(data['timestamp'] as String);
      if (DateTime.now().difference(timestamp).inHours > 12) {
        await clearJob();
        return null;
      }

      JobStatus? doneStatus;
      if (data['doneStatus'] != null) {
        doneStatus = _jobStatusFromJson(data['doneStatus'] as Map<String, dynamic>);
      }

      return JobPersistenceData(
        jobId: data['jobId'] as String,
        moments: (data['moments'] as List<dynamic>)
            .map((m) => FunnyMoment.fromJson(m as Map<String, dynamic>))
            .toList(),
        youtubeUrl: data['youtubeUrl'] as String,
        doneStatus: doneStatus,
      );
    } catch (e) {
      _logger.error('local_storage_error', 'Failed to load job state: $e');
      return null;
    }
  }

  Map<String, dynamic> _jobStatusToJson(JobStatus s) => {
    'jobId': s.jobId,
    'status': s.status.name,
    'progress': s.progress,
    'error': s.error,
    'clips': s.clips
        .map(
          (c) => {
            'momentId': c.momentId,
            'startSec': c.startSec,
            'endSec': c.endSec,
            'downloadUrl': c.downloadUrl,
          },
        )
        .toList(),
    'moments': s.moments.map((m) => m.toJson()).toList(),
  };

  JobStatus _jobStatusFromJson(Map<String, dynamic> j) => JobStatus(
    jobId: j['jobId'] as String,
    status: JobStatusType.values.firstWhere((e) => e.name == j['status']),
    progress: j['progress'] as int,
    error: j['error'] as String?,
    clips: (j['clips'] as List<dynamic>)
        .map((c) {
          final m = c as Map<String, dynamic>;
          return ClipArtifact(
            momentId: m['momentId'] as String,
            startSec: (m['startSec'] as num).toDouble(),
            endSec: (m['endSec'] as num).toDouble(),
            downloadUrl: m['downloadUrl'] as String,
          );
        })
        .toList(),
    moments: (j['moments'] as List<dynamic>)
        .map((m) => FunnyMoment.fromJson(m as Map<String, dynamic>))
        .toList(),
  );

  /// Clear active job
  Future<void> clearJob() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_jobKey);
    } catch (e) {
      _logger.error('local_storage_error', 'Failed to clear job state: $e');
    }
  }

  Map<String, dynamic> _messageToJson(ChatMessage message) {
    return {
      'id': message.id,
      'text': message.text,
      'isUser': message.isUser,
      'timestamp': message.timestamp.toIso8601String(),
      'type': message.type.name,
      'metadata': message.metadata,
    };
  }

  ChatMessage _messageFromJson(Map<String, dynamic> json) {
    final type = MessageType.values.firstWhere(
      (t) => t.name == json['type'],
      orElse: () => MessageType.text,
    );

    if (json['isUser'] as bool) {
      return ChatMessage.user(
        text: json['text'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
    } else {
      return ChatMessage.bot(
        text: json['text'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        type: type,
        metadata: json['metadata'] as Map<String, dynamic>?,
      );
    }
  }
}

/// Data class for persisted chat state
class ChatPersistenceData {
  const ChatPersistenceData({
    required this.currentStep,
    required this.messages,
    this.url,
    this.language,
    this.youtubeUrl,
    this.aiPayload,
    this.analyzeResult,
    this.prompt,
  });

  final String currentStep;
  final List<ChatMessage> messages;
  final String? url;
  final String? language;
  final String? youtubeUrl;
  final Map<String, dynamic>? aiPayload;
  final Map<String, dynamic>? analyzeResult;
  final String? prompt;
}

/// Data class for persisted job state
class JobPersistenceData {
  const JobPersistenceData({
    required this.jobId,
    required this.moments,
    required this.youtubeUrl,
    this.doneStatus,
  });

  final String jobId;
  final List<FunnyMoment> moments;
  final String youtubeUrl;
  /// Non-null when the job completed — allows restoring [ProcessDone] on refresh.
  final JobStatus? doneStatus;
}
