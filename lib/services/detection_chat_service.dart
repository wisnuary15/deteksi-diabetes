import '../models/detection_result.dart';
import '../models/user_profile.dart';
import '../models/chat_models.dart';
import 'chat_service.dart';

/// Service untuk mengintegrasikan hasil deteksi dengan chat AI
class DetectionChatService {
  final ChatService _chatService;

  DetectionChatService({ChatService? chatService})
    : _chatService = chatService ?? ChatService();

  /// Memulai konsultasi otomatis berdasarkan hasil deteksi
  Stream<StreamResponse> startConsultationWithResult({
    required DetectionResult detectionResult,
    UserProfile? userProfile,
    String? preferredLanguage = 'id',
  }) async* {
    final consultationMessage = _generateConsultationMessage(detectionResult);

    yield* _chatService.sendMessageStreamWithDetectionContext(
      consultationMessage,
      userProfile: userProfile,
      detectionResult: detectionResult,
      preferredLanguage: preferredLanguage,
    );
  }

  /// Mengirim pertanyaan dengan konteks hasil deteksi
  Stream<StreamResponse> askQuestionWithDetectionContext({
    required String question,
    required DetectionResult detectionResult,
    UserProfile? userProfile,
    String? preferredLanguage = 'id',
  }) async* {
    yield* _chatService.sendMessageStreamWithDetectionContext(
      question,
      userProfile: userProfile,
      detectionResult: detectionResult,
      preferredLanguage: preferredLanguage,
    );
  }

  /// Generate pesan konsultasi otomatis berdasarkan hasil deteksi
  String _generateConsultationMessage(DetectionResult detectionResult) {
    if (detectionResult.className == 'diabetes') {
      return _generateDiabetesConsultation(detectionResult);
    } else {
      return _generateNormalConsultation(detectionResult);
    }
  }

  String _generateDiabetesConsultation(DetectionResult detectionResult) {
    final confidence = (detectionResult.confidence * 100).toStringAsFixed(1);

    switch (detectionResult.riskLevel) {
      case 'TINGGI':
        return '''
DrAI, hasil deteksi menunjukkan INDIKASI DIABETES dengan tingkat kepercayaan $confidence%. 
Ini adalah tingkat risiko TINGGI. Mohon berikan:

1. Analisis mendalam tentang hasil deteksi ini
2. Penjelasan tanda-tanda pada lidah yang terdeteksi AI
3. Langkah-langkah URGENT yang harus saya lakukan segera
4. Pemeriksaan laboratorium apa yang harus dilakukan
5. Gejala diabetes yang perlu saya waspadai
6. Rekomendasi diet dan gaya hidup untuk kondisi ini

Saya ingin memahami hasil ini dengan baik dan tahu apa yang harus saya lakukan selanjutnya.
''';

      case 'SEDANG-TINGGI':
        return '''
DrAI, hasil deteksi menunjukkan INDIKASI DIABETES dengan tingkat kepercayaan $confidence%.
Ini adalah tingkat risiko SEDANG-TINGGI. Mohon bantu saya memahami:

1. Apa arti hasil deteksi ini?
2. Mengapa AI mendeteksi indikasi diabetes pada lidah saya?
3. Langkah-langkah apa yang perlu saya ambil?
4. Pemeriksaan lanjutan apa yang disarankan?
5. Bagaimana cara mencegah atau mengelola kondisi ini?

Terima kasih atas penjelasannya DrAI.
''';

      default:
        return '''
DrAI, hasil deteksi menunjukkan INDIKASI DIABETES dengan tingkat kepercayaan $confidence%.
Namun tingkat kepercayaan ini masih perlu konfirmasi. Mohon jelaskan:

1. Apa arti hasil deteksi ini?
2. Apakah saya perlu khawatir?
3. Langkah apa yang sebaiknya saya lakukan?
4. Pemeriksaan apa yang diperlukan untuk memastikan?

Saya ingin mendapat panduan yang tepat untuk kondisi saya.
''';
    }
  }

  String _generateNormalConsultation(DetectionResult detectionResult) {
    final confidence = (detectionResult.confidence * 100).toStringAsFixed(1);

    return '''
DrAI, hasil deteksi menunjukkan TIDAK ADA INDIKASI DIABETES dengan tingkat kepercayaan $confidence%.
Ini adalah kabar baik! Mohon berikan informasi:

1. Apa arti hasil deteksi ini?
2. Apakah lidah saya dalam kondisi normal?
3. Langkah-langkah pencegahan diabetes yang bisa saya lakukan
4. Kapan sebaiknya saya melakukan screening ulang?
5. Gaya hidup sehat apa yang perlu dipertahankan?
6. Tanda-tanda apa yang perlu saya waspadai di masa depan?

Terima kasih DrAI atas informasinya!
''';
  }

  /// Generate pesan follow-up berdasarkan riwayat deteksi
  String generateFollowUpMessage(List<DetectionResult> historyResults) {
    if (historyResults.isEmpty) {
      return 'DrAI, saya baru pertama kali menggunakan aplikasi ini. Bisakah dijelaskan bagaimana cara kerja deteksi diabetes melalui lidah?';
    }

    final latestResult = historyResults.first;
    final hasMultipleResults = historyResults.length > 1;

    if (hasMultipleResults) {
      return '''
DrAI, saya sudah melakukan ${historyResults.length} kali pemeriksaan. 
Hasil terakhir menunjukkan: ${latestResult.displayText} dengan kepercayaan ${latestResult.confidenceText}.

Bisakah Anda menganalisis perkembangan kondisi saya berdasarkan riwayat pemeriksaan? 
Apakah ada perubahan yang perlu saya perhatikan?
''';
    } else {
      return 'DrAI, bisakah Anda menjelaskan lebih detail tentang hasil deteksi saya dan memberikan saran untuk langkah selanjutnya?';
    }
  }

  /// Dispose service
  void dispose() {
    _chatService.dispose();
  }
}
