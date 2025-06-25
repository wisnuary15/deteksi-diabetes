import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_profile.dart';

class ChatPreferencesService {
  static const String _chatPrefsKey = 'chat_preferences';
  static const String _userContextKey = 'user_chat_context';
  static const String _lastSyncKey = 'last_profile_sync';

  /// Update chat preferences when user profile is created/updated
  static Future<bool> updateChatPreferencesFromProfile(
    UserProfile profile,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Build contextualized chat preferences
      final chatPreferences = _buildChatPreferencesFromProfile(profile);

      // Save preferences
      await prefs.setString(_chatPrefsKey, jsonEncode(chatPreferences));
      await prefs.setString(
        _userContextKey,
        jsonEncode(_buildUserContext(profile)),
      );
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());

      return true;
    } catch (e) {
      print('Error updating chat preferences: $e');
      return false;
    }
  }

  /// Get current chat preferences with user context
  static Future<Map<String, dynamic>?> getChatPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefsString = prefs.getString(_chatPrefsKey);

      if (prefsString != null) {
        return jsonDecode(prefsString) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting chat preferences: $e');
      return null;
    }
  }

  /// Get user context for chat personalization
  static Future<Map<String, dynamic>?> getUserChatContext() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final contextString = prefs.getString(_userContextKey);

      if (contextString != null) {
        return jsonDecode(contextString) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting user chat context: $e');
      return null;
    }
  }

  /// Check if profile data needs to be synced with chat preferences
  static Future<bool> needsProfileSync(UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSyncString = prefs.getString(_lastSyncKey);

      if (lastSyncString == null) return true;

      final lastSync = DateTime.parse(lastSyncString);
      return profile.updatedAt.isAfter(lastSync);
    } catch (e) {
      return true; // If error, force sync
    }
  }

  /// Generate personalized system prompt for chat AI
  static Future<String> getPersonalizedSystemPrompt() async {
    final context = await getUserChatContext();
    if (context == null) return _getDefaultSystemPrompt();

    return _buildPersonalizedPrompt(context);
  }

  /// Build chat preferences from user profile
  static Map<String, dynamic> _buildChatPreferencesFromProfile(
    UserProfile profile,
  ) {
    return {
      'user_name': profile.name,
      'age_group': _getAgeGroup(profile.age),
      'gender': profile.gender,
      'language': 'id', // Default Indonesian
      'communication_style': _getCommunicationStyle(profile),
      'health_focus_areas': _getHealthFocusAreas(profile),
      'risk_factors': _extractRiskFactors(profile),
      'preferred_tone': _getPreferredTone(profile),
      'medical_context': _getMedicalContext(profile),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Build user context for personalization
  static Map<String, dynamic> _buildUserContext(UserProfile profile) {
    return {
      'profile_id': profile.id,
      'name': profile.name,
      'age': profile.age,
      'gender': profile.gender,
      'bmi': profile.bmi,
      'bmi_category': profile.bmiCategory,
      'risk_level': profile.riskLevel ?? 'belum_dinilai',
      'has_family_history': profile.familyDiabetesHistory != null,
      'has_medical_history': profile.medicalHistory.isNotEmpty,
      'is_on_medication': profile.currentMedications.isNotEmpty,
      'has_allergies': profile.allergies.isNotEmpty,
      'last_detection': profile.lastDetectionResult,
      'personal_risk_score': _calculatePersonalRiskScore(profile),
      'focus_areas': _getHealthFocusAreas(profile),
    };
  }

  /// Get age group for appropriate communication
  static String _getAgeGroup(int age) {
    if (age < 25) return 'young_adult';
    if (age < 40) return 'adult';
    if (age < 60) return 'middle_aged';
    return 'senior';
  }

  /// Determine communication style based on profile
  static String _getCommunicationStyle(UserProfile profile) {
    // Young adults might prefer casual, seniors might prefer formal
    if (profile.age < 30) return 'friendly_casual';
    if (profile.age > 60) return 'respectful_formal';
    return 'professional_friendly';
  }

  /// Get health focus areas based on profile data
  static List<String> _getHealthFocusAreas(UserProfile profile) {
    List<String> focusAreas = ['diabetes_prevention'];

    if (profile.bmi != null) {
      if (profile.bmi! > 25) focusAreas.add('weight_management');
      if (profile.bmi! < 18.5) focusAreas.add('nutrition_improvement');
    }

    if (profile.familyDiabetesHistory != null) {
      focusAreas.add('genetic_risk_management');
    }

    if (profile.medicalHistory.any(
      (h) => h.toLowerCase().contains('hipertensi'),
    )) {
      focusAreas.add('hypertension_management');
    }

    if (profile.age > 45) {
      focusAreas.add('age_related_screening');
    }

    return focusAreas;
  }

  /// Extract risk factors from profile
  static List<String> _extractRiskFactors(UserProfile profile) {
    List<String> risks = [];

    if (profile.age > 45) risks.add('age_over_45');
    if (profile.bmi != null && profile.bmi! > 25) risks.add('overweight');
    if (profile.familyDiabetesHistory != null) risks.add('family_history');
    if (profile.medicalHistory.isNotEmpty) risks.add('medical_history');

    return risks;
  }

  /// Get preferred communication tone
  static String _getPreferredTone(UserProfile profile) {
    // Can be customized based on user preferences or profile analysis
    return 'empathetic_professional';
  }

  /// Get medical context summary
  static Map<String, dynamic> _getMedicalContext(UserProfile profile) {
    return {
      'has_conditions': profile.medicalHistory.isNotEmpty,
      'conditions': profile.medicalHistory,
      'medications': profile.currentMedications,
      'allergies': profile.allergies,
      'family_diabetes': profile.familyDiabetesHistory != null,
    };
  }

  /// Calculate personal risk score (0-100)
  static int _calculatePersonalRiskScore(UserProfile profile) {
    int score = 0;

    // Age factor
    if (profile.age > 45) score += 20;
    if (profile.age > 65) score += 10;

    // BMI factor
    if (profile.bmi != null) {
      if (profile.bmi! > 30)
        score += 25;
      else if (profile.bmi! > 25)
        score += 15;
    }

    // Family history
    if (profile.familyDiabetesHistory != null) score += 25;

    // Medical history
    if (profile.medicalHistory.isNotEmpty) score += 15;

    // Gender factor (slightly higher risk for males in some age groups)
    if (profile.gender == 'Laki-laki' && profile.age > 45) score += 5;

    return score.clamp(0, 100);
  }

  /// Build personalized prompt for AI
  static String _buildPersonalizedPrompt(Map<String, dynamic> context) {
    final name = context['name'] ?? 'Pengguna';
    final age = context['age'] ?? 0;
    final gender = context['gender'] ?? 'Tidak diketahui';
    final riskLevel = context['risk_level'] ?? 'belum_dinilai';
    final focusAreas = List<String>.from(context['focus_areas'] ?? []);

    return '''
KONTEKS PENGGUNA UNTUK DRAIKHI (Dokter AI Konsultan Diabetes):

INFORMASI PERSONAL:
- Nama: $name
- Usia: $age tahun
- Jenis Kelamin: $gender
- Status Risiko: $riskLevel
- Area Fokus Kesehatan: ${focusAreas.join(', ')}

PANDUAN PERSONALISASI:
1. Gunakan nama "$name" dalam percakapan untuk memberikan sentuhan personal
2. Sesuaikan bahasa dan pendekatan berdasarkan usia ($age tahun)
3. Berikan perhatian khusus pada area fokus: ${focusAreas.join(', ')}
4. Pertimbangkan tingkat risiko saat ini: $riskLevel

GAYA KOMUNIKASI:
- Gunakan bahasa yang sesuai dengan usia dan latar belakang
- Berikan penjelasan yang mudah dipahami
- Tunjukkan empati dan dukungan
- Fokus pada pencegahan dan edukasi diabetes
''';
  }

  /// Default system prompt when no profile available
  static String _getDefaultSystemPrompt() {
    return '''
Anda adalah DrAI, asisten AI konsultan diabetes untuk aplikasi DeteksiDiabetes.
Berikan saran yang ramah, profesional, dan mudah dipahami tentang diabetes dan kesehatan.
''';
  }

  /// Clear all chat preferences (for logout)
  static Future<bool> clearChatPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_chatPrefsKey);
      await prefs.remove(_userContextKey);
      await prefs.remove(_lastSyncKey);
      return true;
    } catch (e) {
      print('Error clearing chat preferences: $e');
      return false;
    }
  }
}
