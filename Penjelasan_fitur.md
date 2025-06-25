# 📱 Dokumentasi Fitur Aplikasi Deteksi Diabetes

> **📚 Dokumentasi Lengkap Tersedia:**
> - **[TECHNICAL_DOCUMENTATION.md](TECHNICAL_DOCUMENTATION.md)** - Dokumentasi teknis untuk developer
> - **[API_DOCUMENTATION.md](API_DOCUMENTATION.md)** - API dan integration guide
> - **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - Panduan deployment dan maintenance  
> - **[USER_GUIDE.md](USER_GUIDE.md)** - Panduan lengkap untuk pengguna

## 🏠 Gambaran Umum Aplikasi

MUNGKIN BISA MEMBANTU :D

**Nama Aplikasi:** DeteksiDiabetes  
**Platform:** Flutter (iOS, Android, Web, Windows)  
**Tujuan:** Aplikasi kesehatan yang menggunakan teknologi AI untuk mendeteksi diabetes melalui analisis gambar lidah dan menyediakan layanan konsultasi serta edukasi kesehatan.

---

## 🎯 Fitur-Fitur Utama

### 1. 🔐 **Sistem Autentikasi & Profil Pengguna**

#### 1.1 Login & Register
- **File:** `login_screen.dart`, `register_screen.dart`
- **Service:** `auth_service.dart`
- **Fitur:**
  - Login dengan username/email dan password
  - Registrasi akun baru dengan validasi
  - Penyimpanan session pengguna
  - Keamanan dengan enkripsi password

#### 1.2 Profil Pengguna
- **File:** `profile_screen.dart`, `edit_profile_screen.dart`, `user_profile_setup_screen.dart`
- **Service:** `user_profile_service.dart`, `profile_image_service.dart`
- **Database:** SQLite (`sqflite` package) untuk data lokal
- **Storage:** SharedPreferences untuk preferensi, FlutterSecureStorage untuk data sensitif
- **Fitur:**
  - Setup profil kesehatan lengkap
  - Upload dan edit foto profil
  - Pengelolaan data personal
  - Analytics profil pengguna
  - Perubahan password (`change_password_screen.dart`)

**📊 Data Profil yang Disimpan:**
- Informasi pribadi (nama, umur, jenis kelamin)
- Data kesehatan (tinggi badan, berat badan, riwayat penyakit)
- Foto profil
- Preferensi aplikasi

**🔧 Teknologi Storage:**
- **SQLite Database** - Data profil dan riwayat kesehatan
- **SharedPreferences** - Pengaturan aplikasi dan cache
- **FlutterSecureStorage** - Password dan data sensitif (terenkripsi)
- **Local File System** - Penyimpanan foto profil dan gambar deteksi

---

### 2. 🔍 **Deteksi Diabetes dengan AI**

#### 2.1 Deteksi Melalui Kamera
- **File:** `camera_screen.dart`, `result_screen.dart`
- **Service:** `ml_service.dart`
- **Model:** `assets/models/model.tflite //lokasi file model e`
- **Database:** SQLite untuk menyimpan riwayat hasil deteksi
- **Image Processing:** `image` package untuk preprocessing
- **Fitur:**
  - Pengambilan gambar lidah melalui kamera
  - Analisis gambar menggunakan TensorFlow Lite
  - Hasil deteksi diabetes/non-diabetes
  - Confidence score dan rekomendasi

**🔬 Teknologi yang Digunakan:**
- **TensorFlow Lite** untuk inferensi model AI
- **Image Processing** untuk preprocessing gambar
- **Input Size**: 180x180 pixels, 3 channels (RGB)
- **Output Classes**: 2 (diabetes, non_diabetes)
- **Camera Plugin**: `image_picker` untuk capture gambar
- **Storage**: File system lokal untuk menyimpan gambar

#### 2.2 Hasil Deteksi
- **Model:** `detection_result.dart`
- **Service:** `detection_sync_service.dart`
- **Database:** SQLite dengan tabel `detection_results`
- **Fitur:**
  - Tampilan hasil deteksi yang user-friendly
  - Confidence level dan interpretasi
  - Rekomendasi tindakan lanjutan
  - Penyimpanan hasil ke riwayat

**🗄️ Database Schema (SQLite):**
```sql
CREATE TABLE detection_results (
  id TEXT PRIMARY KEY,
  image_path TEXT NOT NULL,
  prediction TEXT NOT NULL,
  confidence REAL NOT NULL,
  timestamp INTEGER NOT NULL,
  interpretation TEXT,
  recommendations TEXT
);
```

---

### 3. 💬 **Sistem Chat AI (DrAI)**

