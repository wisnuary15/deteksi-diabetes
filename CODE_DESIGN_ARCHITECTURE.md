# 🏗️ Code Design Architecture - DeteksiDiabetes

## 📋 Overview
Dokumen ini menjelaskan arsitektur dan design pattern yang digunakan dalam project DeteksiDiabetes untuk memastikan kode yang maintainable, scalable, dan testable.

---

## 🎯 Architecture Pattern

### Clean Architecture + MVVM
```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                       │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │
│  │   Screens   │  │   Widgets   │  │    ViewModels       │ │
│  │ (UI/Pages)  │  │(Components) │  │ (State Management)  │ │
│  └─────────────┘  └─────────────┘  └─────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Business Logic Layer                     │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │
│  │  Services   │  │ Use Cases   │  │     Validators      │ │
│  │(Core Logic) │  │(App Logic)  │  │   (Rules/Logic)     │ │
│  └─────────────┘  └─────────────┘  └─────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      Data Layer                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │
│  │Repositories │  │   Models    │  │    Data Sources     │ │
│  │(Data Access)│  │(Entities)   │  │  (Local/Remote)     │ │
│  └─────────────┘  └─────────────┘  └─────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

---

## 📁 Recommended Folder Structure

```
lib/
├── core/                          # Core functionality
│   ├── constants/                 # App constants
│   │   ├── app_colors.dart
│   │   ├── app_strings.dart
│   │   ├── app_config.dart
│   │   └── api_endpoints.dart
│   ├── errors/                    # Error handling
│   │   ├── exceptions.dart
│   │   ├── failures.dart
│   │   └── error_handler.dart
│   ├── network/                   # Network layer
│   │   ├── network_info.dart
│   │   └── api_client.dart
│   ├── utils/                     # Utility functions
│   │   ├── validators.dart
│   │   ├── formatters.dart
│   │   ├── extensions.dart
│   │   └── helpers.dart
│   └── di/                        # Dependency Injection
│       └── injection_container.dart
├── features/                      # Feature-based modules
│   ├── authentication/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   ├── repositories/
│   │   │   └── usecases/
│   │   └── presentation/
│   │       ├── pages/
│   │       ├── widgets/
│   │       └── providers/
│   ├── diabetes_detection/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── chat_ai/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── health_tracking/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── education/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   └── profile/
│       ├── data/
│       ├── domain/
│       └── presentation/
├── shared/                        # Shared components
│   ├── widgets/                   # Reusable widgets
│   │   ├── buttons/
│   │   ├── cards/
│   │   ├── dialogs/
│   │   ├── forms/
│   │   └── loading/
│   ├── models/                    # Shared models
│   ├── services/                  # Shared services
│   └── extensions/                # Dart extensions
└── main.dart                      # App entry point
```

---

## 🔧 Core Components Design

### 1. Base Classes

#### BaseUseCase
```dart
// core/usecases/base_usecase.dart
import '../errors/failures.dart';
import 'package:dartz/dartz.dart';

abstract class BaseUseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

class NoParams {}
```

#### BaseRepository
```dart
// core/repositories/base_repository.dart
abstract class BaseRepository {
  Future<void> dispose();
}
```

#### BaseModel
```dart
// core/models/base_model.dart
abstract class BaseModel {
  Map<String, dynamic> toJson();
  
  @override
  bool operator ==(Object other);
  
  @override
  int get hashCode;
}
```

### 2. Error Handling

#### Custom Exceptions
```dart
// core/errors/exceptions.dart
class ServerException implements Exception {
  final String message;
  final int? statusCode;
  
  const ServerException({
    required this.message,
    this.statusCode,
  });
}

class CacheException implements Exception {
  final String message;
  
  const CacheException({required this.message});
}

class NetworkException implements Exception {
  final String message;
  
  const NetworkException({required this.message});
}

class ValidationException implements Exception {
  final String field;
  final String message;
  
  const ValidationException({
    required this.field,
    required this.message,
  });
}

class ModelException implements Exception {
  final String message;
  final String? modelPath;
  
  const ModelException({
    required this.message,
    this.modelPath,
  });
}
```

#### Failures
```dart
// core/errors/failures.dart
abstract class Failure {
  final String message;
  final int? code;
  
