class ChatResponse {
  final List<Candidate> candidates;

  ChatResponse({required this.candidates});

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      candidates:
          (json['candidates'] as List<dynamic>?)
              ?.map((e) => Candidate.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {'candidates': candidates.map((e) => e.toJson()).toList()};
  }
}

class Candidate {
  final Content content;

  Candidate({required this.content});

  factory Candidate.fromJson(Map<String, dynamic> json) {
    return Candidate(
      content: Content.fromJson(json['content'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {'content': content.toJson()};
  }
}

class Content {
  final List<Part> parts;

  Content({required this.parts});

  factory Content.fromJson(Map<String, dynamic> json) {
    return Content(
      parts:
          (json['parts'] as List<dynamic>?)
              ?.map((e) => Part.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {'parts': parts.map((e) => e.toJson()).toList()};
  }
}

class Part {
  final String text;

  Part({required this.text});

  factory Part.fromJson(Map<String, dynamic> json) {
    return Part(text: json['text'] as String? ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'text': text};
  }
}

// Request models
class ChatRequest {
  final List<ContentRequest> contents;

  ChatRequest({required this.contents});

  factory ChatRequest.fromJson(Map<String, dynamic> json) {
    return ChatRequest(
      contents:
          (json['contents'] as List<dynamic>?)
              ?.map((e) => ContentRequest.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {'contents': contents.map((e) => e.toJson()).toList()};
  }
}

class ContentRequest {
  final List<PartRequest> parts;

  ContentRequest({required this.parts});

  factory ContentRequest.fromJson(Map<String, dynamic> json) {
    return ContentRequest(
      parts:
          (json['parts'] as List<dynamic>?)
              ?.map((e) => PartRequest.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {'parts': parts.map((e) => e.toJson()).toList()};
  }
}

class PartRequest {
  final String text;

  PartRequest({required this.text});

  factory PartRequest.fromJson(Map<String, dynamic> json) {
    return PartRequest(text: json['text'] as String? ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'text': text};
  }
}

// Chat message model
class ChatMessage {
  final String id;
  final String message;
  final bool isFromUser;
  final DateTime timestamp;
  final bool isLoading;
  final bool hasError;
  final bool isStreaming;
  final String streamingText;

  ChatMessage({
    required this.id,
    required this.message,
    required this.isFromUser,
    required this.timestamp,
    this.isLoading = false,
    this.hasError = false,
    this.isStreaming = false,
    this.streamingText = '',
  });

  ChatMessage copyWith({
    String? id,
    String? message,
    bool? isFromUser,
    DateTime? timestamp,
    bool? isLoading,
    bool? hasError,
    bool? isStreaming,
    String? streamingText,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      message: message ?? this.message,
      isFromUser: isFromUser ?? this.isFromUser,
      timestamp: timestamp ?? this.timestamp,
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
      isStreaming: isStreaming ?? this.isStreaming,
      streamingText: streamingText ?? this.streamingText,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'isFromUser': isFromUser,
      'timestamp': timestamp.toIso8601String(),
      'isLoading': isLoading,
      'hasError': hasError,
      'isStreaming': isStreaming,
      'streamingText': streamingText,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String? ?? '',
      message: json['message'] as String? ?? '',
      isFromUser: json['isFromUser'] as bool? ?? false,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      isLoading: json['isLoading'] as bool? ?? false,
      hasError: json['hasError'] as bool? ?? false,
      isStreaming: json['isStreaming'] as bool? ?? false,
      streamingText: json['streamingText'] as String? ?? '',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage &&
        other.id == id &&
        other.message == message &&
        other.isFromUser == isFromUser &&
        other.timestamp == timestamp &&
        other.isLoading == isLoading &&
        other.hasError == hasError &&
        other.isStreaming == isStreaming &&
        other.streamingText == streamingText;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      message,
      isFromUser,
      timestamp,
      isLoading,
      hasError,
      isStreaming,
      streamingText,
    );
  }

  @override
  String toString() {
    return 'ChatMessage('
        'id: $id, '
        'message: $message, '
        'isFromUser: $isFromUser, '
        'timestamp: $timestamp, '
        'isLoading: $isLoading, '
        'hasError: $hasError, '
        'isStreaming: $isStreaming, '
        'streamingText: $streamingText'
        ')';
  }
}

// Stream response sealed class equivalent
abstract class StreamResponse {
  const StreamResponse();
}

class StreamStarted extends StreamResponse {
  const StreamStarted();

  @override
  String toString() => 'StreamStarted()';
}

class StreamChunk extends StreamResponse {
  final String text;

  const StreamChunk(this.text);

  @override
  String toString() => 'StreamChunk(text: $text)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StreamChunk && other.text == text;
  }

  @override
  int get hashCode => text.hashCode;
}

class StreamComplete extends StreamResponse {
  final String fullText;

  const StreamComplete(this.fullText);

  @override
  String toString() => 'StreamComplete(fullText: $fullText)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StreamComplete && other.fullText == fullText;
  }

  @override
  int get hashCode => fullText.hashCode;
}

class StreamError extends StreamResponse {
  final String error;

  const StreamError(this.error);

  @override
  String toString() => 'StreamError(error: $error)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StreamError && other.error == error;
  }

  @override
  int get hashCode => error.hashCode;
}

// Chat statistics
class ChatStatistics {
  final int totalSessions;
  final DateTime? firstChatDate;
  final DateTime? lastChatDate;
  final int favoriteTopicsCount;
  final bool onboardingComplete;
  final String timeSinceLastChat;

  const ChatStatistics({
    required this.totalSessions,
    this.firstChatDate,
    this.lastChatDate,
    required this.favoriteTopicsCount,
    required this.onboardingComplete,
    required this.timeSinceLastChat,
  });

  @override
  String toString() {
    return 'ChatStatistics('
        'totalSessions: $totalSessions, '
        'firstChatDate: $firstChatDate, '
        'lastChatDate: $lastChatDate, '
        'favoriteTopicsCount: $favoriteTopicsCount, '
        'onboardingComplete: $onboardingComplete, '
        'timeSinceLastChat: $timeSinceLastChat'
        ')';
  }
}

// Welcome strategy enum
enum WelcomeStrategy { firstTime, returningUser, dailyTip, simpleGreeting }

// User interaction types
abstract class UserInteraction {
  const UserInteraction();
}

class MessageSent extends UserInteraction {
  final String message;

  const MessageSent(this.message);

  @override
  String toString() => 'MessageSent(message: $message)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MessageSent && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}

class WelcomeCompleted extends UserInteraction {
  const WelcomeCompleted();

  @override
  String toString() => 'WelcomeCompleted()';
}

class TipViewed extends UserInteraction {
  const TipViewed();

  @override
  String toString() => 'TipViewed()';
}

// Exception classes untuk error handling
class ChatException implements Exception {
  final String message;
  final String? code;

  const ChatException(this.message, [this.code]);

  @override
  String toString() =>
      'ChatException: $message${code != null ? ' (Code: $code)' : ''}';
}

class NetworkException extends ChatException {
  const NetworkException(String message) : super(message, 'NETWORK_ERROR');
}

class ApiException extends ChatException {
  final int statusCode;

  const ApiException(String message, this.statusCode)
    : super(message, 'API_ERROR');

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

class ValidationException extends ChatException {
  const ValidationException(String message)
    : super(message, 'VALIDATION_ERROR');
}
