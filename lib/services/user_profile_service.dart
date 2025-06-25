import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

class UserProfileService {
  static const String _userProfileKey = 'user_profile';
  static const String _profileSetupCompleteKey = 'profile_setup_complete';

  final SharedPreferences _prefs;

  UserProfileService(this._prefs);

  // Check if user profile exists
  bool get hasProfile => _prefs.containsKey(_userProfileKey);

  bool get isProfileSetupComplete =>
      _prefs.getBool(_profileSetupCompleteKey) ?? false;

  // ENHANCED: Get user profile with error recovery
  Future<UserProfile?> getUserProfile() async {
    try {
      final jsonString = _prefs.getString(_userProfileKey);
      if (jsonString == null) return null;

      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

      // VALIDATE: Check if JSON data is valid
      if (!_isValidProfileJson(jsonData)) {
        print('Invalid profile data detected, attempting recovery...');
        await _attemptProfileRecovery(jsonData);
        return null;
      }

      return UserProfile.fromJson(jsonData);
    } catch (e) {
      print('Error loading user profile: $e');

      // RECOVERY: Try to recover or clear corrupted data
      await _handleCorruptedProfile(e);
      return null;
    }
  }

  // ADD: Validate profile JSON structure
  bool _isValidProfileJson(Map<String, dynamic> json) {
    // Check for required fields
    if (!json.containsKey('id') || json['id'] == null) return false;
    if (!json.containsKey('name') || json['name'] == null) return false;
    if (!json.containsKey('age') || json['age'] == null) return false;
    if (!json.containsKey('gender') || json['gender'] == null) return false;

    return true;
  }