  const Failure({
    required this.message,
    this.code,
  });
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Failure &&
        other.message == message &&
        other.code == code;
  }
  
  @override
  int get hashCode => message.hashCode ^ code.hashCode;
}

class ServerFailure extends Failure {
  const ServerFailure({
    required String message,
    int? code,
  }) : super(message: message, code: code);
}

class CacheFailure extends Failure {
  const CacheFailure({
    required String message,
  }) : super(message: message);
}

class NetworkFailure extends Failure {
  const NetworkFailure({
    required String message,
  }) : super(message: message);
}

class ValidationFailure extends Failure {
  final String field;
  
  const ValidationFailure({
    required this.field,
    required String message,
  }) : super(message: message);
}
```

### 3. State Management with Provider

#### Base Provider
```dart
// core/providers/base_provider.dart
import 'package:flutter/foundation.dart';

enum ViewState { idle, loading, success, error }

abstract class BaseProvider extends ChangeNotifier {
  ViewState _state = ViewState.idle;
  String _errorMessage = '';
  
  ViewState get state => _state;
  String get errorMessage => _errorMessage;
  
  bool get isIdle => _state == ViewState.idle;
  bool get isLoading => _state == ViewState.loading;
  bool get isSuccess => _state == ViewState.success;
  bool get isError => _state == ViewState.error;
  
  void setState(ViewState newState) {
    _state = newState;
    notifyListeners();
  }
  
  void setError(String message) {
    _errorMessage = message;
    _state = ViewState.error;
    notifyListeners();
  }
  
  void setLoading() {
    _state = ViewState.loading;
    notifyListeners();
  }
  
  void setSuccess() {
    _state = ViewState.success;
    notifyListeners();
  }
  
  void setIdle() {
    _state = ViewState.idle;
    notifyListeners();
  }
  
  void clearError() {
    _errorMessage = '';
    if (_state == ViewState.error) {
      _state = ViewState.idle;
      notifyListeners();
    }
  }
}
```

---

## 🎯 Feature-Specific Design

### 1. Diabetes Detection Feature

#### Domain Layer
```dart
// features/diabetes_detection/domain/entities/detection_result.dart
class DetectionResult {
  final String id;
  final String imagePath;
  final String prediction;
  final double confidence;
  final DateTime timestamp;
  final String interpretation;
  final List<String> recommendations;
  
  const DetectionResult({
    required this.id,
    required this.imagePath,
    required this.prediction,
    required this.confidence,
    required this.timestamp,
    required this.interpretation,
    required this.recommendations,
  });
  
  bool get isDiabetes => prediction.toLowerCase() == 'diabetes';
  bool get isHighConfidence => confidence > 0.8;
  
  String get riskLevel {
    if (!isDiabetes) return 'Low';
    if (confidence > 0.9) return 'High';
    if (confidence > 0.7) return 'Medium';
    return 'Low';
  }
}
```

#### Repository Interface
```dart
// features/diabetes_detection/domain/repositories/detection_repository.dart
import '../entities/detection_result.dart';
import '../../../../core/errors/failures.dart';
import 'package:dartz/dartz.dart';

abstract class DetectionRepository {
  Future<Either<Failure, DetectionResult>> detectDiabetes(String imagePath);
  Future<Either<Failure, List<DetectionResult>>> getDetectionHistory();
  Future<Either<Failure, void>> saveDetectionResult(DetectionResult result);
  Future<Either<Failure, void>> deleteDetectionResult(String id);
}
```

#### Use Case
```dart
// features/diabetes_detection/domain/usecases/detect_diabetes_usecase.dart
import '../entities/detection_result.dart';
import '../repositories/detection_repository.dart';
import '../../../../core/usecases/base_usecase.dart';
import '../../../../core/errors/failures.dart';
import 'package:dartz/dartz.dart';

class DetectDiabetesUseCase extends BaseUseCase<DetectionResult, DetectDiabetesParams> {
  final DetectionRepository repository;
  
  DetectDiabetesUseCase({required this.repository});
  
  @override
  Future<Either<Failure, DetectionResult>> call(DetectDiabetesParams params) async {
    return await repository.detectDiabetes(params.imagePath);
  }
}

class DetectDiabetesParams {
  final String imagePath;
  
  const DetectDiabetesParams({required this.imagePath});
}
```

#### Data Layer
```dart
// features/diabetes_detection/data/models/detection_result_model.dart
import '../../domain/entities/detection_result.dart';
import '../../../../core/models/base_model.dart';

