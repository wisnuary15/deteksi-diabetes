import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_models.dart';
import '../models/user_profile.dart';
import '../models/detection_result.dart';
import 'detection_sync_service.dart';
import 'chat_preferences_service.dart';

class ChatService {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/';
  static const String _apiKey = 'ganti dengan API mu sendiri, cari di google ai studio';

  final http.Client _httpClient;

  ChatService({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();
  // ADD: Method with user context
  Future<Result<String>> sendMessageWithContext(
    String message, {
    UserProfile? userProfile,
    String? preferredLanguage = 'id',
  }) async {
    try {
      if (_apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
        return Result.failure(
          Exception('API Key belum dikonfigurasi untuk DeteksiDiabetes'),
        );
      }

      // Get personalized system prompt from ChatPreferencesService
      String contextualPrompt;
      try {
        final personalizedPrompt =
            await ChatPreferencesService.getPersonalizedSystemPrompt();
        contextualPrompt = _buildEnhancedDiabetesPrompt(
          message,
          personalizedSystemPrompt: personalizedPrompt,
          userProfile: userProfile,
          preferredLanguage: preferredLanguage,
        );
      } catch (e) {
        // Fallback to standard prompt if personalized fails
        print('Using fallback prompt, personalized prompt failed: $e');
        contextualPrompt = _buildPersonalizedDiabetesPrompt(
          message,
          userProfile: userProfile,
          preferredLanguage: preferredLanguage,
        );
      }

      final request = ChatRequest(
        contents: [
          ContentRequest(parts: [PartRequest(text: contextualPrompt)]),
        ],
      );

      final response = await _httpClient
          .post(
            Uri.parse(
              '${_baseUrl}v1beta/models/gemini-1.5-flash-latest:generateContent?key=$_apiKey',
            ),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(request.toJson()),
          )
          .timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final chatResponse = ChatResponse.fromJson(jsonDecode(response.body));
        final aiMessage = chatResponse.candidates.isNotEmpty
            ? chatResponse.candidates.first.content.parts.isNotEmpty
                  ? chatResponse.candidates.first.content.parts.first.text
                  : null
            : null;

        if (aiMessage != null && aiMessage.isNotEmpty) {
          return Result.success(aiMessage);
        } else {
          return Result.failure(
            Exception('Respons kosong dari AI Diabetes. Coba lagi.'),
          );
        }
      } else {
        final errorMessage = _getErrorMessage(response.statusCode);
        return Result.failure(Exception(errorMessage));
      }
    } catch (e) {
      return Result.failure(
        Exception('Gagal berkonsultasi dengan AI Diabetes: $e'),
      );
    }
  }

  // Legacy method for backward compatibility
  Future<Result<String>> sendMessage(String message) async {
    return sendMessageWithContext(message);
  }

  // ADD: Smart method that auto-syncs with latest detection
  Future<Result<String>> sendMessageWithAutoSync(
    String message, {
    UserProfile? userProfile,
    String? preferredLanguage = 'id',
  }) async {
    try {
      // Auto-sync user profile with latest detection
      final syncedProfile =
          await DetectionSyncService.syncLatestDetectionWithProfile();
      final latestDetection =
          await DetectionSyncService.getLatestDetectionForChat();

      // Use synced profile if available, otherwise fallback to provided profile
      final profileToUse = syncedProfile ?? userProfile;

      return await sendMessageWithDetectionContext(
        message,
        userProfile: profileToUse,
        detectionResult: latestDetection,
        preferredLanguage: preferredLanguage,
      );
    } catch (e) {
      return Result.failure(
        Exception(
          'Gagal menyinkronkan dan berkonsultasi dengan AI Diabetes: $e',
        ),
      );
    }
  }

  // ADD: Stream method that auto-syncs with latest detection
  Stream<StreamResponse> sendMessageStreamWithAutoSync(
    String message, {
    UserProfile? userProfile,
    String? preferredLanguage = 'id',
  }) async* {
    try {
      yield StreamStarted();

      // Auto-sync user profile with latest detection
      final syncedProfile =
          await DetectionSyncService.syncLatestDetectionWithProfile();
      final latestDetection =
          await DetectionSyncService.getLatestDetectionForChat();

      // Use synced profile if available, otherwise fallback to provided profile
      final profileToUse = syncedProfile ?? userProfile;

      // Stream with detection context
      yield* sendMessageStreamWithDetectionContext(
        message,
        userProfile: profileToUse,
        detectionResult: latestDetection,
        preferredLanguage: preferredLanguage,
      );
    } catch (e) {
      yield StreamError(
        'Gagal menyinkronkan dan berkonsultasi dengan AI Diabetes: $e',
      );
    }
  }

  // ADD: Stream method with user context
  Stream<StreamResponse> sendMessageStreamWithContext(
    String message, {
    UserProfile? userProfile,
    String? preferredLanguage = 'id',
  }) async* {
    try {
      if (_apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
        yield StreamError('API Key belum dikonfigurasi untuk DeteksiDiabetes');
        return;
      }

      yield StreamStarted();

      final contextualPrompt = _buildPersonalizedDiabetesPrompt(
        message,
        userProfile: userProfile,
        preferredLanguage: preferredLanguage,
      );

      final request = ChatRequest(
        contents: [
          ContentRequest(parts: [PartRequest(text: contextualPrompt)]),
        ],
      );

      final response = await _httpClient
          .post(
            Uri.parse(
              '${_baseUrl}v1beta/models/gemini-1.5-flash-latest:generateContent?key=$_apiKey',
            ),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(request.toJson()),
          )
          .timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final chatResponse = ChatResponse.fromJson(jsonDecode(response.body));
        final aiMessage = chatResponse.candidates.isNotEmpty
            ? chatResponse.candidates.first.content.parts.isNotEmpty
                  ? chatResponse.candidates.first.content.parts.first.text
                  : null
            : null;
        if (aiMessage != null && aiMessage.isNotEmpty) {
          yield StreamStarted();

          // ENHANCED: Professional streaming like ChatGPT/Claude
          const int wordsPerChunk = 3; // Group words for smoother flow
          final words = aiMessage.split(' ');
          String accumulatedText = '';

          for (int i = 0; i < words.length; i += wordsPerChunk) {
            // Take a chunk of words
            final endIndex = (i + wordsPerChunk < words.length)
                ? i + wordsPerChunk
                : words.length;
            final chunk = words.sublist(i, endIndex);

            // Add space before if not first chunk
            if (i > 0) accumulatedText += ' ';
            accumulatedText += chunk.join(' ');

            yield StreamChunk(accumulatedText);

            // ENHANCED: Dynamic delay based on content and chunk position
            int delayTime = _calculateOptimalDelay(chunk, i, words.length);

            await Future.delayed(Duration(milliseconds: delayTime));
          }

          yield StreamComplete(aiMessage);
        } else {
          yield StreamError('Respons kosong dari AI Diabetes');
        }
      } else {
        yield StreamError(_getErrorMessage(response.statusCode));
      }
    } catch (e) {
      yield StreamError('Gagal berkonsultasi dengan AI Diabetes: $e');
    }
  }