#### 3.1 Chat dengan AI Dokter
- **File:** `chat_screen.dart`, `chat_settings_screen.dart`
- **Service:** `chat_service.dart`, `detection_chat_service.dart`
- **Model:** `chat_models.dart`
- **AI Backend:** menggunakan api dari google ai studio model gemini 1.5 flash dengan modifikasi/customisasi respon ai
- **Database:** SQLite untuk riwayat chat
- **Fitur:**
  - Konsultasi dengan AI dokter virtual
  - Chat berbasis konteks hasil deteksi
  - Riwayat percakapan
  - Pengaturan preferensi chat

#### 3.2 Preferensi Chat
- **File:** `chat_preferences_demo_screen.dart`
- **Service:** `chat_preferences_service.dart`
- **Utils:** `chat_preferences.dart`
- **Storage:** SharedPreferences untuk menyimpan preferensi
- **Fitur:**
  - Kustomisasi gaya komunikasi AI
  - Pengaturan bahasa dan tone
  - Preferensi topik kesehatan
  - Demo interaksi chat

**💡 Fitur Chat AI:**
- Respons real-time
- Konteks aware (berdasarkan hasil deteksi)
- Personalisasi berdasarkan profil pengguna
- Rekomendasi medis yang aman

**🤖 AI Chat Technology Stack:**
- **Model gemini 1.5 flash** - Rule-based responses dengan knowledge base internet
- **External API** - ambil data gemini 
- **Context Engine** - Mengintegrasikan hasil deteksi dengan respons chat
- **Knowledge Base** - Database lokal berisi informasi medis diabetes
- **SQLite Chat History** - Tabel `chat_messages` dan `chat_sessions`

**🗄️ Chat Database Schema:**
```sql
CREATE TABLE chat_sessions (
  id TEXT PRIMARY KEY,
  user_id TEXT,
  created_at INTEGER,
  last_activity INTEGER
);

CREATE TABLE chat_messages (
  id TEXT PRIMARY KEY,
  session_id TEXT,
  content TEXT NOT NULL,
  sender_type TEXT NOT NULL, -- 'user' atau 'ai'
  timestamp INTEGER NOT NULL,
  context_data TEXT -- JSON data untuk konteks
);
```

---

### 4. 📚 **Sistem Edukasi Kesehatan**

#### 4.1 Artikel Edukasi
- **File:** `education_screen.dart`, `article_detail_screen.dart`
- **Service:** `education_repository.dart`
- **Model:** `education_article.dart`
- **Database:** SQLite dengan tabel `education_articles`
- **Content Storage:** Ambil data dari news api
- **Fitur:**
  - Koleksi artikel kesehatan
  - Kategorisasi artikel (Tips Kesehatan, Nutrisi, Olahraga, dll.)
  - Pembaca artikel dengan fitur aksesibilitas
  - Sistem sharing artikel

#### 4.2 Fitur Pembaca Artikel
- **File:** `article_detail_screen.dart`
- **Storage:** SharedPreferences untuk pengaturan pembaca
- **Fitur:**
  - Pengaturan ukuran font (12-24px)
  - Mode gelap/terang //BOHONG GORONG ISO IKI
  - Sharing artikel ke clipboard
  - Navigasi kategori dengan warna-koding

**📋 Kategori Artikel:**
- 🟢 Tips Kesehatan
- 🟠 Nutrisi
- 🔵 Olahraga
- 🔴 Informasi Medis
- 🟣 Berita Kesehatan

**📚 Education Content Technology:**
- **SQLite Database** - Metadata artikel dan bookmark
- **Ambil data dari news api
- **SharedPreferences** - Reading preferences (font, theme)
- **Flutter Sharing Plugin** - Share ke platform lain

**🗄️ Education Database Schema:**
```sql
CREATE TABLE education_articles (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  category TEXT NOT NULL,
  content_path TEXT, -- Path ke file konten
  thumbnail_url TEXT,
  author TEXT,
  publish_date INTEGER,
  reading_time INTEGER,
  is_bookmarked INTEGER DEFAULT 0
);

CREATE TABLE article_tags (
  article_id TEXT,
  tag TEXT,
  FOREIGN KEY (article_id) REFERENCES education_articles (id)
);
```

---

### 5. 📊 **Sistem Riwayat & Tracking**

#### 5.1 Riwayat Deteksi
- **File:** `history_screen.dart`
- **Service:** `history_service.dart`
- **Database:** SQLite dengan indexing untuk performa optimal
- **Analytics:** Local processing untuk tren dan statistik
- **Fitur:**
  - Riwayat lengkap hasil deteksi
  - Tracking progress kesehatan
  - Analisis tren hasil
  - Export data riwayat

#### 5.2 Analytics Kesehatan
- **Service:** `profile_analytics_service.dart`
- **Database:** SQLite dengan tabel terpisah untuk metrics
- **Chart Library:** `fl_chart` package untuk visualisasi
- **Fitur:**
  - Analisis pola kesehatan
  - Rekomendasi berdasarkan tren
  - Peringatan kesehatan

