import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_models.dart';
import '../models/detection_result.dart';
import '../repositories/chat_repository.dart';
import '../services/user_profile_service.dart';
import '../utils/chat_preferences.dart';

class ChatViewModel extends ChangeNotifier {
  final ChatRepository _chatRepository;
  final ChatPreferencesManager _preferencesManager;

  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _error;
  bool _shouldScrollToBottom = false;

  // ENHANCED: Throttling for smooth scrolling during streaming
  Timer? _updateThrottleTimer;
  bool _hasPendingUpdate = false;

  ChatViewModel({
    required ChatRepository chatRepository,
    required ChatPreferencesManager preferencesManager,
  }) : _chatRepository = chatRepository,
       _preferencesManager = preferencesManager {
    _loadChatHistory();
  }

  // Getters
  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get shouldScrollToBottom => _shouldScrollToBottom;

  // ADD: Getters untuk preferences
  bool get isStreaming => _preferencesManager.isStreamingEnabled;
  bool get isAutoScrollEnabled => _preferencesManager.isAutoScrollEnabled;
  bool get isTypingIndicatorEnabled =>
      _preferencesManager.isTypingIndicatorEnabled;
  String get preferredLanguage => _preferencesManager.preferredLanguage;

  Future<void> _loadChatHistory() async {
    try {
      _messages = await _chatRepository.getChatHistory();

      // CHECK: Handle profile recovery if needed
      await _checkProfileRecovery();

      notifyListeners();
    } catch (e) {
      _error = 'Gagal memuat riwayat chat: $e';
      notifyListeners();
    }
  }

  // ADD: Check and handle profile recovery
  Future<void> _checkProfileRecovery() async {
    try {
      final userProfile = await _chatRepository.getUserProfile();
      if (userProfile == null) {
        // Check if recovery is needed via UserProfileService directly
        final userProfileService = UserProfileService(
          await SharedPreferences.getInstance(),
        );
        if (userProfileService.needsProfileRecovery) {
          _error =
              'Profil pengguna perlu dipulihkan. Silakan setup ulang profil Anda.';
          await userProfileService.markProfileRecoveryComplete();
        }
      }
    } catch (e) {
      print('Error checking profile recovery: $e');
    }
  }

