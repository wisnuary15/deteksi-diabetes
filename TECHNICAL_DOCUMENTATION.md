# 🔧 Dokumentasi Teknis - Services & Components

## 📋 Daftar Isi
1. [Authentication Services](#authentication-services)
2. [ML & Detection Services](#ml--detection-services)
3. [Chat & AI Services](#chat--ai-services)
4. [Data Management Services](#data-management-services)
5. [UI Components](#ui-components)
6. [Models & Data Structures](#models--data-structures)

---

## 🔐 Authentication Services

### `auth_service.dart`
**Tujuan:** Mengelola autentikasi pengguna dan session management

**Fungsi Utama:**
- `login(String username, String password)` - Login pengguna
- `register(UserData userData)` - Registrasi pengguna baru
- `logout()` - Logout dan clear session
- `isAuthenticated()` - Cek status autentikasi
- `getCurrentUser()` - Mendapatkan data pengguna aktif

**Dependencies:**
- `shared_preferences` - Penyimpanan session
- `crypto` - Enkripsi password

**Security Features:**
- Password hashing dengan salt
- Session timeout management
- Secure token storage

---

## 🤖 ML & Detection Services

### `ml_service.dart`
**Tujuan:** Service untuk machine learning inference menggunakan TensorFlow Lite

**Spesifikasi Model:**
```dart
static const int INPUT_SIZE = 180;     // 180x180 pixels
static const int NUM_CHANNELS = 3;     // RGB channels
static const int NUM_CLASSES = 2;      // diabetes, non_diabetes
```

**Fungsi Utama:**
- `loadModel()` - Load model TensorFlow Lite dari assets
- `predictImage(File imageFile)` - Prediksi gambar
- `preprocessImage(File imageFile)` - Preprocessing gambar
- `postprocessOutput(List<double> output)` - Interpretasi hasil

**Pipeline Deteksi:**
1. **Input Validation** - Validasi format dan ukuran gambar
2. **Preprocessing** - Resize ke 180x180, normalisasi pixel
3. **Inference** - Jalankan model TensorFlow Lite
4. **Postprocessing** - Konversi output ke DetectionResult
5. **Caching** - Simpan hasil untuk performa

**Error Handling:**
- Model loading failures
- Invalid image formats
- Memory management
- Inference errors

### `detection_sync_service.dart`
**Tujuan:** Sinkronisasi hasil deteksi dengan storage lokal

**Fungsi Utama:**
- `saveDetectionResult(DetectionResult result)` - Simpan hasil
- `getDetectionHistory()` - Ambil riwayat deteksi
- `syncWithCloud()` - Sinkronisasi cloud (future feature)
- `clearCache()` - Bersihkan cache lama

---

## 💬 Chat & AI Services

### `chat_service.dart`
**Tujuan:** Mengelola percakapan dengan AI dokter virtual

**Fungsi Utama:**
- `sendMessage(String message)` - Kirim pesan ke AI
- `getResponse(String userMessage, UserContext context)` - Dapatkan respons AI
- `getChatHistory()` - Ambil riwayat chat
- `clearChat()` - Bersihkan percakapan

**AI Features:**
- Context-aware responses
- Medical knowledge base
- Personalized recommendations
- Safety guardrails untuk medical advice

### `detection_chat_service.dart`
**Tujuan:** Chat AI spesifik untuk hasil deteksi

**Fungsi Utama:**
- `explainDetectionResult(DetectionResult result)` - Jelaskan hasil deteksi
- `getRecommendations(DetectionResult result)` - Rekomendasi berdasarkan hasil
- `generateFollowUpQuestions()` - Pertanyaan lanjutan
- `getEducationalContent(String topic)` - Konten edukasi terkait

### `chat_preferences_service.dart`
**Tujuan:** Mengelola preferensi pengguna untuk chat AI

**Preferensi yang Dikelola:**
- Gaya komunikasi (formal/casual)
- Bahasa preferensi
- Topik kesehatan yang diminati
- Frequency reminder
- Privacy settings

---

## 📊 Data Management Services

### `user_profile_service.dart`
**Tujuan:** Mengelola profil pengguna dan data kesehatan

**Fungsi Utama:**
- `createProfile(UserProfile profile)` - Buat profil baru
- `updateProfile(UserProfile profile)` - Update profil
- `getProfile()` - Ambil data profil
- `validateProfile(UserProfile profile)` - Validasi data
- `calculateHealthMetrics()` - Hitung metrik kesehatan

**Data yang Dikelola:**
```dart
class UserProfile {
  String name;
  int age;
  String gender;
  double height;    // cm
  double weight;    // kg
  String bloodType;
  List<String> medicalHistory;
  String profileImagePath;
  DateTime lastUpdated;
}
```

### `history_service.dart`
**Tujuan:** Mengelola riwayat deteksi dan tracking

**Fungsi Utama:**
- `addDetectionRecord(DetectionResult result)` - Tambah record
- `getDetectionHistory(DateRange range)` - Ambil riwayat
- `getHealthTrends()` - Analisis tren kesehatan
- `exportHistory(ExportFormat format)` - Export data
- `deleteOldRecords(int daysToKeep)` - Cleanup data lama

**Analytics Features:**
- Trend analysis
- Statistical insights
- Health score calculation
- Progress tracking

### `hospital_service.dart`
**Tujuan:** Mengelola data rumah sakit dan layanan lokasi

**Fungsi Utama:**
- `getNearbyHospitals(Location userLocation)` - Cari RS terdekat
- `getHospitalDetails(String hospitalId)` - Detail RS
- `getDirections(Hospital hospital)` - Navigasi
- `filterHospitals(FilterCriteria criteria)` - Filter RS

**Data Structure:**
```dart
class Hospital {
  String id;
  String name;
  String address;
  Location coordinates;
  List<String> services;
  String phoneNumber;
  OperatingHours hours;
  double rating;
  List<Review> reviews;
}
```

### `education_repository.dart`
**Tujuan:** Repository untuk artikel edukasi kesehatan

**Fungsi Utama:**
- `getArticles(String category)` - Ambil artikel berdasarkan kategori
- `getArticleById(String id)` - Detail artikel
- `searchArticles(String query)` - Pencarian artikel
- `getPopularArticles()` - Artikel populer
- `markAsRead(String articleId)` - Tandai telah dibaca

---

## 🎨 UI Components

### `modern_app_bar.dart`
**Tujuan:** Reusable AppBar dengan design modern

**Features:**
- Gradient background
- Custom actions
- Dynamic title
- Back button handling
- Elevation control

**Usage:**
```dart
ModernAppBar(
  title: 'Deteksi Diabetes',
  useGradient: true,
  gradientColors: [Colors.blue, Colors.lightBlue],
  actions: [/* custom actions */],
)
```

### `modern_card.dart`
**Tujuan:** Kartu modern dengan shadow dan rounded corners

**Variants:**
- `ModernCard` - Basic card
- `ModernGradientCard` - Card dengan gradient
- `ModernAnimatedCard` - Card dengan animasi

**Features:**
- Consistent styling
- Hover effects
- Tap feedback
- Shadow elevation
- Border radius control

### `profile_header_widget.dart`
**Tujuan:** Header profil pengguna yang reusable

**Features:**
- Avatar dengan placeholder
- Welcome message
- Quick stats
- Edit functionality
- Responsive design

---

## 📋 Models & Data Structures

### `detection_result.dart`
**Tujuan:** Model untuk hasil deteksi diabetes

```dart
class DetectionResult {
  String id;
  String imagePath;
  String prediction;        // 'diabetes' atau 'non_diabetes'
  double confidence;        // 0.0 - 1.0
  DateTime timestamp;
  String interpretation;    // Penjelasan hasil
  List<String> recommendations;
  Map<String, dynamic> rawOutput;
}
```

### `chat_models.dart`
**Tujuan:** Models untuk sistem chat

```dart
class ChatMessage {
  String id;
  String content;
  ChatMessageType type;     // user, ai, system
  DateTime timestamp;
  Map<String, dynamic> metadata;
}

class ChatSession {
  String sessionId;
  List<ChatMessage> messages;
  UserContext userContext;
  DateTime startTime;
  bool isActive;
}
```

### `education_article.dart`
**Tujuan:** Model untuk artikel edukasi

```dart
class EducationArticle {
  String id;
  String title;
  String content;
  String category;
  String author;
  DateTime publishDate;
  List<String> tags;
  String thumbnailUrl;
  int readingTime;          // dalam menit
  bool isBookmarked;
}
```

### `user.dart` & `user_profile.dart`
**Tujuan:** Models untuk data pengguna

```dart
class User {
  String id;
  String username;
  String email;
  String hashedPassword;
  DateTime createdAt;
  DateTime lastLogin;
  bool isActive;
}

class UserProfile {
  String userId;
  PersonalInfo personalInfo;
  HealthInfo healthInfo;
  AppPreferences preferences;
  DateTime lastUpdated;
}
```

---

## 🔄 Service Interactions

### Detection Flow
```
CameraScreen → ml_service.dart → DetectionResult
     ↓
history_service.dart → Local Storage
     ↓
detection_chat_service.dart → AI Explanation
```

### Chat Flow
```
ChatScreen → chat_service.dart → AI Response
     ↓
chat_preferences_service.dart → Personalization
     ↓
user_profile_service.dart → Context
```

### Education Flow
```
EducationScreen → education_repository.dart → Articles
     ↓
ArticleDetailScreen → Reading Experience
     ↓
Share Functionality → System Share
```

---

## 🔧 Configuration & Constants

### `app_colors.dart`
**Tujuan:** Centralized color management

```dart
class AppColors {
  static const Color primary = Color(0xFF1976D2);
  static const Color secondary = Color(0xFF42A5F5);
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFDC2626);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
}
```

---

## 🚀 Performance Optimizations

### Memory Management
- Image compression sebelum processing
- Model lazy loading
- Cache management untuk hasil deteksi
- Garbage collection untuk chat history

### Network Optimization
- Offline-first architecture
- Compression untuk data sync
- Retry mechanism untuk network calls
- Caching strategy untuk static content

### UI Performance
- Widget reusability
- Lazy loading untuk lists
- Image optimization
- Animation performance

---

## 🛡️ Error Handling Strategy

### Global Error Handling
```dart
class AppError {
  ErrorType type;
  String message;
  String? technicalDetails;
  DateTime timestamp;
  bool isRecoverable;
}
```

### Error Types
- `NetworkError` - Koneksi internet
- `ModelError` - ML model issues
- `ValidationError` - Input validation
- `StorageError` - Local storage issues
- `PermissionError` - Device permissions

### Recovery Mechanisms
- Automatic retry dengan exponential backoff
- Fallback ke cached data
- User-friendly error messages
- Error reporting untuk debugging

---

**📝 Catatan Teknis:** 
- Semua services menggunakan dependency injection pattern
- Error handling menggunakan try-catch dengan specific exceptions
- Async operations menggunakan Future/Stream patterns
- State management menggunakan StatefulWidget dan setState
- Data persistence menggunakan SharedPreferences untuk simplicity

**🔄 Terakhir diperbarui:** 23 Juni 2025