  // Legacy method for backward compatibility
  Stream<StreamResponse> sendMessageStream(String message) async* {
    yield* sendMessageStreamWithContext(message);
  }

  // ADD: Method with detection result context
  Future<Result<String>> sendMessageWithDetectionContext(
    String message, {
    UserProfile? userProfile,
    DetectionResult? detectionResult,
    String? preferredLanguage = 'id',
  }) async {
    try {
      if (_apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
        return Result.failure(
          Exception('API Key belum dikonfigurasi untuk DeteksiDiabetes'),
        );
      }

      final contextualPrompt = _buildPersonalizedDiabetesPrompt(
        message,
        userProfile: userProfile,
        detectionResult: detectionResult,
        preferredLanguage: preferredLanguage,
      );

      final request = ChatRequest(
        contents: [
          ContentRequest(parts: [PartRequest(text: contextualPrompt)]),
        ],
      );

      final response = await _httpClient
          .post(
            Uri.parse(
              '${_baseUrl}v1beta/models/gemini-1.5-flash-latest:generateContent?key=$_apiKey',
            ),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(request.toJson()),
          )
          .timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final chatResponse = ChatResponse.fromJson(jsonDecode(response.body));
        final aiMessage = chatResponse.candidates.isNotEmpty
            ? chatResponse.candidates.first.content.parts.isNotEmpty
                  ? chatResponse.candidates.first.content.parts.first.text
                  : null
            : null;

        if (aiMessage != null && aiMessage.isNotEmpty) {
          return Result.success(aiMessage);
        } else {
          return Result.failure(
            Exception('Respons kosong dari AI Diabetes. Coba lagi.'),
          );
        }
      } else {
        final errorMessage = _getErrorMessage(response.statusCode);
        return Result.failure(Exception(errorMessage));
      }
    } catch (e) {
      return Result.failure(
        Exception('Gagal berkonsultasi dengan AI Diabetes: $e'),
      );
    }
  }

  // ADD: Stream method with detection result context
  Stream<StreamResponse> sendMessageStreamWithDetectionContext(
    String message, {
    UserProfile? userProfile,
    DetectionResult? detectionResult,
    String? preferredLanguage = 'id',
  }) async* {
    try {
      if (_apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
        yield StreamError('API Key belum dikonfigurasi untuk DeteksiDiabetes');
        return;
      }

      yield StreamStarted();

      final contextualPrompt = _buildPersonalizedDiabetesPrompt(
        message,
        userProfile: userProfile,
        detectionResult: detectionResult,
        preferredLanguage: preferredLanguage,
      );

      final request = ChatRequest(
        contents: [
          ContentRequest(parts: [PartRequest(text: contextualPrompt)]),
        ],
      );

      final response = await _httpClient
          .post(
            Uri.parse(
              '${_baseUrl}v1beta/models/gemini-1.5-flash-latest:generateContent?key=$_apiKey',
            ),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(request.toJson()),
          )
          .timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final chatResponse = ChatResponse.fromJson(jsonDecode(response.body));
        final aiMessage = chatResponse.candidates.isNotEmpty
            ? chatResponse.candidates.first.content.parts.isNotEmpty
                  ? chatResponse.candidates.first.content.parts.first.text
                  : null
            : null;
        if (aiMessage != null && aiMessage.isNotEmpty) {
          // ENHANCED: Professional streaming menggunakan kata per kata
          final words = aiMessage.split(' ');
          String accumulatedText = '';

          for (int i = 0; i < words.length; i++) {
            if (i > 0) accumulatedText += ' ';
            accumulatedText += words[i];

            yield StreamChunk(accumulatedText);

            // Dynamic delay untuk typing effect yang natural
            await Future.delayed(
              Duration(milliseconds: 50 + (words[i].length * 10)),
            );
          }

          yield StreamComplete(aiMessage);
        } else {
          yield StreamError('Respons kosong dari AI Diabetes');
        }
      } else {
        yield StreamError(_getErrorMessage(response.statusCode));
      }
    } catch (e) {
      yield StreamError('Gagal berkonsultasi dengan AI Diabetes: $e');
    }
  }

  // ADD: New personalized prompt with user context
  String _buildPersonalizedDiabetesPrompt(
    String userMessage, {
    UserProfile? userProfile,
    DetectionResult? detectionResult,
    String? preferredLanguage = 'id',
  }) {
    final userContext = _buildUserContextString(userProfile);
    final languageInstruction = _getLanguageInstruction(
      preferredLanguage ?? 'id',
    );
    final detectionContext = _buildDetectionContextString(detectionResult);
    return '''
Anda adalah DrAI, asisten AI konsultan diabetes untuk aplikasi DeteksiDiabetes.

IDENTITAS:
- Nama: DrAI (Doctor AI untuk Diabetes)
- Role: Konsultan diabetes dan interpretasi hasil screening
- Fokus: Memberikan saran berdasarkan analisis foto lidah

${userContext}

${detectionContext}

PANDUAN RESPONS:
• Berikan 1 respons komprehensif tanpa pengulangan
• Gunakan bahasa yang jelas dan empati
• Maksimal 200 kata untuk menghindari informasi berlebihan
• Fokus pada informasi yang relevan dengan pertanyaan user
• Sebutkan nama user jika tersedia untuk personalisasi
   **RENDAH (0-30%)**:
   - Lidah normal, warna pink sehat
   - Tidak ada coating berlebihan
   - Tekstur normal, tidak kering
   - Papila taste bud normal
   - *Tindakan*: Pertahankan gaya hidup sehat, screening rutin
   
   **SEDANG (31-70%)**:
   - Slight coating pada lidah
   - Warna agak pucat atau kemerahan ringan
   - Tekstur sedikit kering
   - Beberapa indikator minor
   - *Tindakan*: Lifestyle modification, monitoring gula darah, konsultasi dokter
   
   **TINGGI (71-100%)**:
   - Coating tebal pada lidah
   - Perubahan warna signifikan (putih tebal/merah)
   - Tekstur sangat kering atau licin
   - Multiple indicators diabetes
   - *Tindakan*: ***SEGERA konsultasi dokter***, pemeriksaan gula darah, HbA1c

FORMAT RESPONS YANG BENAR:
- Gunakan **text** untuk membuat text tebal (bold)
- Gunakan *text* untuk membuat text miring (italic)  
- Gunakan ***text*** untuk bold + italic pada poin sangat penting
- Gunakan bullet points dengan - atau • untuk list
- Gunakan angka 1. 2. 3. untuk numbered list
- Pisahkan paragraf dengan line break

${languageInstruction}

KOMUNIKASI GUIDELINES:
✅ Gunakan bahasa yang ramah dan empati
✅ Berikan harapan dan motivasi untuk hidup sehat dengan diabetes
✅ Jelaskan medical terms dengan analogi sederhana
✅ Struktur jawaban: Direct answer + Medical context + Practical tips + Medical consultation reminder
✅ Gunakan emoji secukupnya untuk friendliness
✅ PERSONALISASI respons berdasarkan profil user (usia, gender, riwayat kesehatan)

SAFETY PROTOCOLS:
❌ JANGAN berikan dosis obat atau rekomendasi obat spesifik
❌ JANGAN diagnosis pasti diabetes (only risk assessment)
❌ JANGAN create unnecessary panic tapi juga jangan meremehkan
✅ SELALU remind untuk konsultasi dokter untuk hasil risiko TINGGI
✅ SELALU emphasize screening vs diagnostic difference
✅ BERIKAN emergency signs yang require immediate medical attention

PERTANYAAN PENGGUNA: ${userMessage}

Berikan respons sebagai DrAI yang kompeten, empati, dan fokus pada diabetes dengan format yang benar. Gunakan informasi profil user untuk memberikan saran yang lebih personal dan relevan:
''';
  } // ADD: Enhanced personalized prompt with ChatPreferencesService integration

  String _buildEnhancedDiabetesPrompt(
    String userMessage, {
    String? personalizedSystemPrompt,
    UserProfile? userProfile,
    DetectionResult? detectionResult,
    String? preferredLanguage = 'id',
  }) {
    // If we have a personalized system prompt, use it as the base
    if (personalizedSystemPrompt != null &&
        personalizedSystemPrompt.isNotEmpty) {
      final userContext = _buildUserContextString(userProfile);
      final languageInstruction = _getLanguageInstruction(
        preferredLanguage ?? 'id',
      );
      final detectionContext = _buildDetectionContextString(detectionResult);

      return '''
$personalizedSystemPrompt

${userContext}

${detectionContext}

PANDUAN RESPONS LANJUTAN:
• Berikan 1 respons komprehensif tanpa pengulangan
• Gunakan bahasa yang jelas dan empati
• Maksimal 200 kata untuk menghindari informasi berlebihan
• Fokus pada informasi yang relevan dengan pertanyaan user
• Sebutkan nama user jika tersedia untuk personalisasi

INTERPRETASI RISIKO BERDASARKAN DETEKSI LIDAH:
   **RENDAH (0-30%)**:
   - Lidah normal, warna pink sehat
   - Tidak ada coating berlebihan
   - Tekstur normal, tidak kering
   - *Tindakan*: Pertahankan gaya hidup sehat, screening rutin
   
   **SEDANG (31-70%)**:
   - Slight coating pada lidah
   - Warna agak pucat atau kemerahan ringan
   - Tekstur sedikit kering
   - *Tindakan*: Lifestyle modification, monitoring gula darah, konsultasi dokter
   
   **TINGGI (71-100%)**:
   - Coating tebal pada lidah
   - Perubahan warna signifikan (putih tebal/merah)
   - Tekstur sangat kering atau licin
   - *Tindakan*: ***SEGERA konsultasi dokter***, pemeriksaan gula darah, HbA1c

${languageInstruction}

SAFETY PROTOCOLS:
❌ JANGAN berikan dosis obat atau rekomendasi obat spesifik
❌ JANGAN diagnosis pasti diabetes (only risk assessment)
✅ SELALU remind untuk konsultasi dokter untuk hasil risiko TINGGI
✅ SELALU emphasize screening vs diagnostic difference

PERTANYAAN PENGGUNA: ${userMessage}

Berikan respons sebagai DrAI yang kompeten, empati, dan fokus pada diabetes dengan format yang benar:
''';
    }

    // Fallback to standard personalized prompt
    return _buildPersonalizedDiabetesPrompt(
      userMessage,
      userProfile: userProfile,
      detectionResult: detectionResult,
      preferredLanguage: preferredLanguage,
    );
  }

  // ...existing code...
  String _buildUserContextString(UserProfile? userProfile) {
    if (userProfile == null) {
      return '''
PROFIL PENGGUNA: 
- Status: User belum melengkapi profil
- Rekomendasi: Berikan saran umum untuk screening diabetes
''';
    }

    final bmiInfo = userProfile.bmi != null
        ? 'BMI: ${userProfile.bmi!.toStringAsFixed(1)} (${userProfile.bmiCategory})'
        : 'BMI: Tidak tersedia';

    final riskFactors = _calculatePersonalRiskFactors(userProfile);

    return '''
PROFIL PENGGUNA:
- Nama: ${userProfile.name}
- Usia: ${userProfile.age} tahun
- Jenis Kelamin: ${userProfile.gender}
- ${bmiInfo}
- Golongan Darah: ${userProfile.bloodType ?? 'Tidak diketahui'}
- Riwayat Penyakit: ${userProfile.medicalHistory.isEmpty ? 'Tidak ada' : userProfile.medicalHistory.join(', ')}
- Obat Saat Ini: ${userProfile.currentMedications.isEmpty ? 'Tidak ada' : userProfile.currentMedications.join(', ')}
- Alergi: ${userProfile.allergies.isEmpty ? 'Tidak ada' : userProfile.allergies.join(', ')}
- Riwayat Diabetes Keluarga: ${userProfile.familyDiabetesHistory ?? 'Tidak ada'}
- Hasil Deteksi Terakhir: ${userProfile.lastDetectionResult ?? 'Belum ada'}
- Tingkat Risiko Saat Ini: ${userProfile.riskLevel ?? 'Belum dinilai'}

FAKTOR RISIKO PERSONAL: ${riskFactors}

INSTRUKSI PERSONALISASI:
- Sebutkan nama user (${userProfile.name}) untuk membuat percakapan lebih personal
- Berikan saran berdasarkan usia dan gender
- Pertimbangkan BMI dalam rekomendasi diet/olahraga
- Sesuaikan advice dengan riwayat kesehatan yang ada
- Jika ada family history diabetes, berikan perhatian khusus
- PENTING: Cek status "Hasil Deteksi Terakhir" dan "Tingkat Risiko":
  * Jika "Belum ada" atau "Belum dinilai" = Arahkan untuk melakukan deteksi foto lidah
  * Jika sudah ada hasil = Reference hasil tersebut dan berikan analisis lanjutan
- Berikan respons yang konsisten dengan status deteksi user saat ini
''';
  }

  // ADD: Calculate personal risk factors
  String _calculatePersonalRiskFactors(UserProfile userProfile) {
    List<String> risks = [];

    // Age risk
    if (userProfile.age >= 45) {
      risks.add('Usia ≥45 tahun (risiko meningkat)');
    }

    // BMI risk
    if (userProfile.bmi != null) {
      if (userProfile.bmi! >= 25) {
        risks.add(
          'BMI ${userProfile.bmi!.toStringAsFixed(1)} (overweight/obesitas)',
        );
      }
    }

    // Family history
    if (userProfile.familyDiabetesHistory?.isNotEmpty == true) {
      risks.add('Riwayat diabetes dalam keluarga');
    }

    // Medical history
    for (final condition in userProfile.medicalHistory) {
      final lowerCondition = condition.toLowerCase();
      if (lowerCondition.contains('hipertensi') ||
          lowerCondition.contains('tekanan darah tinggi')) {
        risks.add('Hipertensi (comorbid dengan diabetes)');
      }
      if (lowerCondition.contains('kolesterol')) {
        risks.add('Kolesterol tinggi (sindrom metabolik)');
      }
      if (lowerCondition.contains('pcos') ||
          lowerCondition.contains('polycystic')) {
        risks.add('PCOS (insulin resistance)');
      }
    }

    // Detection history
    if (userProfile.lastDetectionResult?.toLowerCase().contains('tinggi') ==
        true) {
      risks.add('Hasil deteksi lidah menunjukkan risiko TINGGI');
    } else if (userProfile.lastDetectionResult?.toLowerCase().contains(
          'sedang',
        ) ==
        true) {
      risks.add('Hasil deteksi lidah menunjukkan risiko SEDANG');
    }

    return risks.isEmpty
        ? 'Tidak ada faktor risiko mayor yang teridentifikasi'
        : risks.join(', ');
  }

  // ADD: Get language instruction
  String _getLanguageInstruction(String language) {
    switch (language) {
      case 'en':
        return '''
LANGUAGE INSTRUCTION:
- Respond in English
- Use medical terminology appropriate for general audience
- Maintain professional yet friendly tone
''';
      case 'jv':
        return '''
LANGUAGE INSTRUCTION:
- Gunakan Bahasa Jawa (Ngoko/Krama sesuai konteks)
- Jelaskan istilah medis dengan bahasa yang mudah dipahami
- Pertahankan nuansa sopan dan ramah
''';
      case 'id':
      default:
        return '''
LANGUAGE INSTRUCTION:
- Gunakan Bahasa Indonesia yang baik dan benar
- Jelaskan istilah medis dengan bahasa awam
- Pertahankan tone yang profesional namun ramah
''';
    }
  }

  // ADD: Build detection context string
  String _buildDetectionContextString(DetectionResult? detectionResult) {
    if (detectionResult == null) {
      return '''
HASIL DETEKSI TERBARU: 
- Status: Sedang menganalisis hasil deteksi terbaru user
- Instruksi: Cek riwayat deteksi user dan berikan respons yang sesuai
- Jika user sudah pernah melakukan deteksi, reference hasil terakhir
- Jika belum pernah deteksi, arahkan untuk melakukan pemeriksaan foto lidah
''';
    }

    return '''
HASIL DETEKSI AI TERBARU:
${detectionResult.aiDescription}

KONTEKS MEDIS:
${detectionResult.medicalContext}

REKOMENDASI BERDASARKAN RISIKO:
${detectionResult.riskBasedRecommendation}

INSTRUKSI INTERPRETASI:
- Berikan analisis mendalam tentang hasil deteksi ini
- Jelaskan korelasi antara hasil AI dengan gejala diabetes pada lidah
- Berikan panduan follow-up yang tepat berdasarkan tingkat risiko
- Jika user bertanya tentang hasil, reference hasil deteksi ini secara spesifik
- Berikan konteks edukasi yang sesuai dengan tingkat risiko yang terdeteksi
''';
  }

  String _getErrorMessage(int statusCode) {
    switch (statusCode) {
      case 401:
        return 'API Key tidak valid untuk layanan diabetes';
      case 429:
        return 'Terlalu banyak permintaan. Tunggu sebentar.';
      case 500:
        return 'Server AI diabetes sedang bermasalah. Coba lagi nanti.';
      default:
        return 'Error API Diabetes: Status $statusCode';
    }
  }

  void dispose() {
    _httpClient.close();
  }
}

