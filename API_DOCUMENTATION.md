# 🔌 API & Integration Documentation

## 📋 Daftar Isi
1. [API Architecture](#api-architecture)
2. [ML Model Integration](#ml-model-integration)
3. [Local Storage APIs](#local-storage-apis)
4. [External Integrations](#external-integrations)
5. [Configuration & Setup](#configuration--setup)
6. [Testing APIs](#testing-apis)

---

## 🏗️ API Architecture

### Service Layer Pattern
Aplikasi menggunakan **Service Layer Pattern** untuk memisahkan business logic dari UI components.

```
UI Layer (Screens/Widgets)
    ↓
Service Layer (Business Logic)
    ↓
Repository Layer (Data Access)
    ↓
Storage Layer (Local/Remote)
```

### Core Services API

#### Authentication API (`auth_service.dart`)

```dart
class AuthService {
  // Login user dengan credentials
  Future<AuthResult> login({
    required String username,
    required String password,
  });
  
  // Register user baru
  Future<AuthResult> register({
    required String username,
    required String email, 
    required String password,
    UserProfile? profile,
  });
  
  // Logout user dan clear session
  Future<void> logout();
  
  // Check authentication status
  Future<bool> isAuthenticated();
  
  // Get current user data
  Future<User?> getCurrentUser();
  
  // Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}

// Response Models
class AuthResult {
  final bool success;
  final String? message;
  final User? user;
  final String? token;
}
```

---

## 🤖 ML Model Integration

### TensorFlow Lite API (`ml_service.dart`)

```dart
class MLService {
  // Model Configuration
  static const int INPUT_SIZE = 180;
  static const int NUM_CHANNELS = 3;
  static const int NUM_CLASSES = 2;
  
  // Load model dari assets
  static Future<void> loadModel() async;
  
  // Main prediction method
  static Future<DetectionResult> predictImage(File imageFile);
  
  // Image preprocessing
  static Future<List<List<List<double>>>> preprocessImage(File imageFile);
  
  // Batch prediction (untuk multiple images)
  static Future<List<DetectionResult>> predictBatch(List<File> images);
  
  // Model info dan diagnostics
  static ModelInfo getModelInfo();
  
  // Clear cache
  static void clearCache();
}

// Model Response
class DetectionResult {
  final String id;
  final String imagePath;
  final String prediction;      // 'diabetes' | 'non_diabetes'
  final double confidence;      // 0.0 - 1.0
  final DateTime timestamp;
  final String interpretation;
  final List<String> recommendations;
  final Duration processingTime;
  final Map<String, dynamic> rawOutput;
  
  // Computed properties
  bool get isDiabetes => prediction == 'diabetes';
  bool get isHighConfidence => confidence > 0.8;
  String get riskLevel => _calculateRiskLevel();
}
```

### Model Usage Example

```dart
// Load model saat app startup
await MLService.loadModel();

// Predict image
File imageFile = File('path/to/image.jpg');
DetectionResult result = await MLService.predictImage(imageFile);

// Handle result
if (result.isDiabetes) {
  if (result.isHighConfidence) {
    // High risk - recommend immediate medical consultation
    showHighRiskDialog(result);
  } else {
    // Moderate risk - suggest monitoring
    showModeRiskDialog(result);
  }
} else {
  // Low risk - provide general health tips
  showLowRiskDialog(result);
}
```

---

## 💾 Local Storage APIs

### User Profile API (`user_profile_service.dart`)

```dart
class UserProfileService {
  final SharedPreferences _prefs;
  
  // Profile Management
  Future<UserProfile?> getProfile();
  Future<bool> saveProfile(UserProfile profile);
  Future<bool> updateProfile(Map<String, dynamic> updates);
  Future<bool> deleteProfile();
  
  // Health Data
  Future<HealthInfo?> getHealthInfo();
  Future<bool> updateHealthInfo(HealthInfo healthInfo);
  
  // Preferences
  Future<AppPreferences> getPreferences();
  Future<bool> updatePreferences(AppPreferences preferences);
  
  // Profile Image
  Future<String?> getProfileImagePath();
  Future<bool> setProfileImage(File imageFile);
  Future<bool> deleteProfileImage();
  
  // Validation
  ValidationResult validateProfile(UserProfile profile);
  
  // Analytics
  Future<ProfileAnalytics> getProfileAnalytics();
}

// Data Models
class UserProfile {
  final String id;
  final PersonalInfo personalInfo;
  final HealthInfo healthInfo;
  final AppPreferences preferences;
  final DateTime createdAt;
  final DateTime lastUpdated;
  
  // Factory constructors
  factory UserProfile.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}

class HealthInfo {
  final double? height;       // cm
  final double? weight;       // kg
  final String? bloodType;    // A, B, AB, O
  final List<String> allergies;
  final List<String> medications;
  final List<String> medicalHistory;
  final String? emergencyContact;
  
  // Computed properties
  double? get bmi => (weight != null && height != null) 
    ? weight! / ((height! / 100) * (height! / 100)) 
    : null;
    
  String get bmiCategory => _getBMICategory();
}
```

### History API (`history_service.dart`)

```dart
class HistoryService {
  // Detection History
  Future<List<DetectionResult>> getDetectionHistory({
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  });
  
  Future<bool> saveDetectionResult(DetectionResult result);
  Future<bool> deleteDetectionResult(String id);
  Future<bool> clearHistory();
  
  // Analytics
  Future<HistoryAnalytics> getAnalytics({
    DateRange? dateRange,
  });
  
  Future<List<HealthTrend>> getHealthTrends();
  Future<HealthScore> getCurrentHealthScore();
  
  // Export
  Future<String> exportHistory({
    required ExportFormat format,
    DateRange? dateRange,
  });
  
  // Statistics
  Future<HistoryStats> getStatistics();
}

// Analytics Models
class HistoryAnalytics {
  final int totalDetections;
  final int diabetesDetections;
  final int nonDiabetesDetections;
  final double averageConfidence;
  final DateTime firstDetection;
  final DateTime lastDetection;
  final List<DailyStats> dailyStats;
  final TrendAnalysis trendAnalysis;
}

class HealthTrend {
  final DateTime date;
  final String prediction;
  final double confidence;
  final double healthScore;
}
```

---

## 🌐 External Integrations

### Maps & Location API (`hospital_service.dart`)

```dart
class HospitalService {
  // Location Services
  Future<Position> getCurrentLocation();
  Future<bool> requestLocationPermission();
  
  // Hospital Search
  Future<List<Hospital>> getNearbyHospitals({
    required Position userLocation,
    double radiusKm = 10.0,
    HospitalType? type,
  });
  
  Future<Hospital?> getHospitalById(String id);
  Future<List<Hospital>> searchHospitals(String query);
  
  // Navigation
  Future<RouteInfo> getRoute({
    required Position from,
    required Hospital to,
  });
  
  Future<void> openInMaps(Hospital hospital);
  
  // Hospital Data
  Future<List<String>> getHospitalServices(String hospitalId);
  Future<List<Review>> getHospitalReviews(String hospitalId);
  Future<OperatingHours> getOperatingHours(String hospitalId);
}

// Models
class Hospital {
  final String id;
  final String name;
  final String address;
  final Position coordinates;
  final double distance;        // km from user
  final List<String> services;
  final String phoneNumber;
  final String? website;
  final double rating;
  final OperatingHours operatingHours;
  final List<String> specialties;
}

class RouteInfo {
  final double distanceKm;
  final Duration estimatedTime;
  final List<Position> routePoints;
  final String instructions;
}
```

### Integration Example

```dart
// Get user location dan cari rumah sakit terdekat  
Position userLocation = await HospitalService.getCurrentLocation();

List<Hospital> hospitals = await HospitalService.getNearbyHospitals(
  userLocation: userLocation,
  radiusKm: 15.0,
  type: HospitalType.general,
);

// Show di map
for (Hospital hospital in hospitals) {
  mapController.addMarker(
    position: hospital.coordinates,
    title: hospital.name,
    subtitle: '${hospital.distance.toStringAsFixed(1)} km',
  );
}
```

---

## 💬 Chat AI Integration

### Chat Service API (`chat_service.dart`)

```dart
class ChatService {
  // Chat Management
  Future<ChatSession> createChatSession({
    ChatType type = ChatType.general,
    UserContext? context,
  });
  
  Future<ChatMessage> sendMessage({
    required String sessionId,
    required String content,
    Map<String, dynamic>? metadata,
  });
  
  Future<List<ChatMessage>> getChatHistory(String sessionId);
  Future<bool> clearChatHistory(String sessionId);
  
  // AI Response Generation
  Future<AIResponse> generateResponse({
    required String userMessage,
    required UserContext context,
    ChatType type = ChatType.general,
  });
  
  // Context-aware chat (berdasarkan hasil deteksi)
  Future<ChatSession> createDetectionChat(DetectionResult result);
  
  // Preferences
  Future<bool> updateChatPreferences(ChatPreferences preferences);
  Future<ChatPreferences> getChatPreferences();
}

// Models
class ChatSession {
  final String id;
  final ChatType type;
  final List<ChatMessage> messages;
  final UserContext userContext;
  final DateTime createdAt;
  final DateTime lastActivity;
  final bool isActive;
}

class ChatMessage {
  final String id;
  final String sessionId;
  final String content;
  final MessageType type;       // user, ai, system
  final DateTime timestamp;
  final MessageStatus status;   // sent, delivered, read
  final Map<String, dynamic>? metadata;
}

class AIResponse {
  final String content;
  final double confidence;
  final List<String> suggestions;
  final List<String> relatedTopics;
  final bool requiresFollowUp;
  final ResponseType type;      // informational, recommendation, warning
}
```

### Chat Integration Example

```dart
// Create detection-based chat session
DetectionResult result = await MLService.predictImage(imageFile);
ChatSession session = await ChatService.createDetectionChat(result);

// Send user question
ChatMessage userMessage = await ChatService.sendMessage(
  sessionId: session.id,
  content: "Apa yang harus saya lakukan dengan hasil ini?",
);

// AI akan memberikan respons berdasarkan context hasil deteksi
// dan profil kesehatan pengguna
```

---

## ⚙️ Configuration & Setup

### App Configuration

```dart
class AppConfig {
  static const String appName = 'DeteksiDiabetes';
  static const String appVersion = '1.0.0';
  
  // ML Model Configuration  
  static const String modelPath = 'assets/models/model.tflite';
  static const String labelsPath = 'assets/models/labels.txt';
  
  // API Endpoints (future use)
  static const String baseUrl = 'https://api.deteksidiabetes.com';
  static const String apiVersion = 'v1';
  
  // Local Storage Keys
  static const String userProfileKey = 'user_profile';
  static const String authTokenKey = 'auth_token';
  static const String preferencesKey = 'app_preferences';
  
  // Feature Flags
  static const bool enableCloudSync = false;
  static const bool enableAnalytics = true;
  static const bool enableCrashReporting = true;
  
  // Performance Settings
  static const int maxCacheSize = 100; // MB
  static const int maxHistoryRecords = 1000;
  static const Duration sessionTimeout = Duration(hours: 24);
}
```

### Initialization Sequence

```dart
class AppInitializer {
  static Future<void> initialize() async {
    try {
      // 1. Initialize Flutter binding
      WidgetsFlutterBinding.ensureInitialized();
      
      // 2. Load ML model
      await MLService.loadModel();
      
      // 3. Initialize local storage
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // 4. Setup services
      AuthService.initialize(prefs);
      UserProfileService.initialize(prefs);
      HistoryService.initialize(prefs);
      
      // 5. Setup error handling
      FlutterError.onError = _handleFlutterError;
      
      // 6. Setup analytics (if enabled)
      if (AppConfig.enableAnalytics) {
        await AnalyticsService.initialize();
      }
      
      print('✅ App initialization complete');
    } catch (e) {
      print('❌ App initialization failed: $e');
      rethrow;
    }
  }
  
  static void _handleFlutterError(FlutterErrorDetails details) {
    // Log error
    print('Flutter Error: ${details.exception}');
    
    // Report to crash reporting service
    if (AppConfig.enableCrashReporting) {
      CrashReportingService.reportError(details);
    }
  }
}
```

---

## 🧪 Testing APIs

### Unit Test Examples

```dart
// test/services/ml_service_test.dart
class MLServiceTest {
  group('MLService Tests', () {
    setUpAll(() async {
      await MLService.loadModel();
    });
    
    test('should load model successfully', () async {
      expect(MLService.isModelLoaded, true);
    });
    
    test('should predict diabetes correctly', () async {
      File testImage = File('test/assets/diabetes_sample.jpg');
      DetectionResult result = await MLService.predictImage(testImage);
      
      expect(result.prediction, 'diabetes');
      expect(result.confidence, greaterThan(0.7));
    });
    
    test('should handle invalid images gracefully', () async {
      File invalidImage = File('test/assets/invalid.txt');
      
      expect(
        () => MLService.predictImage(invalidImage),
        throwsA(isA<InvalidImageException>()),
      );
    });
  });
}

// test/services/user_profile_service_test.dart
class UserProfileServiceTest {
  late UserProfileService service;
  late MockSharedPreferences mockPrefs;
  
  setUp(() {
    mockPrefs = MockSharedPreferences();
    service = UserProfileService(mockPrefs);
  });
  
  test('should save and retrieve profile', () async {
    UserProfile profile = UserProfile(
      id: 'test_id',
      personalInfo: PersonalInfo(name: 'Test User'),
      healthInfo: HealthInfo(height: 170, weight: 70),
      preferences: AppPreferences(),
      createdAt: DateTime.now(),
      lastUpdated: DateTime.now(),
    );
    
    bool saved = await service.saveProfile(profile);
    expect(saved, true);
    
    UserProfile? retrieved = await service.getProfile();
    expect(retrieved?.personalInfo.name, 'Test User');
    expect(retrieved?.healthInfo.height, 170);
  });
}
```

### Integration Test Examples

```dart
// integration_test/app_test.dart
void main() {
  group('App Integration Tests', () {
    testWidgets('complete diabetes detection flow', (tester) async {
      // Launch app
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();
      
      // Navigate to detection screen
      await tester.tap(find.text('Deteksi Diabetes'));
      await tester.pumpAndSettle();
      
      // Mock camera capture
      await tester.tap(find.byIcon(Icons.camera));
      await tester.pumpAndSettle();
      
      // Verify result screen appears
      expect(find.text('Hasil Deteksi'), findsOneWidget);
      
      // Check if prediction is displayed
      expect(find.textContaining('diabetes'), findsAtLeastNWidgets(1));
    });
    
    testWidgets('chat AI integration', (tester) async {
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();
      
      // Navigate to chat
      await tester.tap(find.text('Chat AI'));
      await tester.pumpAndSettle();
      
      // Send message
      await tester.enterText(
        find.byType(TextField), 
        'Apa gejala diabetes?'
      );
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();
      
      // Verify AI response appears
      expect(find.textContaining('Gejala diabetes'), findsOneWidget);
    });
  });
}
```

---

## 📊 API Monitoring & Analytics

### Performance Monitoring

```dart
class PerformanceMonitor {
  static final Map<String, Duration> _apiTimes = {};
  
  static Future<T> measureApiCall<T>(
    String apiName,
    Future<T> Function() apiCall,
  ) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      T result = await apiCall();
      stopwatch.stop();
      
      _apiTimes[apiName] = stopwatch.elapsed;
      _logPerformance(apiName, stopwatch.elapsed);
      
      return result;
    } catch (e) {
      stopwatch.stop();
      _logError(apiName, e, stopwatch.elapsed);
      rethrow;
    }
  }
  
  static Map<String, Duration> getApiTimes() => _apiTimes;
  
  static void _logPerformance(String apiName, Duration duration) {
    print('🚀 $apiName completed in ${duration.inMilliseconds}ms');
    
    // Send to analytics service
    AnalyticsService.trackApiPerformance(apiName, duration);
  }
  
  static void _logError(String apiName, dynamic error, Duration duration) {
    print('❌ $apiName failed after ${duration.inMilliseconds}ms: $error');
    
    // Send to error tracking service  
    ErrorTrackingService.trackApiError(apiName, error, duration);
  }
}
```

### Usage Analytics

```dart
class UsageAnalytics {
  static Future<void> trackFeatureUsage(String featureName) async {
    await AnalyticsService.trackEvent(
      name: 'feature_used',
      parameters: {
        'feature_name': featureName,
        'timestamp': DateTime.now().toIso8601String(),
        'user_id': await AuthService.getCurrentUserId(),
      },
    );
  }
  
  static Future<void> trackDetectionUsage({
    required String prediction,
    required double confidence,
    required Duration processingTime,
  }) async {
    await AnalyticsService.trackEvent(
      name: 'detection_performed',
      parameters: {
        'prediction': prediction,
        'confidence': confidence,
        'processing_time_ms': processingTime.inMilliseconds,
        'model_version': MLService.getModelVersion(),
      },
    );
  }
}
```

---

**📝 Catatan API:**
- Semua APIs menggunakan async/await pattern
- Error handling dengan try-catch dan custom exceptions
- Response models untuk type safety
- Dependency injection untuk testability
- Performance monitoring built-in
- Analytics tracking untuk feature usage

**🔄 Terakhir diperbarui:** 23 Juni 2025