class DetectionResultModel extends DetectionResult implements BaseModel {
  const DetectionResultModel({
    required String id,
    required String imagePath,
    required String prediction,
    required double confidence,
    required DateTime timestamp,
    required String interpretation,
    required List<String> recommendations,
  }) : super(
          id: id,
          imagePath: imagePath,
          prediction: prediction,
          confidence: confidence,
          timestamp: timestamp,
          interpretation: interpretation,
          recommendations: recommendations,
        );
  
  factory DetectionResultModel.fromJson(Map<String, dynamic> json) {
    return DetectionResultModel(
      id: json['id'] as String,
      imagePath: json['imagePath'] as String,
      prediction: json['prediction'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      interpretation: json['interpretation'] as String,
      recommendations: List<String>.from(json['recommendations'] as List),
    );
  }
  
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imagePath': imagePath,
      'prediction': prediction,
      'confidence': confidence,
      'timestamp': timestamp.toIso8601String(),
      'interpretation': interpretation,
      'recommendations': recommendations,
    };
  }
  
  DetectionResult toEntity() {
    return DetectionResult(
      id: id,
      imagePath: imagePath,
      prediction: prediction,
      confidence: confidence,
      timestamp: timestamp,
      interpretation: interpretation,
      recommendations: recommendations,
    );
  }
}
```

#### Presentation Layer
```dart
// features/diabetes_detection/presentation/providers/detection_provider.dart
import '../../domain/usecases/detect_diabetes_usecase.dart';
import '../../domain/entities/detection_result.dart';
import '../../../../core/providers/base_provider.dart';

class DetectionProvider extends BaseProvider {
  final DetectDiabetesUseCase _detectDiabetesUseCase;
  
  DetectionProvider({
    required DetectDiabetesUseCase detectDiabetesUseCase,
  }) : _detectDiabetesUseCase = detectDiabetesUseCase;
  
  DetectionResult? _currentResult;
  List<DetectionResult> _detectionHistory = [];
  
  DetectionResult? get currentResult => _currentResult;
  List<DetectionResult> get detectionHistory => _detectionHistory;
  
  Future<void> detectDiabetes(String imagePath) async {
    setLoading();
    
    final params = DetectDiabetesParams(imagePath: imagePath);
    final result = await _detectDiabetesUseCase(params);
    
    result.fold(
      (failure) => setError(failure.message),
      (detectionResult) {
        _currentResult = detectionResult;
        _detectionHistory.insert(0, detectionResult);
        setSuccess();
      },
    );
  }
  