// Result class untuk error handling
class Result<T> {
  final T? _value;
  final Exception? _error;

  Result._(this._value, this._error);

  static Result<T> success<T>(T value) => Result._(value, null);
  static Result<T> failure<T>(Exception error) => Result._(null, error);

  bool get isSuccess => _error == null;
  bool get isFailure => _error != null;

  T get value {
    if (_error != null) throw _error;
    return _value!;
  }

  Exception get error {
    if (_error == null) throw StateError('No error');
    return _error;
  }

  R fold<R>(
    R Function(T value) onSuccess,
    R Function(Exception error) onError,
  ) {
    return _error == null ? onSuccess(_value!) : onError(_error);
  }
}

// ENHANCED: Professional delay calculation like ChatGPT/Claude
int _calculateOptimalDelay(
  List<String> chunk,
  int currentIndex,
  int totalWords,
) {
  // Base delay for professional streaming feel
  int baseDelay = 40; // Faster than before but still readable

  // Adjust based on chunk content
  final chunkText = chunk.join(' ');

  // Slower for medical terms to ensure readability
  if (chunkText.toLowerCase().contains(
    RegExp(r'diabetes|gula|darah|medis|kesehatan'),
  )) {
    baseDelay += 20;
  }

  // Faster for common words and connectors
  if (chunkText.toLowerCase().contains(
    RegExp(r'dan|atau|yang|untuk|dengan|pada|dari|ke|di|adalah'),
  )) {
    baseDelay -= 10;
  }

  // Add pause for punctuation in the chunk
  if (chunkText.contains(RegExp(r'[.!?]'))) {
    baseDelay += 60; // Sentence ending pause
  } else if (chunkText.contains(RegExp(r'[,;:]'))) {
    baseDelay += 30; // Clause pause
  }

  // Progressive speed up - start slower, get faster
  final progressRatio = currentIndex / totalWords;
  if (progressRatio < 0.1) {
    baseDelay += 20; // Slower start for impact
  } else if (progressRatio > 0.8) {
    baseDelay -= 10; // Faster ending
  }
  // Ensure minimum readable speed
  return baseDelay.clamp(25, 120);
}
