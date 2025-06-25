import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_models.dart';
import '../models/user_profile.dart';
import '../models/detection_result.dart';
import '../services/chat_service.dart';
import '../services/user_profile_service.dart';

class ChatRepository {
  static const String _chatMessagesKey = 'chat_messages';
  static const String _lastDetectionResultKey = 'last_detection_result';
  static const String _userRiskLevelKey = 'user_risk_level';
  static const String _userDiabetesStatusKey = 'user_diabetes_status';
  static const int _maxChatHistory = 100;

  final ChatService _chatService;
  final SharedPreferences _prefs;
  final UserProfileService _userProfileService;

  ChatRepository({
    required ChatService chatService,
    required SharedPreferences prefs,
  }) : _chatService = chatService,
       _prefs = prefs,
       _userProfileService = UserProfileService(prefs);

  // Send message with user context
  Future<Result<String>> sendMessageWithContext(
    String message, {
    String? preferredLanguage = 'id',
  }) async {
    final userProfile = await _userProfileService.getUserProfile();

    final result = await _chatService.sendMessageWithContext(
      message,
      userProfile: userProfile,
      preferredLanguage: preferredLanguage,
    );

    if (result.isSuccess) {
      _analyzeUserInteraction(message, result.value);
    }

    return result;
  }

  // Stream message with user context
  Stream<StreamResponse> sendMessageStreamWithContext(
    String message, {
    String? preferredLanguage = 'id',
  }) async* {
    final userProfile = await _userProfileService.getUserProfile();

    String? completeMessage;

    await for (final response in _chatService.sendMessageStreamWithContext(
      message,
      userProfile: userProfile,
      preferredLanguage: preferredLanguage,
    )) {
      if (response is StreamComplete) {
        completeMessage = response.fullText;
        _analyzeUserInteraction(message, completeMessage);
      }
      yield response;
    }
  }

  // ADD: Stream method with detection context
  Stream<StreamResponse> sendMessageStreamWithDetectionContext(
    String message, {
    UserProfile? userProfile,
    DetectionResult? detectionResult,
    String? preferredLanguage = 'id',
  }) async* {
    try {
      final actualUserProfile =
          userProfile ?? await _userProfileService.getUserProfile();

      yield* _chatService.sendMessageStreamWithDetectionContext(
        message,
        userProfile: actualUserProfile,
        detectionResult: detectionResult,
        preferredLanguage: preferredLanguage,
      );
    } catch (e) {
      yield StreamError('Gagal mengirim pesan dengan konteks deteksi: $e');
    }
  }

  // ADD: Send message with detection context
  Future<Result<String>> sendMessageWithDetectionContext(
    String message, {
    UserProfile? userProfile,
    DetectionResult? detectionResult,
    String? preferredLanguage = 'id',
  }) async {
    try {
      final actualUserProfile =
          userProfile ?? await _userProfileService.getUserProfile();

      final result = await _chatService.sendMessageWithDetectionContext(
        message,
        userProfile: actualUserProfile,
        detectionResult: detectionResult,
        preferredLanguage: preferredLanguage,
      );

      if (result.isSuccess) {
        _analyzeUserInteraction(message, result.value);
      }

      return result;
    } catch (e) {
      return Result.failure(
        Exception('Gagal berkonsultasi dengan AI Diabetes: $e'),
      );
    }
  }

  // Legacy methods for backward compatibility
  Future<Result<String>> sendMessage(String message) async {
    return sendMessageWithContext(message);
  }

  Stream<StreamResponse> sendMessageStream(String message) async* {
    yield* sendMessageStreamWithContext(message);
  }

  // ADD: Smart method that auto-syncs with latest detection
  Future<Result<String>> sendMessageWithAutoSync(
    String message, {
    String? preferredLanguage = 'id',
  }) async {
    final result = await _chatService.sendMessageWithAutoSync(
      message,
      preferredLanguage: preferredLanguage,
    );

    if (result.isSuccess) {
      _analyzeUserInteraction(message, result.value);
    }

    return result;
  }