  void clearCurrentResult() {
    _currentResult = null;
    setIdle();
  }
}
```

---

## 🔒 Security & Validation

### Input Validation
```dart
// core/utils/validators.dart
class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegExp.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    
    return null;
  }
  
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
      return 'Password must contain uppercase, lowercase, and number';
    }
    
    return null;
  }
  
  static String? validateAge(String? value) {
    if (value == null || value.isEmpty) {
      return 'Age is required';
    }
    
    final age = int.tryParse(value);
    if (age == null) {
      return 'Enter a valid age';
    }
    
    if (age < 1 || age > 120) {
      return 'Age must be between 1 and 120';
    }
    
    return null;
  }
  
  static String? validateWeight(String? value) {
    if (value == null || value.isEmpty) {
      return 'Weight is required';
    }
    
    final weight = double.tryParse(value);
    if (weight == null) {
      return 'Enter a valid weight';
    }
    
    if (weight < 20 || weight > 300) {
      return 'Weight must be between 20 and 300 kg';
    }
    
    return null;
  }
  
  static String? validateHeight(String? value) {
    if (value == null || value.isEmpty) {
      return 'Height is required';
    }
    
    final height = double.tryParse(value);
    if (height == null) {
      return 'Enter a valid height';
    }
    
    if (height < 100 || height > 250) {
      return 'Height must be between 100 and 250 cm';
    }
    
    return null;
  }
}
```

### Secure Storage
```dart
// core/services/secure_storage_service.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: IOSAccessibility.first_unlock_this_device,
    ),
  );
  
  // User credentials
  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUserId = 'user_id';
  static const String _keyUserEmail = 'user_email';
  
  // Biometric data
  static const String _keyBiometricEnabled = 'biometric_enabled';
  
  // Health data encryption key
  static const String _keyHealthDataKey = 'health_data_key';
  
  // Auth methods
  Future<void> storeAccessToken(String token) async {
    await _storage.write(key: _keyAccessToken, value: token);
  }
  
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _keyAccessToken);
  }
  
  Future<void> storeRefreshToken(String token) async {
    await _storage.write(key: _keyRefreshToken, value: token);
  }
  
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _keyRefreshToken);
  }
  
  Future<void> storeUserCredentials({
    required String userId,
    required String email,
  }) async {
    await Future.wait([
      _storage.write(key: _keyUserId, value: userId),
      _storage.write(key: _keyUserEmail, value: email),
    ]);
  }
  
  Future<Map<String, String?>> getUserCredentials() async {
    final results = await Future.wait([
      _storage.read(key: _keyUserId),
      _storage.read(key: _keyUserEmail),
    ]);
    
    return {
      'userId': results[0],
      'email': results[1],
    };
  }
  
  // Biometric methods
  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(
      key: _keyBiometricEnabled,
      value: enabled.toString(),
    );
  }
  
  Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: _keyBiometricEnabled);
    return value == 'true';
  }
  
  // Health data encryption
  Future<void> storeHealthDataKey(String key) async {
    await _storage.write(key: _keyHealthDataKey, value: key);
  }
  
  Future<String?> getHealthDataKey() async {
    return await _storage.read(key: _keyHealthDataKey);
  }
  
  // Clear all data
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
  
  // Clear only auth data
  Future<void> clearAuthData() async {
    await Future.wait([
      _storage.delete(key: _keyAccessToken),
      _storage.delete(key: _keyRefreshToken),
      _storage.delete(key: _keyUserId),
      _storage.delete(key: _keyUserEmail),
    ]);
  }
}
```

---

## 🧪 Testing Strategy

### Unit Test Structure
```dart
// test/features/diabetes_detection/domain/usecases/detect_diabetes_usecase_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';

import 'package:diabetes_app/features/diabetes_detection/domain/usecases/detect_diabetes_usecase.dart';
import 'package:diabetes_app/features/diabetes_detection/domain/repositories/detection_repository.dart';
import 'package:diabetes_app/features/diabetes_detection/domain/entities/detection_result.dart';
import 'package:diabetes_app/core/errors/failures.dart';

class MockDetectionRepository extends Mock implements DetectionRepository {}

void main() {
  late DetectDiabetesUseCase usecase;
  late MockDetectionRepository mockRepository;
  
  setUp(() {
    mockRepository = MockDetectionRepository();
    usecase = DetectDiabetesUseCase(repository: mockRepository);
  });
  
  const testImagePath = '/test/image/path.jpg';
  const testDetectionResult = DetectionResult(
    id: '1',
    imagePath: testImagePath,
    prediction: 'diabetes',
    confidence: 0.85,
    timestamp: DateTime(2025, 6, 25),
    interpretation: 'High risk of diabetes detected',
    recommendations: ['Consult with doctor', 'Monitor blood sugar'],
  );
  
  group('DetectDiabetesUseCase', () {
    test('should return DetectionResult when detection is successful', () async {
      // Arrange
      when(() => mockRepository.detectDiabetes(testImagePath))
          .thenAnswer((_) async => const Right(testDetectionResult));
      
      // Act
      final result = await usecase(
        const DetectDiabetesParams(imagePath: testImagePath),
      );
      
      // Assert
      expect(result, const Right(testDetectionResult));
      verify(() => mockRepository.detectDiabetes(testImagePath));
      verifyNoMoreInteractions(mockRepository);
    });
    
    test('should return Failure when detection fails', () async {
      // Arrange
      const failure = ServerFailure(message: 'Detection failed');
      when(() => mockRepository.detectDiabetes(testImagePath))
          .thenAnswer((_) async => const Left(failure));
      
      // Act
      final result = await usecase(
        const DetectDiabetesParams(imagePath: testImagePath),
      );
      
      // Assert
      expect(result, const Left(failure));
      verify(() => mockRepository.detectDiabetes(testImagePath));
      verifyNoMoreInteractions(mockRepository);
    });
  });
}
```

### Widget Test Example
```dart
// test/features/diabetes_detection/presentation/widgets/detection_result_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diabetes_app/features/diabetes_detection/presentation/widgets/detection_result_card.dart';
import 'package:diabetes_app/features/diabetes_detection/domain/entities/detection_result.dart';

