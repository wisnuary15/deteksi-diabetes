# 🚀 Deployment & Maintenance Guide

## 📋 Daftar Isi
1. [Build & Release Process](#build--release-process)
2. [Platform-Specific Deployment](#platform-specific-deployment)
3. [CI/CD Pipeline](#cicd-pipeline)
4. [Environment Configuration](#environment-configuration)
5. [Monitoring & Maintenance](#monitoring--maintenance)
6. [Troubleshooting Guide](#troubleshooting-guide)

---

## 🏗️ Build & Release Process

### Pre-Build Checklist

```bash
# 1. Verify Flutter version
flutter --version

# 2. Clean build directory
flutter clean

# 3. Get dependencies
flutter pub get

# 4. Run code analysis
flutter analyze

# 5. Run tests
flutter test

# 6. Build runner (if using code generation)
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### Build Commands

#### Debug Build
```bash
# Android Debug
flutter build apk --debug
flutter build appbundle --debug

# iOS Debug  
flutter build ios --debug

# Web Debug
flutter build web --debug

# Windows Debug
flutter build windows --debug
```

#### Release Build
```bash
# Android Release
flutter build apk --release
flutter build appbundle --release --target-platform android-arm,android-arm64,android-x64

# iOS Release
flutter build ios --release

# Web Release
flutter build web --release --web-renderer html

# Windows Release
flutter build windows --release
```

### Version Management

#### `pubspec.yaml` Configuration
```yaml
name: diabetes
description: Aplikasi Deteksi Diabetes dengan AI
version: 1.0.0+1  # version+build_number

environment:
  sdk: ">=3.0.0 <4.0.0"
  flutter: ">=3.10.0"
```

#### Version Bumping Script
```bash
#!/bin/bash
# scripts/bump_version.sh

# Get current version
CURRENT_VERSION=$(grep "version:" pubspec.yaml | cut -d ' ' -f 2 | cut -d '+' -f 1)
CURRENT_BUILD=$(grep "version:" pubspec.yaml | cut -d '+' -f 2)

# Increment build number
NEW_BUILD=$((CURRENT_BUILD + 1))

# Update pubspec.yaml
sed -i "s/version: $CURRENT_VERSION+$CURRENT_BUILD/version: $CURRENT_VERSION+$NEW_BUILD/" pubspec.yaml

echo "Version updated to $CURRENT_VERSION+$NEW_BUILD"
```

---

## 📱 Platform-Specific Deployment

### Android Deployment

#### 1. Signing Configuration
**File:** `android/app/build.gradle`

```gradle
android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

#### 2. Key Properties
**File:** `android/key.properties`
```properties
storePassword=myStorePassword
keyPassword=myKeyPassword
keyAlias=myKeyAlias
storeFile=../app-release-key.jks
```

#### 3. ProGuard Rules
**File:** `android/app/proguard-rules.pro`
```proguard
# Keep TensorFlow Lite
-keep class org.tensorflow.lite.** { *; }
-keep class org.tensorflow.lite.gpu.** { *; }

# Keep model classes
-keep class com.example.diabetes.models.** { *; }

# Keep Flutter classes
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
```

#### 4. Build for Play Store
```bash
# Build App Bundle (recommended)
flutter build appbundle --release

# Build APK (for manual distribution)
flutter build apk --release --split-per-abi
```

### iOS Deployment

#### 1. Xcode Configuration
- Open `ios/Runner.xcworkspace`
- Set **Team** in Signing & Capabilities
- Configure **Bundle Identifier**
- Set **Deployment Target** (minimum iOS 11.0)

#### 2. Info.plist Configuration
**File:** `ios/Runner/Info.plist`
```xml
<dict>
    <!-- App Transport Security -->
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <false/>
    </dict>
    
    <!-- Camera Permission -->
    <key>NSCameraUsageDescription</key>
    <string>This app needs camera access to capture tongue images for diabetes detection.</string>
    
    <!-- Location Permission -->
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>This app needs location access to find nearby hospitals.</string>
</dict>
```

#### 3. Build for App Store
```bash
# Build for iOS
flutter build ios --release

# Archive in Xcode
# Product → Archive → Distribute App
```

### Web Deployment

#### 1. Build Configuration
```bash
# Build for web
flutter build web --release --web-renderer html --base-href /diabetes/

# Build with PWA support
flutter build web --release --pwa-strategy offline-first
```

#### 2. Web Configuration
**File:** `web/index.html`
```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>DeteksiDiabetes - AI Diabetes Detection</title>
  <meta name="description" content="Aplikasi deteksi diabetes menggunakan AI">
  
  <!-- PWA -->
  <link rel="manifest" href="manifest.json">
  <meta name="theme-color" content="#1976D2">
  
  <!-- Icons -->
  <link rel="apple-touch-icon" href="icons/Icon-192.png">
  <link rel="icon" type="image/png" href="favicon.png"/>
</head>
<body>
  <script src="main.dart.js" type="application/javascript"></script>
</body>
</html>
```

#### 3. PWA Manifest
**File:** `web/manifest.json`
```json
{
  "name": "DeteksiDiabetes",
  "short_name": "DiabetesAI",
  "start_url": ".",
  "display": "standalone",
  "background_color": "#1976D2",
  "theme_color": "#1976D2",
  "description": "AI-powered diabetes detection app",
  "orientation": "portrait-primary",
  "prefer_related_applications": false,
  "icons": [
    {
      "src": "icons/Icon-192.png",
      "sizes": "192x192",
      "type": "image/png"
    },
    {
      "src": "icons/Icon-512.png",
      "sizes": "512x512",
      "type": "image/png"
    }
  ]
}
```

### Windows Deployment

#### 1. Build for Windows
```bash
# Build Windows executable
flutter build windows --release

# Create installer (optional)
# Using Inno Setup or similar
```

#### 2. Windows Configuration
**File:** `windows/runner/main.cpp`
```cpp
#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present
  if (::AllocConsole()) {
    freopen_s(reinterpret_cast<FILE**>(stdout), "CONOUT$", "w", stdout);
    freopen_s(reinterpret_cast<FILE**>(stderr), "CONOUT$", "w", stderr);
  }

  // Initialize and run the application
  flutter::DartProject project(L"data");
  auto controller = std::make_unique<flutter::FlutterViewController>(
      100, 100, project);
  
  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  return EXIT_SUCCESS;
}
```

---

## 🔄 CI/CD Pipeline

### GitHub Actions Workflow

**File:** `.github/workflows/build_and_deploy.yml`

```yaml
name: Build and Deploy

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.10.0'
        
    - name: Get dependencies
      run: flutter pub get
      
    - name: Analyze code
      run: flutter analyze
      
    - name: Run tests
      run: flutter test
      
    - name: Test coverage
      run: flutter test --coverage
      
    - name: Upload coverage
      uses: codecov/codecov-action@v3

  build-android:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.10.0'
        
    - name: Setup Java
      uses: actions/setup-java@v3
      with:
        distribution: 'zulu'
        java-version: '11'
        
    - name: Get dependencies
      run: flutter pub get
      
    - name: Build APK
      run: flutter build apk --release
      
    - name: Build App Bundle
      run: flutter build appbundle --release
      
    - name: Upload artifacts
      uses: actions/upload-artifact@v3
      with:
        name: android-builds
        path: |
          build/app/outputs/flutter-apk/
          build/app/outputs/bundle/

  build-ios:
    needs: test
    runs-on: macos-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.10.0'
        
    - name: Build iOS
      run: |
        flutter build ios --release --no-codesign
        
    - name: Upload artifacts
      uses: actions/upload-artifact@v3
      with:
        name: ios-build
        path: build/ios/

  build-web:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.10.0'
        
    - name: Build Web
      run: flutter build web --release
      
    - name: Deploy to GitHub Pages
      uses: peaceiris/actions-gh-pages@v3
      with:
        github_token: ${{ secrets.GITHUB_TOKEN }}
        publish_dir: ./build/web

  release:
    needs: [build-android, build-ios, build-web]
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
    - name: Create Release
      uses: actions/create-release@v1
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      with:
        tag_name: v${{ github.run_number }}
        release_name: Release v${{ github.run_number }}
        body: |
          Automatic release from CI/CD pipeline
          
          Changes in this release:
          - Android APK and App Bundle
          - iOS build
          - Web deployment
          
        draft: false
        prerelease: false
```

### Azure DevOps Pipeline

**File:** `azure-pipelines.yml`

```yaml
trigger:
- main
- develop

pool:
  vmImage: 'ubuntu-latest'

variables:
  flutterVersion: '3.10.0'

stages:
- stage: Test
  jobs:
  - job: RunTests
    steps:
    - task: FlutterInstall@0
      inputs:
        channel: 'stable'
        version: $(flutterVersion)
        
    - script: flutter pub get
      displayName: 'Get dependencies'
      
    - script: flutter analyze
      displayName: 'Analyze code'
      
    - script: flutter test
      displayName: 'Run tests'
      
    - task: PublishTestResults@2
      inputs:
        testResultsFormat: 'JUnit'
        testResultsFiles: 'test-results.xml'

- stage: Build
  dependsOn: Test
  condition: succeeded()
  jobs:
  - job: BuildAndroid
    steps:
    - task: FlutterInstall@0
      inputs:
        channel: 'stable'
        version: $(flutterVersion)
        
    - script: flutter build apk --release
      displayName: 'Build Android APK'
      
    - task: PublishBuildArtifacts@1
      inputs:
        pathToPublish: 'build/app/outputs/flutter-apk'
        artifactName: 'android-apk'

- stage: Deploy
  dependsOn: Build
  condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
  jobs:
  - deployment: DeployToStore
    environment: 'production'
    strategy:
      runOnce:
        deploy:
          steps:
          - task: GooglePlayRelease@4
            inputs:
              serviceConnection: 'Google Play Console'
              applicationId: 'com.example.diabetes'
              action: 'SingleBundle'
              bundleFile: '$(Pipeline.Workspace)/android-apk/app-release.aab'
```

---

## 🌍 Environment Configuration

### Development Environment
**File:** `lib/config/dev_config.dart`

```dart
class DevConfig {
  static const String environment = 'development';
  static const bool debugMode = true;
  static const bool enableAnalytics = false;
  static const bool enableCrashReporting = false;
  
  // API Configuration
  static const String apiBaseUrl = 'http://localhost:3000';
  static const Duration apiTimeout = Duration(seconds: 30);
  
  // ML Model Configuration
  static const String modelPath = 'assets/models/model_dev.tflite';
  static const bool useModelCache = false;
  
  // Feature Flags
  static const bool enableCloudSync = false;
  static const bool enableBetaFeatures = true;
  static const bool showDebugInfo = true;
}
```

### Production Environment
**File:** `lib/config/prod_config.dart`

```dart
class ProdConfig {
  static const String environment = 'production';
  static const bool debugMode = false;
  static const bool enableAnalytics = true;
  static const bool enableCrashReporting = true;
  
  // API Configuration
  static const String apiBaseUrl = 'https://api.deteksidiabetes.com';
  static const Duration apiTimeout = Duration(seconds: 10);
  
  // ML Model Configuration
  static const String modelPath = 'assets/models/model.tflite';
  static const bool useModelCache = true;
  
  // Feature Flags
  static const bool enableCloudSync = true;
  static const bool enableBetaFeatures = false;
  static const bool showDebugInfo = false;
}
```

### Environment Selector
**File:** `lib/config/app_config.dart`

```dart
import 'dev_config.dart';
import 'prod_config.dart';

class AppConfig {
  static late final AppEnvironment _environment;
  
  static void initialize({required AppEnvironment environment}) {
    _environment = environment;
  }
  
  static AppEnvironment get environment => _environment;
  static bool get isProduction => _environment == AppEnvironment.production;
  static bool get isDevelopment => _environment == AppEnvironment.development;
  
  // Proxy methods
  static bool get debugMode => isProduction ? ProdConfig.debugMode : DevConfig.debugMode;
  static String get apiBaseUrl => isProduction ? ProdConfig.apiBaseUrl : DevConfig.apiBaseUrl;
  static bool get enableAnalytics => isProduction ? ProdConfig.enableAnalytics : DevConfig.enableAnalytics;
  static String get modelPath => isProduction ? ProdConfig.modelPath : DevConfig.modelPath;
}

enum AppEnvironment { development, staging, production }
```

---

## 📊 Monitoring & Maintenance

### Health Monitoring

```dart
class AppHealthMonitor {
  static Timer? _healthCheckTimer;
  
  static void startMonitoring() {
    _healthCheckTimer = Timer.periodic(
      Duration(minutes: 5),
      (timer) => _performHealthCheck(),
    );
  }
  
  static void stopMonitoring() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
  }
  
  static Future<void> _performHealthCheck() async {
    final healthStatus = HealthStatus();
    
    // Check ML model status
    healthStatus.isModelLoaded = MLService.isModelLoaded;
    
    // Check storage availability
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('health_check', DateTime.now().toIso8601String());
      healthStatus.isStorageAvailable = true;
    } catch (e) {
      healthStatus.isStorageAvailable = false;
    }
    
    // Check memory usage
    final memory = await ProcessInfo.currentRss;
    healthStatus.memoryUsageMB = memory ~/ (1024 * 1024);
    
    // Check cache size
    healthStatus.cacheSize = await _getCacheSize();
    
    // Report health status
    await HealthReportingService.reportHealth(healthStatus);
    
    // Take action if unhealthy
    if (!healthStatus.isHealthy) {
      await _handleUnhealthyState(healthStatus);
    }
  }
  
  static Future<void> _handleUnhealthyState(HealthStatus status) async {
    if (!status.isModelLoaded) {
      await MLService.loadModel();
    }
    
    if (status.memoryUsageMB > 500) {
      await _clearCache();
    }
    
    if (status.cacheSize > AppConfig.maxCacheSize) {
      await _clearOldCache();
    }
  }
}

class HealthStatus {
  bool isModelLoaded = false;
  bool isStorageAvailable = false;
  int memoryUsageMB = 0;
  int cacheSize = 0;
  
  bool get isHealthy => isModelLoaded && isStorageAvailable && memoryUsageMB < 500;
}
```

### Crash Reporting

```dart
class CrashReportingService {
  static bool _isInitialized = false;
  
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Setup Flutter error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      reportFlutterError(details);
    };
    
    // Setup Dart error handling
    PlatformDispatcher.instance.onError = (error, stack) {
      reportDartError(error, stack);
      return true;
    };
    
    _isInitialized = true;
  }
  
  static void reportFlutterError(FlutterErrorDetails details) {
    final crashReport = CrashReport(
      type: CrashType.flutter,
      error: details.exception.toString(),
      stackTrace: details.stack.toString(),
      timestamp: DateTime.now(),
      context: _getCurrentContext(),
    );
    
    _sendCrashReport(crashReport);
  }
  
  static void reportDartError(Object error, StackTrace stackTrace) {
    final crashReport = CrashReport(
      type: CrashType.dart,
      error: error.toString(),
      stackTrace: stackTrace.toString(),
      timestamp: DateTime.now(),
      context: _getCurrentContext(),
    );
    
    _sendCrashReport(crashReport);
  }
  
  static Future<void> _sendCrashReport(CrashReport report) async {
    try {
      // Save to local storage first
      await _saveCrashReportLocally(report);
      
      // Send to remote service if available
      if (AppConfig.enableCrashReporting) {
        await _sendToRemoteService(report);
      }
    } catch (e) {
      print('Failed to send crash report: $e');
    }
  }
}
```

### Performance Monitoring

```dart
class PerformanceMonitor {
  static final Map<String, PerformanceMetric> _metrics = {};
  static Timer? _reportingTimer;
  
  static void startMonitoring() {
    _reportingTimer = Timer.periodic(
      Duration(minutes: 10),
      (timer) => _reportMetrics(),
    );
  }
  
  static void recordMetric({
    required String name,
    required Duration duration,
    Map<String, dynamic>? metadata,
  }) {
    final metric = _metrics.putIfAbsent(
      name,
      () => PerformanceMetric(name: name),
    );
    
    metric.addMeasurement(duration, metadata);
  }
  
  static Future<void> _reportMetrics() async {
    final report = PerformanceReport(
      timestamp: DateTime.now(),
      metrics: Map.from(_metrics),
      deviceInfo: await _getDeviceInfo(),
      appVersion: AppConfig.appVersion,
    );
    
    await PerformanceReportingService.sendReport(report);
    
    // Clear old metrics
    _metrics.clear();
  }
}

class PerformanceMetric {
  final String name;
  final List<Duration> measurements = [];
  final List<Map<String, dynamic>> metadata = [];
  
  PerformanceMetric({required this.name});
  
  void addMeasurement(Duration duration, Map<String, dynamic>? meta) {
    measurements.add(duration);
    if (meta != null) metadata.add(meta);
  }
  
  Duration get averageDuration {
    if (measurements.isEmpty) return Duration.zero;
    final totalMs = measurements
        .map((d) => d.inMilliseconds)
        .reduce((a, b) => a + b);
    return Duration(milliseconds: totalMs ~/ measurements.length);
  }
  
  Duration get maxDuration => measurements.isEmpty 
      ? Duration.zero 
      : measurements.reduce((a, b) => a > b ? a : b);
      
  Duration get minDuration => measurements.isEmpty 
      ? Duration.zero 
      : measurements.reduce((a, b) => a < b ? a : b);
}
```

---

## 🔧 Troubleshooting Guide

### Common Build Issues

#### 1. Gradle Build Failures
```bash
# Issue: Gradle build fails with "Could not resolve all artifacts"
# Solution:
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter build apk
```

#### 2. iOS Build Failures
```bash
# Issue: iOS build fails with pod install errors
# Solution:
cd ios
rm -rf Pods
rm -rf .symlinks
rm Podfile.lock
pod install --repo-update
cd ..
flutter clean
flutter build ios
```

#### 3. Web Build Issues
```bash
# Issue: Web build fails with "Failed to compile application"
# Solution:
flutter clean
flutter pub get
flutter build web --release --no-tree-shake-icons
```

### Runtime Issues

#### 1. Model Loading Failures
```dart
// Check if model file exists
bool modelExists = await File('assets/models/model.tflite').exists();
if (!modelExists) {
  // Handle missing model file
  throw ModelNotFoundException('Model file not found');
}

// Check model compatibility
try {
  await MLService.loadModel();
} catch (e) {
  // Handle incompatible model
  await _downloadLatestModel();
  await MLService.loadModel();
}
```

#### 2. Memory Issues
```dart
// Monitor memory usage
class MemoryMonitor {
  static Future<void> checkMemoryUsage() async {
    final memory = await ProcessInfo.currentRss;
    final memoryMB = memory ~/ (1024 * 1024);
    
    if (memoryMB > 300) {  // Threshold 300MB
      await _performMemoryCleanup();
    }
  }
  
  static Future<void> _performMemoryCleanup() async {
    // Clear image cache
    PaintingBinding.instance.imageCache.clear();
    
    // Clear ML model cache
    MLService.clearCache();
    
    // Clear chat history cache
    ChatService.clearOldMessages();
    
    // Force garbage collection
    await Future.delayed(Duration(milliseconds: 100));
  }
}
```

#### 3. Storage Issues
```dart
// Handle storage quota exceeded
class StorageManager {
  static Future<void> checkStorageSpace() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      // Calculate total storage used
      int totalSize = 0;
      for (String key in keys) {
        final value = prefs.get(key);
        if (value is String) {
          totalSize += value.length;
        }
      }
      
      // If storage is over limit, cleanup
      if (totalSize > 10 * 1024 * 1024) {  // 10MB limit
        await _cleanupOldData();
      }
    } catch (e) {
      print('Storage check failed: $e');
    }
  }
  
  static Future<void> _cleanupOldData() async {
    // Remove old detection results
    await HistoryService.removeOldResults(daysToKeep: 30);
    
    // Remove old chat messages
    await ChatService.removeOldMessages(daysToKeep: 7);
    
    // Clear temporary files
    await _clearTempFiles();
  }
}
```

### Deployment Issues

#### 1. Android Signing Issues
```bash
# Generate new keystore
keytool -genkey -v -keystore app-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias diabetes-app

# Verify keystore
keytool -list -v -keystore app-release-key.jks

# Check if app is signed
jarsigner -verify -verbose -certs app-release.apk
```

#### 2. iOS Provisioning Issues
```bash
# Clean derived data
rm -rf ~/Library/Developer/Xcode/DerivedData

# Update provisioning profiles
xcrun notarytool store-credentials --apple-id "your-email@example.com" --team-id "TEAMID123" --password "app-password"

# Check certificates
security find-identity -v -p codesigning
```

### Performance Issues

#### 1. Slow App Launch
```dart
// Optimize app initialization
class AppInitializer {
  static Future<void> optimizedInitialize() async {
    // Load critical components first
    await _loadCriticalComponents();
    
    // Load non-critical components in background
    unawaited(_loadNonCriticalComponents());
  }
  
  static Future<void> _loadCriticalComponents() async {
    await SharedPreferences.getInstance();
    await AuthService.initialize();
  }
  
  static Future<void> _loadNonCriticalComponents() async {
    await MLService.loadModel();
    await AnalyticsService.initialize();
  }
}
```

#### 2. Slow ML Inference
```dart
// Optimize ML inference
class MLOptimizer {
  static Future<DetectionResult> optimizedPredict(File imageFile) async {
    // Check cache first
    final cacheKey = await _generateCacheKey(imageFile);
    final cachedResult = await _getCachedResult(cacheKey);
    if (cachedResult != null) {
      return cachedResult;
    }
    
    // Optimize image before processing
    File optimizedImage = await _optimizeImage(imageFile);
    
    // Run inference with timeout
    DetectionResult result = await Future.timeout(
      MLService.predictImage(optimizedImage),
      Duration(seconds: 10),
      onTimeout: () => throw TimeoutException('ML inference timeout'),
    );
    
    // Cache result
    await _cacheResult(cacheKey, result);
    
    return result;
  }
}
```

---

## 📋 Maintenance Checklist

### Daily Maintenance
- [ ] Check crash reports
- [ ] Monitor app performance metrics
- [ ] Review error logs
- [ ] Check storage usage

### Weekly Maintenance
- [ ] Update dependencies
- [ ] Run security scan
- [ ] Performance optimization
- [ ] Backup user data

### Monthly Maintenance
- [ ] Update ML model if needed
- [ ] Review and update documentation
- [ ] Analyze user feedback
- [ ] Plan feature updates

### Quarterly Maintenance
- [ ] Major dependency updates
- [ ] Security audit
- [ ] Performance benchmarking
- [ ] User experience review

---

**🔄 Terakhir diperbarui:** 23 Juni 2025

**📞 Support:** Untuk bantuan deployment, hubungi tim development atau buat issue di repository.