**📊 Health Tracking Technology:**
- **SQLite Database** - Primary storage untuk semua riwayat
- **Local Analytics Engine** - Processing statistik dan tren
- **Chart Visualization** - fl_chart untuk grafik interaktif
- **Export Functionality** - CSV/PDF export menggunakan packages lokal

**🗄️ Health Tracking Database Schema:**
```sql
CREATE TABLE health_metrics (
  id TEXT PRIMARY KEY,
  user_id TEXT,
  metric_type TEXT, -- 'detection', 'weight', 'blood_sugar', etc
  value REAL,
  unit TEXT,
  timestamp INTEGER,
  notes TEXT
);

CREATE TABLE health_trends (
  id TEXT PRIMARY KEY,
  user_id TEXT,
  period TEXT, -- 'daily', 'weekly', 'monthly'
  trend_type TEXT,
  trend_direction TEXT, -- 'improving', 'stable', 'declining'
  calculated_at INTEGER
);
```

---

POKOK E NGENE LAH, MUNGKIN INI BISA MEMBANTU

### 6. 🏥 **Lokasi Rumah Sakit Terdekat**

#### 6.1 Peta Rumah Sakit
- **File:** `hospital_map_screen.dart`
- **Service:** `hospital_service.dart`
- **Map Provider:** OpenStreetMap (flutter_map package)
- **Data Source:** Overpass API untuk data rumah sakit
- **Location:** Geolocator package untuk GPS
- **Fitur:**
  - Peta interaktif rumah sakit terdekat
  - Informasi detail rumah sakit
  - Navigasi ke lokasi
  - Filter berdasarkan jenis layanan

**🗺️ Fitur Peta:**
- Integrasi OpenStreetMap
- Overpass API untuk data POI
- Geolocation tracking
- Radius pencarian 15 rumah sakit terdekat (jika ada)
- Informasi kontak dan jam operasional

**🌍 Maps & Location Technology Stack:**
- **OpenStreetMap** - Base map tiles (gratis, open source)
- **flutter_map** - Flutter widget untuk menampilkan peta
- **Overpass API** - Query rumah sakit dari OpenStreetMap database
- **Geolocator** - GPS location services
- **Geocoding** - Convert koordinat ke alamat
- **URL Launcher** - Buka navigasi eksternal (Google Maps/Waze)

**🏥 Hospital Data Source:**
- **Overpass API Query:**
```
[out:json][timeout:25];
(
  node["amenity"="hospital"](around:5000,{lat},{lon});
  way["amenity"="hospital"](around:5000,{lat},{lon});
  relation["amenity"="hospital"](around:5000,{lat},{lon});
);
out body;
```

**🗄️ Hospital Cache Database:**
```sql
CREATE TABLE cached_hospitals (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  latitude REAL NOT NULL,
  longitude REAL NOT NULL,
  address TEXT,
  phone TEXT,
  website TEXT,
  services TEXT, -- JSON array
  cached_at INTEGER,
  last_updated INTEGER
);
```

---

### 7. 🎨 **Komponen UI/UX**

#### 7.1 Design System
- **File:** `app_colors.dart`
- **Widgets:** `modern_app_bar.dart`, `modern_card.dart`, `profile_header_widget.dart`
- **Fitur:**
  - Consistent color scheme
  - Modern gradient design
  - Reusable components
  - Responsive layout

#### 7.2 Tema Aplikasi
- **File:** `main.dart`
- **Fitur:**
  - Material Design 3
  - Custom color scheme
  - Professional typography
  - Accessibility support

**🎨 Color Palette:**
- Primary: #1976D2 (Blue)
- Secondary: #42A5F5 (Light Blue)
- Success: Green
- Warning: Orange
- Error: #DC2626 (Red)

---

## 🏗️ Arsitektur Aplikasi

### Struktur Folder
```
lib/
├── constants/          # Konstanta aplikasi (warna, tema)
├── models/            # Data models dan struktur data
├── repositories/      # Repository pattern untuk data
├── screens/           # UI Screens/Pages
├── services/          # Business logic dan API calls
├── utils/             # Utility functions
├── viewmodels/        # State management (jika diperlukan)
└── widgets/           # Reusable UI components
```

### Design Patterns
- **Repository Pattern** untuk data management
- **Service Layer** untuk business logic
- **Widget Composition** untuk UI reusability
- **Dependency Injection** untuk loose coupling

---

## 📱 Pengalaman Pengguna (User Journey)

### 1. Onboarding Flow
```
Splash Screen → Login/Register → Profile Setup → Main Menu
```

### 2. Detection Flow
```
Main Menu → Camera → Take Photo → AI Processing → Results → History
```