  // ADD: Smart stream method that auto-syncs with latest detection
  Stream<StreamResponse> sendMessageStreamWithAutoSync(
    String message, {
    String? preferredLanguage = 'id',
  }) async* {
    String? completeMessage;

    await for (final response in _chatService.sendMessageStreamWithAutoSync(
      message,
      preferredLanguage: preferredLanguage,
    )) {
      if (response is StreamComplete) {
        completeMessage = response.fullText;
        _analyzeUserInteraction(message, completeMessage);
      }
      yield response;
    }
  }

  Future<List<ChatMessage>> getChatHistory() async {
    try {
      final json = _prefs.getString(_chatMessagesKey) ?? '[]';
      final List<dynamic> messageList = jsonDecode(json);

      return messageList.map((item) => ChatMessage.fromJson(item)).toList();
    } catch (e) {
      print('Error loading chat history: $e');
      return [];
    }
  }

  Future<void> saveChatMessage(ChatMessage message) async {
    try {
      final currentMessages = await getChatHistory();
      currentMessages.add(message);

      // Limit chat history to prevent storage bloat
      final messagesToSave = currentMessages.length > _maxChatHistory
          ? currentMessages.sublist(currentMessages.length - _maxChatHistory)
          : currentMessages;

      final json = jsonEncode(
        messagesToSave.map((msg) => msg.toJson()).toList(),
      );

      await _prefs.setString(_chatMessagesKey, json);
    } catch (e) {
      print('Error saving chat message: $e');
    }
  }

  Future<void> clearChatHistory() async {
    try {
      await _prefs.remove(_chatMessagesKey);
      await _prefs.remove(_lastDetectionResultKey);
      await _prefs.remove(_userRiskLevelKey);
      await _prefs.remove(_userDiabetesStatusKey);
      await _prefs.remove('detection_timestamp');

      // Clear interaction analytics
      await _clearInteractionAnalytics();
    } catch (e) {
      print('Error clearing chat history: $e');
    }
  }

  Future<void> updateUserDetectionResult(
    String result,
    String riskLevel, {
    List<String>? riskFactors,
  }) async {
    try {
      await _prefs.setString(_lastDetectionResultKey, result);
      await _prefs.setString(_userRiskLevelKey, riskLevel);
      await _prefs.setInt(
        'detection_timestamp',
        DateTime.now().millisecondsSinceEpoch,
      );

      // Update user profile with detection result
      await _userProfileService.updateDetectionResult(
        result: result,
        riskLevel: riskLevel,
        riskFactors: riskFactors,
      );

      final diabetesStatus = _determineDiabetesStatus(riskLevel);
      await _prefs.setString(_userDiabetesStatusKey, diabetesStatus);

      print('Detection result updated: $result, Risk: $riskLevel');
    } catch (e) {
      print('Error updating detection result: $e');
    }
  }

  // Get current user diabetes context
  Future<UserDiabetesContext> getUserDiabetesContext() async {
    try {
      final lastResult = _prefs.getString(_lastDetectionResultKey);
      final riskLevel = _prefs.getString(_userRiskLevelKey);
      final diabetesStatus =
          _prefs.getString(_userDiabetesStatusKey) ?? 'unknown';
      final timestamp = _prefs.getInt('detection_timestamp');

      return UserDiabetesContext(
        lastDetectionResult: lastResult,
        riskLevel: riskLevel,
        diabetesStatus: diabetesStatus,
        detectionTimestamp: timestamp != null
            ? DateTime.fromMillisecondsSinceEpoch(timestamp)
            : null,
      );
    } catch (e) {
      print('Error getting diabetes context: $e');
      return const UserDiabetesContext();
    }
  }

  // User profile methods
  Future<UserProfile?> getUserProfile() async {
    return await _userProfileService.getUserProfile();
  }

  Future<bool> updateUserProfile(UserProfile profile) async {
    return await _userProfileService.saveUserProfile(profile);
  }

  Future<bool> hasUserProfile() async {
    return _userProfileService.hasProfile;
  }

