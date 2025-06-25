import 'package:shared_preferences/shared_preferences.dart';

class ChatPreferences {
  static const String _isFirstTimeChatKey = 'is_first_time_chat';
  static const String _isStreamingEnabledKey = 'is_streaming_enabled';
  static const String _isAutoScrollEnabledKey = 'is_auto_scroll_enabled';
  static const String _isTypingIndicatorEnabledKey =
      'is_typing_indicator_enabled';
  static const String _preferredLanguageKey = 'preferred_language';
  static const String _chatThemeKey = 'chat_theme';
  static const String _messageTextSizeKey = 'message_text_size';
  static const String _isWelcomeMessageShownKey = 'is_welcome_message_shown';

  // ENHANCED: Streaming speed preferences
  static const String _streamingSpeedKey = 'streaming_speed';

  final SharedPreferences _prefs;

  ChatPreferences(this._prefs);

  // Existing getters/setters
  bool get isFirstTimeChat => _prefs.getBool(_isFirstTimeChatKey) ?? true;
  set isFirstTimeChat(bool value) => _prefs.setBool(_isFirstTimeChatKey, value);

  bool get isWelcomeMessageShown =>
      _prefs.getBool(_isWelcomeMessageShownKey) ?? false;
  set isWelcomeMessageShown(bool value) =>
      _prefs.setBool(_isWelcomeMessageShownKey, value);

  // ADD: New getters/setters for missing properties
  bool get isStreamingEnabled => _prefs.getBool(_isStreamingEnabledKey) ?? true;
  set isStreamingEnabled(bool value) =>
      _prefs.setBool(_isStreamingEnabledKey, value);

  bool get isAutoScrollEnabled =>
      _prefs.getBool(_isAutoScrollEnabledKey) ?? true;
  set isAutoScrollEnabled(bool value) =>
      _prefs.setBool(_isAutoScrollEnabledKey, value);

  bool get isTypingIndicatorEnabled =>
      _prefs.getBool(_isTypingIndicatorEnabledKey) ?? true;
  set isTypingIndicatorEnabled(bool value) =>
      _prefs.setBool(_isTypingIndicatorEnabledKey, value);

  String get preferredLanguage =>
      _prefs.getString(_preferredLanguageKey) ?? 'id';
  set preferredLanguage(String value) =>
      _prefs.setString(_preferredLanguageKey, value);

  String get chatTheme => _prefs.getString(_chatThemeKey) ?? 'light';
  set chatTheme(String value) => _prefs.setString(_chatThemeKey, value);

  double get messageTextSize => _prefs.getDouble(_messageTextSizeKey) ?? 14.0;
  set messageTextSize(double value) =>
      _prefs.setDouble(_messageTextSizeKey, value);

  // ENHANCED: Streaming speed preferences
  // Streaming speed: 'slow', 'normal', 'fast', 'instant'
  String get streamingSpeed =>
      _prefs.getString(_streamingSpeedKey) ?? 'fast'; // Default to fast
  set streamingSpeed(String value) =>
      _prefs.setString(_streamingSpeedKey, value);

  // Get speed multiplier for delays
  double get speedMultiplier {
    switch (streamingSpeed) {
      case 'slow':
        return 2.0; // 2x slower
      case 'normal':
        return 1.0; // Normal speed
      case 'fast':
        return 0.5; // 2x faster (current implementation)
      case 'instant':
        return 0.1; // Nearly instant
      default:
        return 0.5; // Default to fast
    }
  }

  // Export all settings
  Map<String, dynamic> exportSettings() {
    return {
      'isFirstTimeChat': isFirstTimeChat,
      'isWelcomeMessageShown': isWelcomeMessageShown,
      'isStreamingEnabled': isStreamingEnabled,
      'isAutoScrollEnabled': isAutoScrollEnabled,
      'isTypingIndicatorEnabled': isTypingIndicatorEnabled,
      'preferredLanguage': preferredLanguage,
      'chatTheme': chatTheme,
      'messageTextSize': messageTextSize,
      'streamingSpeed': streamingSpeed,
    };
  }

  // Import settings
  Future<void> importSettings(Map<String, dynamic> settings) async {
    if (settings.containsKey('isFirstTimeChat')) {
      isFirstTimeChat = settings['isFirstTimeChat'] as bool;
    }
    if (settings.containsKey('isWelcomeMessageShown')) {
      isWelcomeMessageShown = settings['isWelcomeMessageShown'] as bool;
    }
    if (settings.containsKey('isStreamingEnabled')) {
      isStreamingEnabled = settings['isStreamingEnabled'] as bool;
    }
    if (settings.containsKey('isAutoScrollEnabled')) {
      isAutoScrollEnabled = settings['isAutoScrollEnabled'] as bool;
    }
    if (settings.containsKey('isTypingIndicatorEnabled')) {
      isTypingIndicatorEnabled = settings['isTypingIndicatorEnabled'] as bool;
    }
    if (settings.containsKey('preferredLanguage')) {
      preferredLanguage = settings['preferredLanguage'] as String;
    }
    if (settings.containsKey('chatTheme')) {
      chatTheme = settings['chatTheme'] as String;
    }
    if (settings.containsKey('messageTextSize')) {
      messageTextSize = settings['messageTextSize'] as double;
    }
    if (settings.containsKey('streamingSpeed')) {
      streamingSpeed = settings['streamingSpeed'] as String;
    }
  }