  // ENHANCED: Add personalized welcome messages with error handling
  void addPersonalizedWelcomeMessages(String userName) {
    try {
      final welcomeMessages = [
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          message:
              'Halo ${userName.isNotEmpty ? userName : 'User'}! 👋\n\nSelamat datang di DrAI, asisten AI untuk deteksi dan konsultasi diabetes. Saya di sini untuk membantu Anda memahami kondisi kesehatan dan memberikan saran yang tepat.',
          isFromUser: false,
          timestamp: DateTime.now(),
        ),
        ChatMessage(
          id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
          message:
              '🩺 **Yang bisa saya bantu:**\n\n'
              '• Interpretasi hasil deteksi diabetes\n'
              '• Penjelasan gejala diabetes pada lidah\n'
              '• Saran pola makan dan gaya hidup sehat\n'
              '• Tips pencegahan diabetes\n'
              '• Rekomendasi kapan harus konsultasi dokter\n\n'
              'Silakan tanyakan apa saja tentang diabetes${userName.isNotEmpty ? ', $userName' : ''}! 😊',
          isFromUser: false,
          timestamp: DateTime.now().add(const Duration(seconds: 1)),
        ),
      ];

      _messages.addAll(welcomeMessages);

      // USE: Gunakan preferences untuk scroll behavior
      if (isAutoScrollEnabled) {
        _shouldScrollToBottom = true;
      }

      // Save welcome messages with error handling
      for (final message in welcomeMessages) {
        _chatRepository.saveChatMessage(message).catchError((e) {
          print('Error saving welcome message: $e');
        });
      }

      notifyListeners();
    } catch (e) {
      print('Error adding personalized welcome messages: $e');
      // Fallback to simple welcome
      addSimpleWelcomeMessage();
    }
  }

  // ADD: Simple fallback welcome message
  void addSimpleWelcomeMessage() {
    try {
      final welcomeMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        message:
            'Selamat datang di DrAI! Saya siap membantu Anda dengan konsultasi diabetes. Silakan tanyakan apa saja! 😊',
        isFromUser: false,
        timestamp: DateTime.now(),
      );

      _messages.add(welcomeMessage);

      if (isAutoScrollEnabled) {
        _shouldScrollToBottom = true;
      }

      _chatRepository.saveChatMessage(welcomeMessage).catchError((e) {
        print('Error saving simple welcome message: $e');
      });

      notifyListeners();
    } catch (e) {
      print('Error adding simple welcome message: $e');
    }
  }

  // ADD: Method untuk mengatur preferences
  Future<void> setStreamingEnabled(bool enabled) async {
    await _preferencesManager.setStreamingEnabled(enabled);
    notifyListeners();
  }

  Future<void> setAutoScrollEnabled(bool enabled) async {
    await _preferencesManager.setAutoScrollEnabled(enabled);
    notifyListeners();
  }

  Future<void> setTypingIndicatorEnabled(bool enabled) async {
    await _preferencesManager.setTypingIndicatorEnabled(enabled);
    notifyListeners();
  }

  Future<void> setPreferredLanguage(String language) async {
    await _preferencesManager.setPreferredLanguage(language);
    notifyListeners();
  }

  // Legacy method untuk backward compatibility
  void addWelcomeMessages() {
    addPersonalizedWelcomeMessages('User');
  }

  Future<void> sendMessage(String messageText) async {
    if (messageText.trim().isEmpty) return;

    // Add user message
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: messageText,
      isFromUser: true,
      timestamp: DateTime.now(),
    );

    _messages.add(userMessage);

    // USE: Gunakan preferences untuk scroll behavior
    if (isAutoScrollEnabled) {
      _shouldScrollToBottom = true;
    }

    notifyListeners();

    // Save user message
    await _chatRepository.saveChatMessage(userMessage);

    // Create AI response placeholder
    final aiMessageId = (DateTime.now().millisecondsSinceEpoch + 1).toString();
    final aiMessage = ChatMessage(
      id: aiMessageId,
      message: '',
      isFromUser: false,
      timestamp: DateTime.now(),
      isLoading: true,
    );

    _messages.add(aiMessage);
    _isLoading = true;
    notifyListeners();

    try {
      // USE: Gunakan preferences untuk streaming vs non-streaming
      if (isStreaming) {
        await _handleStreamingResponseWithAutoSync(messageText, aiMessageId);
      } else {
        await _handleNonStreamingResponseWithAutoSync(messageText, aiMessageId);
      }
    } catch (e) {
      _handleMessageError(aiMessageId, e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ENHANCED: Professional streaming response handler
  Future<void> _handleStreamingResponse(
    String messageText,
    String aiMessageId,
  ) async {
    final streamController = StreamController<StreamResponse>();
    Timer? timeoutTimer;
    bool isStreamActive = false;

    try {
      // Set timeout for streaming
      timeoutTimer = Timer(const Duration(seconds: 60), () {
        if (isStreamActive) {
          streamController.addError('Timeout: Streaming took too long');
        }
      });

      // Initialize streaming state
      final messageIndex = _messages.indexWhere((msg) => msg.id == aiMessageId);
      if (messageIndex == -1) return;

      // Start streaming indicator
      _messages[messageIndex] = _messages[messageIndex].copyWith(
        isLoading: true,
        isStreaming: true,
        streamingText: '',
        hasError: false,
      );
      notifyListeners();

      isStreamActive = true;
      String accumulatedText = '';
      int chunkCount = 0;

      await for (final response in _chatRepository.sendMessageStreamWithContext(
        messageText,
        preferredLanguage: preferredLanguage,
      )) {
        final currentMessageIndex = _messages.indexWhere(
          (msg) => msg.id == aiMessageId,
        );
        if (currentMessageIndex == -1) break;

        if (response is StreamStarted) {
          _messages[currentMessageIndex] = _messages[currentMessageIndex]
              .copyWith(
                isLoading: false,
                isStreaming: true,
                streamingText: '🤔 DrAI sedang memikirkan respons...',
              );

          // Auto scroll to show typing indicator
          if (isAutoScrollEnabled) {
            _shouldScrollToBottom = true;
          }
        } else if (response is StreamChunk) {
          chunkCount++;
          accumulatedText = response.text;

          _messages[currentMessageIndex] = _messages[currentMessageIndex]
              .copyWith(
                streamingText: accumulatedText,
                isLoading: false,
                isStreaming: true,
                hasError: false,
              ); // ENHANCED: Throttled scrolling to prevent UI lag
          if (isAutoScrollEnabled &&
              (chunkCount % 5 == 0 || // Less frequent scroll triggers
                  response.text.length > 200 || // Higher threshold
                  chunkCount == 1)) {
            // Always scroll on first chunk
            _shouldScrollToBottom = true;
          }
        } else if (response is StreamComplete) {
          _messages[currentMessageIndex] = _messages[currentMessageIndex]
              .copyWith(
                message: response.fullText,
                streamingText: '',
                isLoading: false,
                isStreaming: false,
                hasError: false,
              );

          // Save final AI message
          await _chatRepository.saveChatMessage(_messages[currentMessageIndex]);

          // Final scroll to ensure complete message is visible
          if (isAutoScrollEnabled) {
            _shouldScrollToBottom = true;
          }

          isStreamActive = false;
          break;
        } else if (response is StreamError) {
          _messages[currentMessageIndex] = _messages[currentMessageIndex]
              .copyWith(
                message: _getErrorMessage(response.error),
                streamingText: '',
                isLoading: false,
                isStreaming: false,
                hasError: true,
              );
          _error = response.error;
          isStreamActive = false;
          break;
        }

        notifyListeners();
      }
    } catch (e) {
      final messageIndex = _messages.indexWhere((msg) => msg.id == aiMessageId);
      if (messageIndex != -1) {
        _messages[messageIndex] = _messages[messageIndex].copyWith(
          message: _getErrorMessage(e.toString()),
          streamingText: '',
          isLoading: false,
          isStreaming: false,
          hasError: true,
        );
      }
      _error = 'Streaming error: $e';
      notifyListeners();
    } finally {
      timeoutTimer?.cancel();
      isStreamActive = false;
      streamController.close();
    }
  }

  // ENHANCED: Professional streaming response handler with deduplication
  Future<void> _handleStreamingResponseWithAutoSync(
    String messageText,
    String aiMessageId,
  ) async {
    Timer? timeoutTimer;
    bool isStreamActive = false;
    String lastReceivedText = '';

    try {
      // Set timeout for streaming
      timeoutTimer = Timer(const Duration(seconds: 60), () {
        if (isStreamActive) {
          _handleMessageError(aiMessageId, 'Timeout: Respons AI terlalu lama');
        }
      });

      // Initialize streaming state
      final messageIndex = _messages.indexWhere((msg) => msg.id == aiMessageId);
      if (messageIndex == -1) return;

      // Start streaming indicator
      _messages[messageIndex] = _messages[messageIndex].copyWith(
        isLoading: false,
        isStreaming: true,
        streamingText:
            '🤔 DrAI sedang menganalisis berdasarkan hasil deteksi...',
        hasError: false,
      );
      notifyListeners();

      isStreamActive = true;

      await for (final response
          in _chatRepository.sendMessageStreamWithAutoSync(
            messageText,
            preferredLanguage: preferredLanguage,
          )) {
        final currentMessageIndex = _messages.indexWhere(
          (msg) => msg.id == aiMessageId,
        );
        if (currentMessageIndex == -1) break;

        if (response is StreamStarted) {
          _messages[currentMessageIndex] = _messages[currentMessageIndex]
              .copyWith(
                isLoading: false,
                isStreaming: true,
                streamingText: '✨ DrAI memulai respons...',
              );
          notifyListeners();
        } else if (response is StreamChunk) {
          // Avoid duplicate text by checking if new text is different
          if (response.text != lastReceivedText && response.text.isNotEmpty) {
            lastReceivedText = response.text;

            _messages[currentMessageIndex] = _messages[currentMessageIndex]
                .copyWith(
                  isStreaming: true,
                  streamingText: response.text,
                  isLoading: false,
                  hasError: false,
                );

            if (isAutoScrollEnabled) {
              _shouldScrollToBottom = true;
            }
            notifyListeners();
          }
        } else if (response is StreamComplete) {
          final finalMessageIndex = _messages.indexWhere(
            (msg) => msg.id == aiMessageId,
          );
          if (finalMessageIndex != -1) {
            _messages[finalMessageIndex] = _messages[finalMessageIndex]
                .copyWith(
                  message: response.fullText,
                  isStreaming: false,
                  isLoading: false,
                  streamingText: '',
                  hasError: false,
                );

            // Save AI message
            await _chatRepository.saveChatMessage(_messages[finalMessageIndex]);

            if (isAutoScrollEnabled) {
              _shouldScrollToBottom = true;
            }
            notifyListeners();
          }
          break;
        } else if (response is StreamError) {
          _handleMessageError(aiMessageId, response.error);
          break;
        }
      }
    } catch (e) {
      _handleMessageError(aiMessageId, e);
    } finally {
      timeoutTimer?.cancel();
      isStreamActive = false;
    }
  }

  // ENHANCED: Detection context streaming with professional handling
  Future<void> _handleStreamingResponseWithDetectionContext(
    String messageText,
    String aiMessageId,
    DetectionResult? detectionResult,
  ) async {
    Timer? timeoutTimer;
    bool isStreamActive = false;
    String lastReceivedText = '';

    try {
      // Set timeout for streaming
      timeoutTimer = Timer(const Duration(seconds: 60), () {
        if (isStreamActive) {
          _handleMessageError(aiMessageId, 'Timeout: Respons AI terlalu lama');
        }
      });

      // Initialize streaming state
      final messageIndex = _messages.indexWhere((msg) => msg.id == aiMessageId);
      if (messageIndex == -1) return;

      // Professional status message based on detection context
      final statusMessage = detectionResult != null
          ? '🔬 DrAI menganalisis hasil deteksi ${detectionResult.className}...'
          : '🤔 DrAI sedang memproses pertanyaan...';

      _messages[messageIndex] = _messages[messageIndex].copyWith(
        isLoading: false,
        isStreaming: true,
        streamingText: statusMessage,
        hasError: false,
      );
      notifyListeners();

      isStreamActive = true;

      await for (final response
          in _chatRepository.sendMessageStreamWithDetectionContext(
            messageText,
            detectionResult: detectionResult,
            preferredLanguage: preferredLanguage,
          )) {
        final currentMessageIndex = _messages.indexWhere(
          (msg) => msg.id == aiMessageId,
        );
        if (currentMessageIndex == -1) break;

        if (response is StreamStarted) {
          _messages[currentMessageIndex] = _messages[currentMessageIndex]
              .copyWith(
                isLoading: false,
                isStreaming: true,
                streamingText: '✨ DrAI memulai konsultasi...',
              );
          notifyListeners();
        } else if (response is StreamChunk) {
          // Prevent duplicate and empty responses
          if (response.text != lastReceivedText &&
              response.text.trim().isNotEmpty &&
              response.text.length > lastReceivedText.length) {
            lastReceivedText = response.text;

            _messages[currentMessageIndex] = _messages[currentMessageIndex]
                .copyWith(
                  isStreaming: true,
                  streamingText: response.text,
                  isLoading: false,
                  hasError: false,
                );

            if (isAutoScrollEnabled) {
              _shouldScrollToBottom = true;
            }
            notifyListeners();
          }
        } else if (response is StreamComplete) {
          final finalMessageIndex = _messages.indexWhere(
            (msg) => msg.id == aiMessageId,
          );
          if (finalMessageIndex != -1) {
            _messages[finalMessageIndex] = _messages[finalMessageIndex]
                .copyWith(
                  message: response.fullText,
                  isStreaming: false,
                  isLoading: false,
                  streamingText: '',
                  hasError: false,
                );

            // Save AI message
            await _chatRepository.saveChatMessage(_messages[finalMessageIndex]);

            if (isAutoScrollEnabled) {
              _shouldScrollToBottom = true;
            }
            notifyListeners();
          }
          break;
        } else if (response is StreamError) {
          _handleMessageError(aiMessageId, response.error);
          break;
        }
      }
    } catch (e) {
      _handleMessageError(aiMessageId, e);
    } finally {
      timeoutTimer?.cancel();
      isStreamActive = false;
    }
  }

  // ADD: Auto-sync non-streaming response handler
  Future<void> _handleNonStreamingResponseWithAutoSync(
    String messageText,
    String aiMessageId,
  ) async {
    final result = await _chatRepository.sendMessageWithAutoSync(messageText);
    final messageIndex = _messages.indexWhere((msg) => msg.id == aiMessageId);

    if (messageIndex == -1) return;

    if (result.isSuccess) {
      _messages[messageIndex] = _messages[messageIndex].copyWith(
        message: result.value,
        isLoading: false,
        isStreaming: false,
      );

      // Save AI message
      await _chatRepository.saveChatMessage(_messages[messageIndex]);

      // USE: Auto scroll based on preferences
      if (isAutoScrollEnabled) {
        _shouldScrollToBottom = true;
      }
    } else {
      _messages[messageIndex] = _messages[messageIndex].copyWith(
        message: 'Maaf, terjadi kesalahan saat memproses pesan Anda.',
        isLoading: false,
        hasError: true,
      );
      _error = result.error.toString();
    }
  }

  // ADD: Detection context non-streaming response handler
  Future<void> _handleNonStreamingResponseWithDetectionContext(
    String messageText,
    String aiMessageId,
    DetectionResult? detectionResult,
  ) async {
    final result = await _chatRepository.sendMessageWithDetectionContext(
      messageText,
      detectionResult: detectionResult,
    );
    final messageIndex = _messages.indexWhere((msg) => msg.id == aiMessageId);

    if (messageIndex == -1) return;

    if (result.isSuccess) {
      _messages[messageIndex] = _messages[messageIndex].copyWith(
        message: result.value,
        isLoading: false,
        isStreaming: false,
      );

      // Save AI message
      await _chatRepository.saveChatMessage(_messages[messageIndex]);

      // USE: Auto scroll based on preferences
      if (isAutoScrollEnabled) {
        _shouldScrollToBottom = true;
      }
    } else {
      _messages[messageIndex] = _messages[messageIndex].copyWith(
        message: 'Maaf, terjadi kesalahan saat memproses pesan Anda.',
        isLoading: false,
        hasError: true,
      );
      _error = result.error.toString();
    }
  }

  // ADD: Method untuk handling non-streaming response
  Future<void> _handleNonStreamingResponse(
    String messageText,
    String aiMessageId,
  ) async {
    final result = await _chatRepository.sendMessage(messageText);
    final messageIndex = _messages.indexWhere((msg) => msg.id == aiMessageId);

    if (messageIndex == -1) return;

    if (result.isSuccess) {
      _messages[messageIndex] = _messages[messageIndex].copyWith(
        message: result.value,
        isLoading: false,
        isStreaming: false,
      );

      // Save AI message
      await _chatRepository.saveChatMessage(_messages[messageIndex]);

      // USE: Auto scroll based on preferences
      if (isAutoScrollEnabled) {
        _shouldScrollToBottom = true;
      }
    } else {
      _messages[messageIndex] = _messages[messageIndex].copyWith(
        message: 'Maaf, terjadi kesalahan saat memproses pesan Anda.',
        isLoading: false,
        hasError: true,
      );
      _error = result.error.toString();
    }
  }

  // ADD: Method untuk handling error
  void _handleMessageError(String aiMessageId, dynamic error) {
    final messageIndex = _messages.indexWhere((msg) => msg.id == aiMessageId);
    if (messageIndex != -1) {
      _messages[messageIndex] = _messages[messageIndex].copyWith(
        message: 'Maaf, terjadi kesalahan saat memproses pesan Anda.',
        isLoading: false,
        hasError: true,
      );
    }
    _error = 'Terjadi kesalahan: $error';
  }

  Future<void> retryMessage(ChatMessage message) async {
    if (message.isFromUser) return;

    final messageIndex = _messages.indexWhere((msg) => msg.id == message.id);
    if (messageIndex == -1) return;

    // Find the previous user message
    String? previousUserMessage;
    for (int i = messageIndex - 1; i >= 0; i--) {
      if (_messages[i].isFromUser) {
        previousUserMessage = _messages[i].message;
        break;
      }
    }

    if (previousUserMessage == null) return;

    // Reset the message
    _messages[messageIndex] = _messages[messageIndex].copyWith(
      message: '',
      isLoading: true,
      hasError: false,
      isStreaming: false,
      streamingText: '',
    );

    _isLoading = true;
    notifyListeners();

    try {
      // USE: Gunakan preferences untuk retry method
      if (isStreaming) {
        await _handleRetryStreamingResponse(previousUserMessage, messageIndex);
      } else {
        await _handleRetryNonStreamingResponse(
          previousUserMessage,
          messageIndex,
        );
      }
    } catch (e) {
      _messages[messageIndex] = _messages[messageIndex].copyWith(
        message: 'Maaf, terjadi kesalahan saat memproses pesan Anda.',
        isLoading: false,
        hasError: true,
      );
      _error = 'Terjadi kesalahan: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ENHANCED: Professional retry streaming
  Future<void> _handleRetryStreamingResponse(
    String message,
    int messageIndex,
  ) async {
    Timer? retryTimeout;
    bool isRetryActive = false;

    try {
      // Set retry timeout
      retryTimeout = Timer(const Duration(seconds: 60), () {
        if (isRetryActive) {
          _messages[messageIndex] = _messages[messageIndex].copyWith(
            message: _getErrorMessage('Timeout during retry'),
            isLoading: false,
            isStreaming: false,
            hasError: true,
          );
          notifyListeners();
        }
      });

      isRetryActive = true;
      String accumulatedText = '';
      int retryChunkCount = 0;

      // Initialize retry state
      _messages[messageIndex] = _messages[messageIndex].copyWith(
        streamingText: '🔄 DrAI mencoba lagi...',
        isLoading: false,
        isStreaming: true,
        hasError: false,
      );
      notifyListeners();

      await for (final response in _chatRepository.sendMessageStreamWithContext(
        message,
        preferredLanguage: preferredLanguage,
      )) {
        if (response is StreamStarted) {
          _messages[messageIndex] = _messages[messageIndex].copyWith(
            streamingText: '✨ DrAI siap memberikan respons...',
            isLoading: false,
            isStreaming: true,
          );
        } else if (response is StreamChunk) {
          retryChunkCount++;
          accumulatedText = response.text;

          _messages[messageIndex] = _messages[messageIndex].copyWith(
            streamingText: accumulatedText,
            isLoading: false,
            isStreaming: true,
            hasError: false,
          );

          if (isAutoScrollEnabled && retryChunkCount % 2 == 0) {
            _shouldScrollToBottom = true;
          }
        } else if (response is StreamComplete) {
          _messages[messageIndex] = _messages[messageIndex].copyWith(
            message: response.fullText,
            streamingText: '',
            isLoading: false,
            isStreaming: false,
            hasError: false,
          );

          // Save updated AI message
          await _chatRepository.saveChatMessage(_messages[messageIndex]);

          if (isAutoScrollEnabled) {
            _shouldScrollToBottom = true;
          }

          isRetryActive = false;
          break;
        } else if (response is StreamError) {
          _messages[messageIndex] = _messages[messageIndex].copyWith(
            message: _getErrorMessage(response.error),
            streamingText: '',
            isLoading: false,
            isStreaming: false,
            hasError: true,
          );
          _error = 'Retry failed: ${response.error}';
          isRetryActive = false;
          break;
        }

        notifyListeners();
      }
    } catch (e) {
      _messages[messageIndex] = _messages[messageIndex].copyWith(
        message: _getErrorMessage('Retry failed: $e'),
        streamingText: '',
        isLoading: false,
        isStreaming: false,
        hasError: true,
      );
      _error = 'Retry streaming error: $e';
      notifyListeners();
    } finally {
      retryTimeout?.cancel();
      isRetryActive = false;
    }
  }

  // ADD: Method untuk retry non-streaming
  Future<void> _handleRetryNonStreamingResponse(
    String message,
    int messageIndex,
  ) async {
    final result = await _chatRepository.sendMessage(message);

    if (result.isSuccess) {
      _messages[messageIndex] = _messages[messageIndex].copyWith(
        message: result.value,
        isLoading: false,
        isStreaming: false,
      );

      // Save updated AI message
      await _chatRepository.saveChatMessage(_messages[messageIndex]);

      if (isAutoScrollEnabled) {
        _shouldScrollToBottom = true;
      }
    } else {
      _messages[messageIndex] = _messages[messageIndex].copyWith(
        message: 'Maaf, terjadi kesalahan saat memproses pesan Anda.',
        isLoading: false,
        hasError: true,
      );
      _error = result.error.toString();
    }
  }

  Future<void> clearChat() async {
    try {
      await _chatRepository.clearChatHistory();
      _messages.clear();

      // USE: Reset preferences setelah clear chat
      await _preferencesManager.resetToDefaults();

      notifyListeners();
    } catch (e) {
      _error = 'Gagal menghapus chat: $e';
      notifyListeners();
    }
  }

  // ADD: Export chat preferences
  Map<String, dynamic> exportPreferences() {
    return _preferencesManager.exportSettings();
  }

  // ADD: Import chat preferences
  Future<void> importPreferences(Map<String, dynamic> settings) async {
    await _preferencesManager.importSettings(settings);
    notifyListeners();
  }

  // ADD: Reset preferences to default
  Future<void> resetPreferences() async {
    await _preferencesManager.resetToDefaults();
    notifyListeners();
  }

  void scrollHandled() {
    _shouldScrollToBottom = false;
  }

  void clearError() {
    _error = null;
  }

  @override
  void dispose() {
    _updateThrottleTimer?.cancel();
    _chatRepository.dispose();
    super.dispose();
  }

  // ENHANCED: Professional error message handler
  String _getErrorMessage(String error) {
    if (error.toLowerCase().contains('network')) {
      return '🌐 **Koneksi Bermasalah**\n\nSeperti ada masalah dengan koneksi internet. Coba periksa koneksi Anda dan kirim ulang pesan.';
    } else if (error.toLowerCase().contains('timeout')) {
      return '⏰ **Waktu Habis**\n\nDrAI membutuhkan waktu lebih lama dari biasanya. Coba kirim ulang pesan atau periksa koneksi internet Anda.';
    } else if (error.toLowerCase().contains('api') ||
        error.toLowerCase().contains('server')) {
      return '🔧 **Server Sibuk**\n\nServer DrAI sedang sibuk saat ini. Mohon tunggu sebentar dan coba lagi.';
    } else if (error.toLowerCase().contains('rate limit')) {
      return '⚡ **Terlalu Banyak Permintaan**\n\nAnda mengirim pesan terlalu cepat. Tunggu sebentar sebelum mengirim pesan lagi.';
    } else {
      return '❌ **Terjadi Kesalahan**\n\nMaaf, DrAI mengalami kesalahan teknis. Silakan coba lagi atau hubungi dukungan jika masalah berlanjut.';
    }
  }

  // ENHANCED: Add streaming performance metrics
  void addStreamingMetrics() {
    // This method can be used to track streaming performance
    notifyListeners();
  }

  // ENHANCED: Check streaming health
  bool get isStreamingHealthy => !_isLoading && _error == null;

  // ENHANCED: Fast streaming mode for impatient users
  bool get isFastStreamingMode => _preferencesManager.isStreamingEnabled;

  // ENHANCED: Skip to end functionality
  Future<void> skipToEnd(String messageId) async {
    try {
      final messageIndex = _messages.indexWhere((msg) => msg.id == messageId);
      if (messageIndex == -1 || !_messages[messageIndex].isStreaming) return;

      // Find the streaming message and complete it immediately
      final currentMessage = _messages[messageIndex];
      if (currentMessage.streamingText.isNotEmpty) {
        _messages[messageIndex] = currentMessage.copyWith(
          message: currentMessage.streamingText,
          streamingText: '',
          isStreaming: false,
          isLoading: false,
        );

        // Save the completed message
        await _chatRepository.saveChatMessage(_messages[messageIndex]);

        if (isAutoScrollEnabled) {
          _shouldScrollToBottom = true;
        }

        notifyListeners();
      }
    } catch (e) {
      print('Error skipping to end: $e');
    }
  }

  // ENHANCED: Show instant preview of long responses
  void showInstantPreview(String messageId) {
    try {
      final messageIndex = _messages.indexWhere((msg) => msg.id == messageId);
      if (messageIndex == -1) return;

      final currentMessage = _messages[messageIndex];
      if (currentMessage.streamingText.length > 100) {
        // Show a brief preview of the complete response structure
        final preview = _generateResponsePreview(currentMessage.streamingText);

        _messages[messageIndex] = currentMessage.copyWith(
          streamingText: preview,
        );

        notifyListeners();
      }
    } catch (e) {
      print('Error showing instant preview: $e');
    }
  }

  String _generateResponsePreview(String currentText) {
    // Generate a preview showing response structure
    final words = currentText.split(' ');
    if (words.length > 20) {
      return '${words.take(15).join(' ')}... [respons lengkap sedang dimuat]';
    }
    return currentText;
  }

  // ENHANCED: Throttled update to prevent UI lag during streaming
  void _throttledNotifyListeners() {
    if (_updateThrottleTimer?.isActive ?? false) {
      _hasPendingUpdate = true;
      return;
    }

    _updateThrottleTimer = Timer(const Duration(milliseconds: 150), () {
      if (_hasPendingUpdate) {
        _hasPendingUpdate = false;
        super.notifyListeners();
      }
    });

    super.notifyListeners();
  }

  @override
  void notifyListeners() {
    // Use throttled version for streaming updates
    _throttledNotifyListeners();
  }

  // ENHANCED: Stop generation functionality like ChatGPT
  void stopGeneration(String messageId) {
    try {
      final messageIndex = _messages.indexWhere((msg) => msg.id == messageId);
      if (messageIndex == -1 || !_messages[messageIndex].isStreaming) return;

      final currentMessage = _messages[messageIndex];
      _messages[messageIndex] = currentMessage.copyWith(
        message: currentMessage.streamingText.isNotEmpty
            ? '${currentMessage.streamingText}\n\n[Generasi dihentikan oleh pengguna]'
            : '[Generasi dihentikan oleh pengguna]',
        streamingText: '',
        isStreaming: false,
        isLoading: false,
        hasError: false,
      );

      // Save the stopped message
      _chatRepository.saveChatMessage(_messages[messageIndex]);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error stopping generation: $e');
    }
  }

  // TAMBAHAN: Send message dengan konteks hasil deteksi
  Future<void> sendMessageWithDetectionContext(
    String message, {
    DetectionResult? detectionResult,
  }) async {
    if (message.trim().isEmpty) return;

    // Add user message
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: message,
      isFromUser: true,
      timestamp: DateTime.now(),
    );

    _messages.add(userMessage);

    // USE: Gunakan preferences untuk scroll behavior
    if (isAutoScrollEnabled) {
      _shouldScrollToBottom = true;
    }

    notifyListeners();

    // Save user message
    await _chatRepository.saveChatMessage(userMessage);

    // Create AI response placeholder
    final aiMessageId = (DateTime.now().millisecondsSinceEpoch + 1).toString();
    final aiMessage = ChatMessage(
      id: aiMessageId,
      message: '',
      isFromUser: false,
      timestamp: DateTime.now(),
      isLoading: true,
    );

    _messages.add(aiMessage);
    _isLoading = true;
    notifyListeners();

    try {
      // USE: Gunakan preferences untuk streaming vs non-streaming dengan detection context
      if (isStreaming) {
        await _handleStreamingResponseWithDetectionContext(
          message,
          aiMessageId,
          detectionResult,
        );
      } else {
        await _handleNonStreamingResponseWithDetectionContext(
          message,
          aiMessageId,
          detectionResult,
        );
      }
    } catch (e) {
      _handleMessageError(aiMessageId, e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