  // Get recent conversation topics for context
  Future<List<String>> getRecentTopics({int limit = 5}) async {
    try {
      final messages = await getChatHistory();
      final userMessages = messages
          .where((msg) => msg.isFromUser)
          .take(limit)
          .map((msg) => msg.message)
          .toList();

      return _extractTopics(userMessages);
    } catch (e) {
      print('Error getting recent topics: $e');
      return [];
    }
  }

  // Extract topics from user messages
  List<String> _extractTopics(List<String> messages) {
    final topics = <String>[];
    final keywords = {
      'deteksi': 'Deteksi Diabetes',
      'risiko': 'Tingkat Risiko',
      'gula darah': 'Gula Darah',
      'glukosa': 'Glukosa',
      'makanan': 'Pola Makan',
      'diet': 'Diet Diabetes',
      'olahraga': 'Aktivitas Fisik',
      'gejala': 'Gejala Diabetes',
      'lidah': 'Analisis Lidah',
      'obat': 'Pengobatan',
      'dokter': 'Konsultasi Medis',
      'pencegahan': 'Pencegahan',
      'komplikasi': 'Komplikasi',
      'insulin': 'Insulin',
      'hba1c': 'HbA1c',
      'bmi': 'BMI',
    };

    for (final message in messages) {
      final lowerMessage = message.toLowerCase();
      for (final entry in keywords.entries) {
        if (lowerMessage.contains(entry.key) && !topics.contains(entry.value)) {
          topics.add(entry.value);
        }
      }
    }

    return topics;
  }

  // Build session context for better AI responses
  String buildSessionContext() {
    final now = DateTime.now();
    final hour = now.hour;

    String timeContext = '';
    if (hour >= 5 && hour <= 11) {
      timeContext =
          'Pagi hari - waktu yang baik untuk diskusi sarapan sehat dan aktivitas pagi';
    } else if (hour >= 12 && hour <= 16) {
      timeContext =
          'Siang hari - cocok untuk diskusi makan siang dan aktivitas siang';
    } else if (hour >= 17 && hour <= 20) {
      timeContext =
          'Sore hari - waktu yang tepat untuk diskusi aktivitas fisik dan makan malam';
    } else {
      timeContext =
          'Malam hari - cocok untuk diskusi pola tidur dan perencanaan esok hari';
    }

    return timeContext;
  }