### 3. Consultation Flow
```
Main Menu → Chat AI → Conversation → Recommendations → Follow-up
```

### 4. Education Flow
```
Main Menu → Education → Article List → Article Detail → Share
```

---

## 🔧 Teknologi & Dependencies

### Core Technologies
- **Flutter Framework** (Cross-platform)
- **TensorFlow Lite** (AI/ML)
- **SQLite Database** (`sqflite` package) - Primary database
- **SharedPreferences** (App preferences & cache)
- **FlutterSecureStorage** (Sensitive data encryption)
- **Camera Plugin** (`image_picker` untuk image capture)
- **Image Processing** (`image` package untuk preprocessing)

### Key Packages & External Services
- `tflite_flutter` - Machine learning inference (offline)
- `sqflite` - SQLite database untuk data persistence
- `image_picker` - Camera functionality
- `shared_preferences` - Local preferences storage
- `flutter_secure_storage` - Encrypted storage
- `image` - Image processing dan optimization
- `geolocator` - Location services (GPS)
- `geocoding` - Address resolution
- `flutter_map` - OpenStreetMap integration
- `latlong2` - Geographic coordinate handling
- `url_launcher` - External app integration
- `fl_chart` - Data visualization dan charts

### Database Architecture
**Primary Database:** SQLite (Local)
- **User Profiles** - Informasi pengguna dan preferensi
- **Detection Results** - Riwayat hasil deteksi AI
- **Chat History** - Percakapan dengan AI
- **Education Content** - Artikel dan metadata
- **Health Metrics** - Tracking data kesehatan
- **Hospital Cache** - Cache data rumah sakit terdekat

### External APIs & Services
- **OpenStreetMap** - Map tiles dan geographic data
- **Overpass API** - Query POI data (rumah sakit) dari OSM
- **No Cloud Dependencies** - Semua processing dilakukan offline

### AI/ML Stack
- **TensorFlow Lite Model** - Diabetes detection (local inference)
- **Image Preprocessing** - Native Dart image manipulation
- **Local Knowledge Base** - Rule-based AI chat responses
- **No External AI APIs** - Semua AI processing offline

---

## 🚀 Fitur Unggulan

### 1. **AI-Powered Detection**
- Deteksi diabetes melalui analisis gambar lidah
- Akurasi tinggi dengan model TensorFlow Lite
- Preprocessing gambar otomatis

### 2. **Smart Chat Assistant**
- AI dokter virtual (DrAI)
- Respons contextual berdasarkan hasil deteksi
- Personalisasi berdasarkan profil pengguna

### 3. **Comprehensive Health Tracking**
- Riwayat deteksi lengkap
- Analytics kesehatan personal
- Trend monitoring

### 4. **User-Centered Design**
- Modern, intuitive interface
- Accessibility features
- Responsive design

### 5. **Offline Capability**
- Model AI tersimpan lokal (TensorFlow Lite)
- Data profil tersimpan offline (SQLite + SharedPreferences)
- Chat AI processing offline (local knowledge base)
- Map tiles cache untuk akses offline
- Sinkronisasi saat online (hospital data refresh)

---

## 📊 Metrics & Analytics

### User Engagement
- Deteksi harian/mingguan/bulanan
- Waktu penggunaan aplikasi
- Interaksi dengan chat AI
- Artikel yang dibaca

### Health Metrics
- Accuracy rate deteksi
- Confidence score trends
- User health improvement
- Consultation frequency

---

## 🔮 Roadmap Pengembangan

### Version 2.0 (Planned)
- [ ] Integrasi dengan wearable devices
- [ ] Advanced analytics dashboard
- [ ] Multi-language support
- [ ] Cloud sync untuk data
- [ ] Telemedicine integration

### Version 2.1 (Future)
- [ ] Voice-to-text untuk chat
- [ ] Reminder dan notifikasi
- [ ] Family health tracking
- [ ] Integration dengan health records

---

## 🛡️ Security & Privacy

### Data Protection
- Enkripsi data lokal
- Secure authentication
- No cloud storage untuk data sensitif
- GDPR compliance ready

### Privacy Features
- Data minimization
- User consent management
- Opt-out options
- Transparent data usage

---

## 📞 Support & Maintenance

### Error Handling
- Graceful error recovery
- User-friendly error messages
- Logging untuk debugging
- Crash reporting

### Performance Optimization
- Lazy loading
- Image compression
- Memory management
- Battery optimization

---

**📝 Catatan:** Dokumentasi ini dibuat berdasarkan analisis kode sumber aplikasi DeteksiDiabetes. Untuk informasi lebih detail tentang implementasi teknis, silakan merujuk ke kode sumber di masing-masing file yang disebutkan.

**🔄 Terakhir diperbarui:** 23 Juni 2025