  // ADD: Attempt to recover corrupted profile data
  Future<void> _attemptProfileRecovery(
    Map<String, dynamic> corruptedJson,
  ) async {
    try {
      print('Attempting to recover profile data...');

      // Create a backup of corrupted data
      await _prefs.setString(
        '${_userProfileKey}_corrupted_${DateTime.now().millisecondsSinceEpoch}',
        jsonEncode(corruptedJson),
      ); // Try to create a minimal valid profile from corrupted data
      final recoveredProfile = UserProfile(
        id:
            corruptedJson['id']?.toString() ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        name: corruptedJson['name']?.toString() ?? 'User',
        age: _safeParseInt(corruptedJson['age']) ?? 25,
        gender: corruptedJson['gender']?.toString() ?? 'Tidak ditentukan',
        createdAt:
            _safeParseDateTime(corruptedJson['createdAt']) ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await saveUserProfile(recoveredProfile);
      print('Profile recovery successful');
    } catch (e) {
      print('Profile recovery failed: $e');
      await clearProfile();
    }
  }

  // ADD: Handle corrupted profile
  Future<void> _handleCorruptedProfile(dynamic error) async {
    print('Handling corrupted profile: $error');

    // Create backup of corrupted data
    final corruptedData = _prefs.getString(_userProfileKey);
    if (corruptedData != null) {
      await _prefs.setString(
        '${_userProfileKey}_backup_${DateTime.now().millisecondsSinceEpoch}',
        corruptedData,
      );
    }

    // Clear corrupted profile
    await clearProfile();

    // Set flag to show recovery dialog to user
    await _prefs.setBool('profile_recovery_needed', true);
  }

  // ADD: Check if profile recovery is needed
  bool get needsProfileRecovery =>
      _prefs.getBool('profile_recovery_needed') ?? false;

  // ADD: Mark profile recovery as complete
  Future<void> markProfileRecoveryComplete() async {
    await _prefs.remove('profile_recovery_needed');
  }

  // ADD: Get profile recovery info
  Future<Map<String, dynamic>> getProfileRecoveryInfo() async {
    final keys = _prefs
        .getKeys()
        .where(
          (key) =>
              key.startsWith('${_userProfileKey}_corrupted') ||
              key.startsWith('${_userProfileKey}_backup'),
        )
        .toList();

    return {
      'hasCorruptedBackup': keys.any((key) => key.contains('corrupted')),
      'hasRegularBackup': keys.any((key) => key.contains('backup')),
      'backupCount': keys.length,
      'backupKeys': keys,
    };
  }

  // Save user profile
  Future<bool> saveUserProfile(UserProfile profile) async {
    try {
      // VALIDATE: Check profile before saving
      final errors = validateProfile(profile);
      if (errors.isNotEmpty) {
        print('Profile validation errors: ${errors.join(', ')}');
        return false;
      }

      final jsonString = jsonEncode(profile.toJson());

      // VERIFY: Try to parse back to ensure JSON is valid
      try {
        final testParse = jsonDecode(jsonString);
        UserProfile.fromJson(testParse as Map<String, dynamic>);
      } catch (e) {
        print('Profile JSON validation failed: $e');
        return false;
      }

      await _prefs.setString(_userProfileKey, jsonString);
      await _prefs.setBool(_profileSetupCompleteKey, true);

      print('Profile saved successfully');
      return true;
    } catch (e) {
      print('Error saving user profile: $e');
      return false;
    }
  }

  // Update specific fields
  Future<bool> updateProfile({
    String? name,
    int? age,
    String? gender,
    double? weight,
    double? height,
    String? bloodType,
    List<String>? medicalHistory,
    List<String>? currentMedications,
    List<String>? allergies,
    String? familyDiabetesHistory,
  }) async {
    final currentProfile = await getUserProfile();
    if (currentProfile == null) return false;

    final updatedProfile = currentProfile.copyWith(
      name: name,
      age: age,
      gender: gender,
      weight: weight,
      height: height,
      bloodType: bloodType,
      medicalHistory: medicalHistory,
      currentMedications: currentMedications,
      allergies: allergies,
      familyDiabetesHistory: familyDiabetesHistory,
      updatedAt: DateTime.now(),
    );

    return await saveUserProfile(updatedProfile);
  }

  // FIXED: Unified method untuk update detection result dengan optional risk factors
  Future<bool> updateDetectionResult({
    required String result,
    required String riskLevel,
    List<String>? riskFactors,
  }) async {
    try {
      final currentProfile = await getUserProfile();
      if (currentProfile == null) {
        print('No user profile found to update');
        return false;
      }

      // Build risk factors string if provided
      final riskFactorsString = riskFactors?.isNotEmpty == true
          ? riskFactors!.join(', ')
          : '';

      final updatedProfile = currentProfile.copyWith(
        lastDetectionResult: result,
        riskLevel: riskLevel,
        // Use the correct parameter name as defined in the UserProfile class
        riskFactors: riskFactorsString.isNotEmpty ? riskFactorsString : null,
        lastDetectionDate: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final success = await saveUserProfile(updatedProfile);

      if (success) {
        print('Detection result updated successfully');
        print('Result: $result');
        print('Risk Level: $riskLevel');
        if (riskFactorsString.isNotEmpty) {
          print('Risk Factors: $riskFactorsString');
        }
      }

      return success;
    } catch (e) {
      print('Error updating detection result: $e');
      return false;
    }
  }

  // ADD: Method untuk mendapatkan risk factors sebagai list
  Future<List<String>> getRiskFactors() async {
    try {
      final profile = await getUserProfile();
      if (profile != null && profile.riskFactors?.isNotEmpty == true) {
        return profile.riskFactors!
            .split(',')
            .map((factor) => factor.trim())
            .where((factor) => factor.isNotEmpty)
            .toList();
      }
      return [];
    } catch (e) {
      print('Error getting risk factors: $e');
      return [];
    }
  }

  // ADD: Method untuk mendapatkan detection summary
  Future<Map<String, dynamic>> getDetectionSummary() async {
    try {
      final profile = await getUserProfile();
      if (profile == null) {
        return {'hasDetection': false};
      }

      final riskFactors = await getRiskFactors();

      return {
        'hasDetection': profile.lastDetectionResult != null,
        'result': profile.lastDetectionResult,
        'riskLevel': profile.riskLevel,
        'riskFactors': riskFactors,
        'detectionDate': profile.lastDetectionDate?.millisecondsSinceEpoch,
        'daysSinceDetection': profile.lastDetectionDate != null
            ? DateTime.now().difference(profile.lastDetectionDate!).inDays
            : null,
      };
    } catch (e) {
      print('Error getting detection summary: $e');
      return {'hasDetection': false, 'error': e.toString()};
    }
  }

  // ADD: Method untuk update health metrics
  Future<bool> updateHealthMetrics({
    double? weight,
    double? height,
    String? bloodPressure,
    String? bloodSugar,
    String? cholesterol,
  }) async {
    try {
      final currentProfile = await getUserProfile();
      if (currentProfile == null) return false;

      final updatedProfile = currentProfile.copyWith(
        weight: weight,
        height: height,
        // Note: You might need to add these fields to UserProfile model
        updatedAt: DateTime.now(),
      );

      return await saveUserProfile(updatedProfile);
    } catch (e) {
      print('Error updating health metrics: $e');
      return false;
    }
  }

  // ADD: Method untuk add medical history entry
  Future<bool> addMedicalHistoryEntry(String condition) async {
    try {
      final currentProfile = await getUserProfile();
      if (currentProfile == null) return false;

      final currentHistory = List<String>.from(currentProfile.medicalHistory);
      if (!currentHistory.contains(condition)) {
        currentHistory.add(condition);

        final updatedProfile = currentProfile.copyWith(
          medicalHistory: currentHistory,
          updatedAt: DateTime.now(),
        );

        return await saveUserProfile(updatedProfile);
      }

      return true; // Already exists
    } catch (e) {
      print('Error adding medical history: $e');
      return false;
    }
  }

  // ADD: Method untuk remove medical history entry
  Future<bool> removeMedicalHistoryEntry(String condition) async {
    try {
      final currentProfile = await getUserProfile();
      if (currentProfile == null) return false;

      final currentHistory = List<String>.from(currentProfile.medicalHistory);
      if (currentHistory.remove(condition)) {
        final updatedProfile = currentProfile.copyWith(
          medicalHistory: currentHistory,
          updatedAt: DateTime.now(),
        );

        return await saveUserProfile(updatedProfile);
      }

      return true; // Already removed or didn't exist
    } catch (e) {
      print('Error removing medical history: $e');
      return false;
    }
  }

  // ADD: Method untuk get health summary
  Future<Map<String, dynamic>> getHealthSummary() async {
    try {
      final profile = await getUserProfile();
      if (profile == null) {
        return {'hasProfile': false};
      }

      final detectionSummary = await getDetectionSummary();
      final bmi = profile.bmi;
      final bmiCategory = profile.bmiCategory;

      return {
        'hasProfile': true,
        'name': profile.name,
        'age': profile.age,
        'gender': profile.gender,
        'bmi': bmi,
        'bmiCategory': bmiCategory,
        'weight': profile.weight,
        'height': profile.height,
        'bloodType': profile.bloodType,
        'medicalHistory': profile.medicalHistory,
        'currentMedications': profile.currentMedications,
        'allergies': profile.allergies,
        'familyDiabetesHistory': profile.familyDiabetesHistory,
        'detection': detectionSummary,
        'profileCompleteness': _calculateProfileCompleteness(profile),
        'lastUpdated': profile.updatedAt.millisecondsSinceEpoch,
      };
    } catch (e) {
      print('Error getting health summary: $e');
      return {'hasProfile': false, 'error': e.toString()};
    }
  }

  // ADD: Calculate profile completeness percentage
  double _calculateProfileCompleteness(UserProfile profile) {
    int completedFields = 0;
    int totalFields = 11; // Total number of optional fields

    // Required fields (always completed)
    completedFields += 3; // name, age, gender

    // Optional fields
    if (profile.weight != null) completedFields++;
    if (profile.height != null) completedFields++;
    if (profile.bloodType?.isNotEmpty == true) completedFields++;
    if (profile.medicalHistory.isNotEmpty) completedFields++;
    if (profile.currentMedications.isNotEmpty) completedFields++;
    if (profile.allergies.isNotEmpty) completedFields++;
    if (profile.familyDiabetesHistory?.isNotEmpty == true) completedFields++;
    if (profile.lastDetectionResult?.isNotEmpty == true) completedFields++;

    return (completedFields / totalFields) * 100;
  }

  // ADD: Method untuk validate profile data
  List<String> validateProfile(UserProfile profile) {
    final errors = <String>[];

    if (profile.name.trim().isEmpty) {
      errors.add('Nama tidak boleh kosong');
    }

    if (profile.age < 1 || profile.age > 150) {
      errors.add('Usia harus antara 1-150 tahun');
    }

    if (profile.weight != null &&
        (profile.weight! < 1 || profile.weight! > 500)) {
      errors.add('Berat badan harus antara 1-500 kg');
    }

    if (profile.height != null &&
        (profile.height! < 50 || profile.height! > 300)) {
      errors.add('Tinggi badan harus antara 50-300 cm');
    }

    if (profile.gender.trim().isEmpty) {
      errors.add('Jenis kelamin harus dipilih');
    }

    return errors;
  }

  // ADD: Method untuk check if profile needs update
  bool shouldUpdateProfile(UserProfile profile) {
    final daysSinceUpdate = DateTime.now().difference(profile.updatedAt).inDays;

    // Suggest update if:
    // - Profile older than 30 days
    // - Profile completeness < 70%
    // - No detection result in last 90 days

    if (daysSinceUpdate > 30) return true;

    if (_calculateProfileCompleteness(profile) < 70) return true;

    if (profile.lastDetectionDate == null) return true;

    final daysSinceDetection = DateTime.now()
        .difference(profile.lastDetectionDate!)
        .inDays;

    if (daysSinceDetection > 90) return true;

    return false;
  }

  // Create default profile
  Future<UserProfile> createDefaultProfile(String name) async {
    final profile = UserProfile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      age: 25, // Default age
      gender: 'Tidak ditentukan',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await saveUserProfile(profile);
    return profile;
  }

  // Clear profile
  Future<void> clearProfile() async {
    await _prefs.remove(_userProfileKey);
    await _prefs.remove(_profileSetupCompleteKey);
  }

  // Export profile data
  Map<String, dynamic> exportProfile() {
    final jsonString = _prefs.getString(_userProfileKey);
    if (jsonString == null) return {};

    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  // Import profile data
  Future<bool> importProfile(Map<String, dynamic> profileData) async {
    try {
      final profile = UserProfile.fromJson(profileData);

      // Validate imported profile
      final errors = validateProfile(profile);
      if (errors.isNotEmpty) {
        print('Profile validation errors: ${errors.join(', ')}');
        return false;
      }

      return await saveUserProfile(profile);
    } catch (e) {
      print('Error importing profile: $e');
      return false;
    }
  }

  // ADD: Method untuk backup profile data with timestamp
  Map<String, dynamic> createProfileBackup() {
    final profileData = exportProfile();
    if (profileData.isEmpty) return {};

    return {
      'profile': profileData,
      'backupTimestamp': DateTime.now().millisecondsSinceEpoch,
      'version': '1.0.0',
      'appVersion': 'DeteksiDiabetes 1.0.0',
    };
  }

  // ADD: Method untuk restore from backup
  Future<bool> restoreFromBackup(Map<String, dynamic> backupData) async {
    try {
      if (!backupData.containsKey('profile')) {
        print('Invalid backup data: missing profile');
        return false;
      }

      final profileData = backupData['profile'] as Map<String, dynamic>;
      return await importProfile(profileData);
    } catch (e) {
      print('Error restoring from backup: $e');
      return false;
    }
  }

  // Helper methods for safe parsing
  int? _safeParseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value);
    }
    if (value is double) return value.round();
    return null;
  }

  DateTime? _safeParseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is int) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } catch (e) {
        return null;
      }
    }
    if (value is String) {
      // Try parsing as milliseconds first
      final intValue = int.tryParse(value);
      if (intValue != null) {
        try {
          return DateTime.fromMillisecondsSinceEpoch(intValue);
        } catch (e) {
          // Fall through to ISO string parsing
        }
      }
      // Try parsing as ISO string
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}
