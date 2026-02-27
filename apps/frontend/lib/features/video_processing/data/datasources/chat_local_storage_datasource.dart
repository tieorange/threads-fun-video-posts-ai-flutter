import 'dart:convert';
import 'package:web/web.dart' as web;
import '../../../../core/logging/logger.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/funny_moment.dart';

/// Local storage datasource for persisting chat state
class ChatLocalStorageDatasource {
  ChatLocalStorageDatasource(this._logger);

  final AppLogger _logger;
  static const String _storageKey = 'chat_flow_state';
  static const String _messagesKey = 'chat_flow_messages';
  static const String _jobKey = 'active_job_state';

  /// Save chat state to localStorage
  void saveState({
    required String currentStep,
    required List<ChatMessage> messages,
    String? url,
    String? language,
    String? youtubeUrl,
    Map<String, dynamic>? aiPayload,
    Map<String, dynamic>? analyzeResult,
    String? prompt,
  }) {
    try {
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

      // Save state
      web.window.localStorage.setItem(_storageKey, jsonEncode(stateData));

      // Save messages separately (can be large)
      final messagesData = messages.map((m) => _messageToJson(m)).toList();
      web.window.localStorage.setItem(_messagesKey, jsonEncode(messagesData));
    } catch (e) {
      // Silently fail if localStorage is not available or full
      _logger.error('local_storage_error', 'Failed to save chat state: $e');
    }
  }

  /// Load chat state from localStorage
  ChatPersistenceData? loadState() {
    try {
      final stateJson = web.window.localStorage.getItem(_storageKey);
      final messagesJson = web.window.localStorage.getItem(_messagesKey);

      if (stateJson == null || messagesJson == null) {
        return null;
      }

      final stateData = jsonDecode(stateJson) as Map<String, dynamic>;
      final messagesData = jsonDecode(messagesJson) as List<dynamic>;

      // Check if data is not too old (24 hours)
      final timestamp = DateTime.parse(stateData['timestamp'] as String);
      if (DateTime.now().difference(timestamp).inHours > 24) {
        clearState();
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
  void clearState() {
    try {
      web.window.localStorage.removeItem(_storageKey);
      web.window.localStorage.removeItem(_messagesKey);
    } catch (e) {
      _logger.error('local_storage_error', 'Failed to clear chat state: $e');
    }
  }

  /// Save active job to localStorage
  void saveJob({
    required String jobId,
    required List<FunnyMoment> moments,
    required String youtubeUrl,
  }) {
    try {
      final jobData = {
        'jobId': jobId,
        'moments': moments.map((m) => m.toJson()).toList(),
        'youtubeUrl': youtubeUrl,
        'timestamp': DateTime.now().toIso8601String(),
      };
      web.window.localStorage.setItem(_jobKey, jsonEncode(jobData));
    } catch (e) {
      _logger.error('local_storage_error', 'Failed to save job state: $e');
    }
  }

  /// Load active job from localStorage
  JobPersistenceData? loadJob() {
    try {
      final jobJson = web.window.localStorage.getItem(_jobKey);
      if (jobJson == null) return null;

      final data = jsonDecode(jobJson) as Map<String, dynamic>;

      // Clear job if older than 12 hours
      final timestamp = DateTime.parse(data['timestamp'] as String);
      if (DateTime.now().difference(timestamp).inHours > 12) {
        clearJob();
        return null;
      }

      return JobPersistenceData(
        jobId: data['jobId'] as String,
        moments: (data['moments'] as List<dynamic>)
            .map((m) => FunnyMoment.fromJson(m as Map<String, dynamic>))
            .toList(),
        youtubeUrl: data['youtubeUrl'] as String,
      );
    } catch (e) {
      _logger.error('local_storage_error', 'Failed to load job state: $e');
      return null;
    }
  }

  /// Clear active job
  void clearJob() {
    try {
      web.window.localStorage.removeItem(_jobKey);
    } catch (e) {
      _logger.error('local_storage_error', 'Failed to clear job state: $e');
    }
  }

  /// Convert ChatMessage to JSON
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

  /// Convert JSON to ChatMessage
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
  const JobPersistenceData({required this.jobId, required this.moments, required this.youtubeUrl});

  final String jobId;
  final List<FunnyMoment> moments;
  final String youtubeUrl;
}