  // Reset to defaults
  Future<void> resetToDefaults() async {
    await _prefs.remove(_isFirstTimeChatKey);
    await _prefs.remove(_isWelcomeMessageShownKey);
    await _prefs.remove(_isStreamingEnabledKey);
    await _prefs.remove(_isAutoScrollEnabledKey);
    await _prefs.remove(_isTypingIndicatorEnabledKey);
    await _prefs.remove(_preferredLanguageKey);
    await _prefs.remove(_chatThemeKey);
    await _prefs.remove(_messageTextSizeKey);
    await _prefs.remove(_streamingSpeedKey);
  }

  // Clear all preferences
  Future<void> clearAll() async {
    await resetToDefaults();
  }
}

class ChatPreferencesManager {
  final ChatPreferences _preferences;

  ChatPreferencesManager(this._preferences);

  // Migration and initialization
  Future<void> initialize() async {
    // Perform any necessary migrations here
    await _performMigrations();
  }

  Future<void> _performMigrations() async {
    // Add migration logic if needed in the future
    // For example, migrating old preference keys to new ones
  }

  // Getters - delegate to ChatPreferences
  bool get isStreamingEnabled => _preferences.isStreamingEnabled;
  bool get isAutoScrollEnabled => _preferences.isAutoScrollEnabled;
  bool get isTypingIndicatorEnabled => _preferences.isTypingIndicatorEnabled;
  String get preferredLanguage => _preferences.preferredLanguage;
  String get chatTheme => _preferences.chatTheme;
  double get messageTextSize => _preferences.messageTextSize;
  bool get isFirstTimeChat => _preferences.isFirstTimeChat;
  bool get isWelcomeMessageShown => _preferences.isWelcomeMessageShown;

  // ENHANCED: Streaming speed getters and setters
  String get streamingSpeed => _preferences.streamingSpeed;
  double get speedMultiplier => _preferences.speedMultiplier;

  // Setters with async support
  Future<void> setStreamingEnabled(bool enabled) async {
    _preferences.isStreamingEnabled = enabled;
  }

  Future<void> setAutoScrollEnabled(bool enabled) async {
    _preferences.isAutoScrollEnabled = enabled;
  }

  Future<void> setTypingIndicatorEnabled(bool enabled) async {
    _preferences.isTypingIndicatorEnabled = enabled;
  }

  Future<void> setPreferredLanguage(String language) async {
    _preferences.preferredLanguage = language;
  }

  Future<void> setChatTheme(String theme) async {
    _preferences.chatTheme = theme;
  }

  Future<void> setMessageTextSize(double size) async {
    _preferences.messageTextSize = size;
  }

  Future<void> setFirstTimeChat(bool isFirst) async {
    _preferences.isFirstTimeChat = isFirst;
  }

  Future<void> setWelcomeMessageShown(bool shown) async {
    _preferences.isWelcomeMessageShown = shown;
  }

  Future<void> setStreamingSpeed(String speed) async {
    _preferences.streamingSpeed = speed;
  }

  // Export/Import methods
  Map<String, dynamic> exportSettings() {
    return _preferences.exportSettings();
  }

  Future<void> importSettings(Map<String, dynamic> settings) async {
    await _preferences.importSettings(settings);
  }

  Future<void> resetToDefaults() async {
    await _preferences.resetToDefaults();
  }

  Future<void> clearAll() async {
    await _preferences.clearAll();
  }

  // Utility methods
  bool isDarkTheme() {
    return chatTheme == 'dark';
  }

  bool isLightTheme() {
    return chatTheme == 'light';
  }

  bool isSystemTheme() {
    return chatTheme == 'system';
  }

  String getLanguageDisplayName() {
    switch (preferredLanguage) {
      case 'id':
        return 'Bahasa Indonesia';
      case 'en':
        return 'English';
      case 'jv':
        return 'Bahasa Jawa';
      default:
        return 'Bahasa Indonesia';
    }
  }

  List<String> getSupportedLanguages() {
    return ['id', 'en', 'jv'];
  }

  List<String> getSupportedThemes() {
    return ['light', 'dark', 'system'];
  }

  // Validation methods
  bool isValidLanguage(String language) {
    return getSupportedLanguages().contains(language);
  }

  bool isValidTheme(String theme) {
    return getSupportedThemes().contains(theme);
  }

  bool isValidTextSize(double size) {
    return size >= 10.0 && size <= 24.0;
  }

  // Preset configurations
  Future<void> applyMinimalSettings() async {
    await setStreamingEnabled(false);
    await setAutoScrollEnabled(false);
    await setTypingIndicatorEnabled(false);
    await setMessageTextSize(12.0);
  }

  Future<void> applyRichSettings() async {
    await setStreamingEnabled(true);
    await setAutoScrollEnabled(true);
    await setTypingIndicatorEnabled(true);
    await setMessageTextSize(16.0);
  }

  Future<void> applyAccessibilitySettings() async {
    await setAutoScrollEnabled(true);
    await setTypingIndicatorEnabled(true);
    await setMessageTextSize(18.0);
    await setChatTheme('light'); // High contrast
  }

  // Debug methods
  Map<String, dynamic> getDebugInfo() {
    return {
      'version': '1.0.0',
      'settings': exportSettings(),
      'supportedLanguages': getSupportedLanguages(),
      'supportedThemes': getSupportedThemes(),
    };
  }

  @override
  String toString() {
    return 'ChatPreferencesManager(${exportSettings()})';
  }
}
