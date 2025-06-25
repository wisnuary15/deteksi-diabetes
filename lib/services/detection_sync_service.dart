import 'package:shared_preferences/shared_preferences.dart';
import '../models/detection_result.dart';
import '../models/user_profile.dart';
import '../services/history_service.dart';
import '../services/user_profile_service.dart';

/// Service untuk menyinkronkan data antara hasil deteksi dan profil user
class DetectionSyncService {
  /// Sinkronisasi hasil deteksi terbaru dengan profil user
  static Future<UserProfile?> syncLatestDetectionWithProfile() async {
    try {
      // Ambil profil user saat ini
      final prefs = await SharedPreferences.getInstance();
      final userProfileService = UserProfileService(prefs);
      UserProfile? currentProfile = await userProfileService.getUserProfile();

      // Ambil riwayat deteksi terbaru
      final history = await HistoryService.getHistory();

      if (history.isEmpty) {
        // Tidak ada riwayat deteksi
        return currentProfile;
      }

      // Ambil hasil deteksi terbaru
      final latestDetection = history.first;

      // Cek apakah profil perlu diupdate
      final needsUpdate =
          currentProfile == null ||
          currentProfile.lastDetectionResult != latestDetection.displayText ||
          currentProfile.riskLevel != latestDetection.riskLevel;

      if (needsUpdate) {
        print('🔄 Syncing latest detection result with user profile...');

        // Update profil dengan hasil deteksi terbaru
        await userProfileService.updateDetectionResult(
          result: latestDetection.displayText,
          riskLevel: latestDetection.riskLevel,
          riskFactors: [latestDetection.riskBasedRecommendation],
        );

        // Ambil profil yang sudah diupdate
        currentProfile = await userProfileService.getUserProfile();
        print('✅ Profile synced with latest detection result');
      }

      return currentProfile;
    } catch (e) {
      print('❌ Error syncing detection with profile: $e');
      return null;
    }
  }

  /// Ambil hasil deteksi terbaru untuk konteks chat
  static Future<DetectionResult?> getLatestDetectionForChat() async {
    try {
      final history = await HistoryService.getHistory();
      return history.isNotEmpty ? history.first : null;
    } catch (e) {
      print('❌ Error getting latest detection: $e');
      return null;
    }
  }

  /// Cek apakah user sudah pernah melakukan deteksi
  static Future<bool> hasUserPerformedDetection() async {
    try {
      final history = await HistoryService.getHistory();
      return history.isNotEmpty;
    } catch (e) {
      print('❌ Error checking detection history: $e');
      return false;
    }
  }

  /// Ambil statistik deteksi user
  static Future<Map<String, dynamic>> getDetectionStats() async {
    try {
      final history = await HistoryService.getHistory();

      if (history.isEmpty) {
        return {
          'totalDetections': 0,
          'latestResult': null,
          'riskTrend': 'No data',
          'hasDetection': false,
        };
      }

      final diabetesCount = history
          .where((r) => r.className == 'diabetes')
          .length;
      final nonDiabetesCount = history
          .where((r) => r.className == 'non_diabetes')
          .length;

      return {
        'totalDetections': history.length,
        'latestResult': history.first,
        'diabetesCount': diabetesCount,
        'nonDiabetesCount': nonDiabetesCount,
        'hasDetection': true,
        'lastDetectionDate': history.first.timestamp,
      };
    } catch (e) {
      print('❌ Error getting detection stats: $e');
      return {
        'totalDetections': 0,
        'latestResult': null,
        'riskTrend': 'Error',
        'hasDetection': false,
      };
    }
  }
}