void main() {
  group('DetectionResultCard', () {
    const testDetectionResult = DetectionResult(
      id: '1',
      imagePath: '/test/image.jpg',
      prediction: 'diabetes',
      confidence: 0.85,
      timestamp: DateTime(2025, 6, 25),
      interpretation: 'High risk detected',
      recommendations: ['Consult doctor'],
    );
    
    testWidgets('should display detection result information', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DetectionResultCard(result: testDetectionResult),
          ),
        ),
      );
      
      // Assert
      expect(find.text('High risk detected'), findsOneWidget);
      expect(find.text('85%'), findsOneWidget);
      expect(find.text('diabetes'), findsOneWidget);
    });
    
    testWidgets('should show high risk color for diabetes prediction', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DetectionResultCard(result: testDetectionResult),
          ),
        ),
      );
      
      // Assert
      final cardWidget = tester.widget<Card>(find.byType(Card));
      expect(cardWidget.color, Colors.red.shade50);
    });
  });
}
```

---

## 📦 Dependency Injection

### Service Locator
```dart
// core/di/injection_container.dart
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/diabetes_detection/data/repositories/detection_repository_impl.dart';
import '../../features/diabetes_detection/domain/repositories/detection_repository.dart';
import '../../features/diabetes_detection/domain/usecases/detect_diabetes_usecase.dart';
import '../../features/diabetes_detection/presentation/providers/detection_provider.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Features - Diabetes Detection
  _initDiabetesDetection();
  
  // Features - Authentication
  _initAuthentication();
  
  // Features - Profile
  _initProfile();
  
  // Core
  await _initCore();
  
  // External
  await _initExternal();
}

void _initDiabetesDetection() {
  // Providers
  sl.registerFactory(
    () => DetectionProvider(
      detectDiabetesUseCase: sl(),
    ),
  );
  
  // Use cases
  sl.registerLazySingleton(
    () => DetectDiabetesUseCase(repository: sl()),
  );
  
  // Repository
  sl.registerLazySingleton<DetectionRepository>(
    () => DetectionRepositoryImpl(
      mlService: sl(),
      localDataSource: sl(),
    ),
  );
  
  // Data sources
  sl.registerLazySingleton(
    () => DetectionLocalDataSourceImpl(sharedPreferences: sl()),
  );
  
  // Services
  sl.registerLazySingleton(
    () => MLService(),
  );
}

void _initAuthentication() {
  // Implementation similar to diabetes detection
}

void _initProfile() {
  // Implementation similar to diabetes detection
}

Future<void> _initCore() async {
  sl.registerLazySingleton(() => NetworkInfo());
  sl.registerLazySingleton(() => SecureStorageService());
}

Future<void> _initExternal() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
}
```

---

## 🎨 UI Design Patterns

### Theme Management
```dart
// core/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static const Color _primaryColor = Color(0xFF1976D2);
  static const Color _secondaryColor = Color(0xFF42A5F5);
  static const Color _backgroundColor = Color(0xFFF8FAFC);
  static const Color _surfaceColor = Colors.white;
  static const Color _errorColor = Color(0xFFDC2626);
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: _primaryColor,
      scaffoldBackgroundColor: _backgroundColor,
      
      colorScheme: const ColorScheme.light(
        primary: _primaryColor,
        secondary: _secondaryColor,
        surface: _surfaceColor,
        background: _backgroundColor,
        error: _errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFF1E293B),
        onBackground: Color(0xFF334155),
        onError: Colors.white,
      ),
      
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: _surfaceColor,
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: _primaryColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: _errorColor,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
  
  static ThemeData get darkTheme {
    // Implementation for dark theme
    return lightTheme.copyWith(
      brightness: Brightness.dark,
      // Customize for dark theme
    );
  }
}
```

---

## 📈 Performance Optimization

### Memory Management
```dart
// core/utils/memory_manager.dart
import 'dart:developer' as developer;

class MemoryManager {
  static const int _maxCacheSize = 50 * 1024 * 1024; // 50MB
  static final Map<String, dynamic> _cache = {};
  static int _currentCacheSize = 0;
  