  // Determine diabetes status based on risk level
  String _determineDiabetesStatus(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'tinggi':
      case 'high':
        return 'high_risk';
      case 'sedang':
      case 'medium':
        return 'medium_risk';
      case 'rendah':
      case 'low':
        return 'low_risk';
      default:
        return 'unknown';
    }
  }

  // Analyze user interaction patterns for better insights
  void _analyzeUserInteraction(String userMessage, String aiResponse) {
    try {
      final lowerMessage = userMessage.toLowerCase();

      // Track diabetes-related interaction patterns
      final diabetesKeywords = {
        'deteksi': 'detection_queries',
        'risiko tinggi': 'high_risk_concerns',
        'risiko rendah': 'low_risk_queries',
        'gula darah': 'blood_sugar_questions',
        'makanan': 'diet_questions',
        'gejala': 'symptom_questions',
        'pencegahan': 'prevention_questions',
        'obat': 'medication_questions',
        'dokter': 'medical_consultation',
        'lidah': 'tongue_analysis_questions',
        'bmi': 'bmi_questions',
        'olahraga': 'exercise_questions',
        'komplikasi': 'complication_concerns',
      };

      // Count keyword occurrences
      for (final entry in diabetesKeywords.entries) {
        if (lowerMessage.contains(entry.key)) {
          final count = _prefs.getInt(entry.value) ?? 0;
          _prefs.setInt(entry.value, count + 1);
        }
      }

      // Track overall interaction metrics
      final totalInteractions = _prefs.getInt('total_interactions') ?? 0;
      _prefs.setInt('total_interactions', totalInteractions + 1);
      _prefs.setInt('last_interaction', DateTime.now().millisecondsSinceEpoch);

      // Track message length for analytics
      final avgMessageLength = _prefs.getDouble('avg_message_length') ?? 0.0;
      final newAvgLength = (avgMessageLength + userMessage.length) / 2;
      _prefs.setDouble('avg_message_length', newAvgLength);
    } catch (e) {
      print('Error analyzing user interaction: $e');
    }
  }

  // Clear interaction analytics
  Future<void> _clearInteractionAnalytics() async {
    try {
      final analyticsKeys = [
        'detection_queries',
        'high_risk_concerns',
        'low_risk_queries',
        'blood_sugar_questions',
        'diet_questions',
        'symptom_questions',
        'prevention_questions',
        'medication_questions',
        'medical_consultation',
        'tongue_analysis_questions',
        'bmi_questions',
        'exercise_questions',
        'complication_concerns',
        'total_interactions',
        'last_interaction',
        'avg_message_length',
      ];

      for (final key in analyticsKeys) {
        await _prefs.remove(key);
      }
    } catch (e) {
      print('Error clearing analytics: $e');
    }
  }

  // Get user interaction analytics
  Map<String, dynamic> getUserAnalytics() {
    try {
      return {
        'totalInteractions': _prefs.getInt('total_interactions') ?? 0,
        'lastInteraction': _prefs.getInt('last_interaction'),
        'avgMessageLength': _prefs.getDouble('avg_message_length') ?? 0.0,
        'detectionQueries': _prefs.getInt('detection_queries') ?? 0,
        'highRiskConcerns': _prefs.getInt('high_risk_concerns') ?? 0,
        'dietQuestions': _prefs.getInt('diet_questions') ?? 0,
        'symptomQuestions': _prefs.getInt('symptom_questions') ?? 0,
        'medicalConsultation': _prefs.getInt('medical_consultation') ?? 0,
      };
    } catch (e) {
      print('Error getting analytics: $e');
      return {};
    }
  }

  // Export chat data for backup
  Future<Map<String, dynamic>> exportChatData() async {
    try {
      final messages = await getChatHistory();
      final diabetesContext = await getUserDiabetesContext();
      final analytics = getUserAnalytics();

      return {
        'messages': messages.map((msg) => msg.toJson()).toList(),
        'diabetesContext': {
          'lastDetectionResult': diabetesContext.lastDetectionResult,
          'riskLevel': diabetesContext.riskLevel,
          'diabetesStatus': diabetesContext.diabetesStatus,
          'detectionTimestamp':
              diabetesContext.detectionTimestamp?.millisecondsSinceEpoch,
        },
        'analytics': analytics,
        'exportTimestamp': DateTime.now().millisecondsSinceEpoch,
        'version': '1.0.0',
      };
    } catch (e) {
      print('Error exporting chat data: $e');
      return {};
    }
  }

  // Import chat data from backup
  Future<bool> importChatData(Map<String, dynamic> data) async {
    try {
      // Import messages
      if (data.containsKey('messages')) {
        final messagesData = data['messages'] as List<dynamic>;
        final messages = messagesData
            .map((item) => ChatMessage.fromJson(item))
            .toList();

        final json = jsonEncode(messages.map((msg) => msg.toJson()).toList());
        await _prefs.setString(_chatMessagesKey, json);
      }

      // Import diabetes context
      if (data.containsKey('diabetesContext')) {
        final context = data['diabetesContext'] as Map<String, dynamic>;

        if (context['lastDetectionResult'] != null) {
          await _prefs.setString(
            _lastDetectionResultKey,
            context['lastDetectionResult'],
          );
        }
        if (context['riskLevel'] != null) {
          await _prefs.setString(_userRiskLevelKey, context['riskLevel']);
        }
        if (context['diabetesStatus'] != null) {
          await _prefs.setString(
            _userDiabetesStatusKey,
            context['diabetesStatus'],
          );
        }
        if (context['detectionTimestamp'] != null) {
          await _prefs.setInt(
            'detection_timestamp',
            context['detectionTimestamp'],
          );
        }
      }

      // Import analytics
      if (data.containsKey('analytics')) {
        final analytics = data['analytics'] as Map<String, dynamic>;
        for (final entry in analytics.entries) {
          if (entry.value is int) {
            await _prefs.setInt(entry.key, entry.value);
          } else if (entry.value is double) {
            await _prefs.setDouble(entry.key, entry.value);
          }
        }
      }

      return true;
    } catch (e) {
      print('Error importing chat data: $e');
      return false;
    }
  }

  void dispose() {
    _chatService.dispose();
  }
}

