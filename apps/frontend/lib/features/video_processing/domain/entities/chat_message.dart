import 'package:flutter/material.dart';

/// Message type for UI rendering
enum MessageType {
  text,
  languageSelection,
  videoMetadata,
  aiPrompt,
  error,
  loading,
}

/// Entity representing a single chat message
@immutable
class ChatMessage {
  const ChatMessage._({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    required this.type,
    this.metadata,
  });

  /// Factory for bot messages
  factory ChatMessage.bot({
    required String text,
    required DateTime timestamp,
    MessageType type = MessageType.text,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage._(
      id: _generateId(),
      text: text,
      isUser: false,
      timestamp: timestamp,
      type: type,
      metadata: metadata,
    );
  }

  /// Factory for user messages
  factory ChatMessage.user({
    required String text,
    required DateTime timestamp,
  }) {
    return ChatMessage._(
      id: _generateId(),
      text: text,
      isUser: true,
      timestamp: timestamp,
      type: MessageType.text,
    );
  }

  /// Unique message ID
  final String id;

  /// Message text content
  final String text;

  /// true = user message, false = bot message
  final bool isUser;

  /// Message timestamp
  final DateTime timestamp;

  /// Message type for UI rendering
  final MessageType type;

  /// Optional metadata for special message types
  /// Example: video metadata, prompt data
  final Map<String, dynamic>? metadata;

  /// ID generator
  static String _generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${_counter++}';
  }

  static int _counter = 0;
}