  static void addToCache(String key, dynamic value) {
    final size = _calculateSize(value);
    
    if (_currentCacheSize + size > _maxCacheSize) {
      _clearOldCache();
    }
    
    _cache[key] = value;
    _currentCacheSize += size;
    
    developer.log('Cache size: ${_currentCacheSize / 1024 / 1024:.2f}MB');
  }
  
  static T? getFromCache<T>(String key) {
    return _cache[key] as T?;
  }
  
  static void removeFromCache(String key) {
    if (_cache.containsKey(key)) {
      final size = _calculateSize(_cache[key]);
      _cache.remove(key);
      _currentCacheSize -= size;
    }
  }
  
  static void clearCache() {
    _cache.clear();
    _currentCacheSize = 0;
    developer.log('Cache cleared');
  }
  
  static void _clearOldCache() {
    // Remove oldest 25% of cache
    final keysToRemove = _cache.keys.take(_cache.length ~/ 4).toList();
    for (final key in keysToRemove) {
      removeFromCache(key);
    }
  }
  
  static int _calculateSize(dynamic value) {
    // Simplified size calculation
    if (value is String) {
      return value.length * 2; // 2 bytes per character
    } else if (value is List) {
      return value.length * 8; // 8 bytes per item
    } else if (value is Map) {
      return value.length * 16; // 16 bytes per key-value pair
    }
    return 64; // Default size
  }
}
```

### Image Optimization
```dart
// core/utils/image_optimizer.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class ImageOptimizer {
  static const int _maxWidth = 1024;
  static const int _maxHeight = 1024;
  static const int _quality = 85;
  
  static Future<File> optimizeImage(File imageFile) async {
    try {
      // Read image
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        throw Exception('Failed to decode image');
      }
      
      // Resize if needed
      img.Image resizedImage = image;
      if (image.width > _maxWidth || image.height > _maxHeight) {
        resizedImage = img.copyResize(
          image,
          width: image.width > _maxWidth ? _maxWidth : null,
          height: image.height > _maxHeight ? _maxHeight : null,
          maintainAspect: true,
        );
      }
      
      // Compress
      final compressedBytes = img.encodeJpg(resizedImage, quality: _quality);
      
      // Save optimized image
      final optimizedFile = File('${imageFile.path}_optimized.jpg');
      await optimizedFile.writeAsBytes(compressedBytes);
      
      return optimizedFile;
    } catch (e) {
      developer.log('Image optimization failed: $e');
      return imageFile; // Return original if optimization fails
    }
  }
  
  static Future<Uint8List> prepareImageForML(File imageFile, {
    required int targetWidth,
    required int targetHeight,
  }) async {
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);
    
    if (image == null) {
      throw Exception('Failed to decode image for ML processing');
    }
    
    // Resize to exact dimensions for ML model
    final resizedImage = img.copyResize(
      image,
      width: targetWidth,
      height: targetHeight,
    );
    
    // Normalize pixels (0-1 range)
    final imageBytes = Uint8List(targetWidth * targetHeight * 3);
    int pixelIndex = 0;
    
    for (int y = 0; y < targetHeight; y++) {
      for (int x = 0; x < targetWidth; x++) {
        final pixel = resizedImage.getPixel(x, y);
        
        // Extract RGB values and normalize
        final r = img.getRed(pixel) / 255.0;
        final g = img.getGreen(pixel) / 255.0;
        final b = img.getBlue(pixel) / 255.0;
        
        imageBytes[pixelIndex++] = (r * 255).round();
        imageBytes[pixelIndex++] = (g * 255).round();
        imageBytes[pixelIndex++] = (b * 255).round();
      }
    }
    
    return imageBytes;
  }
}
```

---

Ini adalah design code architecture yang komprehensif untuk project DeteksiDiabetes Anda. Architecture ini mengikuti best practices seperti:

1. **Clean Architecture** - Separation of concerns
2. **SOLID Principles** - Maintainable code
3. **Error Handling** - Robust error management
4. **Security** - Secure data storage and validation
5. **Testing** - Comprehensive test strategy
6. **Performance** - Memory and image optimization
7. **Scalability** - Feature-based modular structure

Apakah Anda ingin saya implementasikan bagian tertentu dari architecture ini ke dalam project Anda?