// Enhanced UserDiabetesContext class
class UserDiabetesContext {
  final String? lastDetectionResult;
  final String? riskLevel;
  final String diabetesStatus;
  final DateTime? detectionTimestamp;

  const UserDiabetesContext({
    this.lastDetectionResult,
    this.riskLevel,
    this.diabetesStatus = 'unknown',
    this.detectionTimestamp,
  });

  bool get hasDetectionHistory =>
      lastDetectionResult != null && riskLevel != null;

  bool get isHighRisk =>
      riskLevel?.toLowerCase() == 'tinggi' ||
      riskLevel?.toLowerCase() == 'high';

  bool get isMediumRisk =>
      riskLevel?.toLowerCase() == 'sedang' ||
      riskLevel?.toLowerCase() == 'medium';

  bool get isLowRisk =>
      riskLevel?.toLowerCase() == 'rendah' || riskLevel?.toLowerCase() == 'low';

  bool get needsUrgentConsultation => isHighRisk;

  bool get needsRegularMonitoring => isMediumRisk || isHighRisk;

  String get riskLevelDisplay {
    switch (riskLevel?.toLowerCase()) {
      case 'tinggi':
      case 'high':
        return 'Risiko Tinggi';
      case 'sedang':
      case 'medium':
        return 'Risiko Sedang';
      case 'rendah':
      case 'low':
        return 'Risiko Rendah';
      default:
        return 'Belum Diketahui';
    }
  }

  String get statusDisplay {
    switch (diabetesStatus) {
      case 'high_risk':
        return 'Perlu Perhatian Khusus';
      case 'medium_risk':
        return 'Monitoring Rutin';
      case 'low_risk':
        return 'Pertahankan Gaya Hidup Sehat';
      default:
        return 'Belum Ada Data';
    }
  }

  String get recommendationDisplay {
    switch (diabetesStatus) {
      case 'high_risk':
        return '🚨 Segera konsultasi dengan dokter untuk pemeriksaan lanjutan';
      case 'medium_risk':
        return '⚠️ Lakukan monitoring gula darah dan konsultasi dokter secara rutin';
      case 'low_risk':
        return '✅ Pertahankan pola hidup sehat dan lakukan screening berkala';
      default:
        return '📋 Lakukan deteksi untuk mengetahui tingkat risiko Anda';
    }
  }

  // Time since last detection
  Duration? get timeSinceDetection {
    if (detectionTimestamp == null) return null;
    return DateTime.now().difference(detectionTimestamp!);
  }

  bool get isDetectionStale {
    final timeSince = timeSinceDetection;
    if (timeSince == null) return true;

    // Consider detection stale after 30 days
    return timeSince.inDays > 30;
  }

  Map<String, dynamic> toJson() {
    return {
      'lastDetectionResult': lastDetectionResult,
      'riskLevel': riskLevel,
      'diabetesStatus': diabetesStatus,
      'detectionTimestamp': detectionTimestamp?.millisecondsSinceEpoch,
    };
  }

  factory UserDiabetesContext.fromJson(Map<String, dynamic> json) {
    return UserDiabetesContext(
      lastDetectionResult: json['lastDetectionResult'],
      riskLevel: json['riskLevel'],
      diabetesStatus: json['diabetesStatus'] ?? 'unknown',
      detectionTimestamp: json['detectionTimestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['detectionTimestamp'])
          : null,
    );
  }

  @override
  String toString() {
    return 'UserDiabetesContext('
        'lastDetectionResult: $lastDetectionResult, '
        'riskLevel: $riskLevel, '
        'diabetesStatus: $diabetesStatus, '
        'detectionTimestamp: $detectionTimestamp'
        ')';
  }
}
