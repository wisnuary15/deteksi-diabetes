import 'package:shared_preferences/shared_preferences.dart';

class ProfileAnalyticsService {
  static const String _profileViewsKey = 'profile_views_count';
  static const String _imageUpdatesKey = 'profile_image_updates_count';
  static const String _lastViewedKey = 'profile_last_viewed';

  final SharedPreferences _prefs;

  ProfileAnalyticsService(this._prefs);

  // Track profile views
  Future<void> trackProfileView() async {
    final currentCount = _prefs.getInt(_profileViewsKey) ?? 0;
    await _prefs.setInt(_profileViewsKey, currentCount + 1);
    await _prefs.setString(_lastViewedKey, DateTime.now().toIso8601String());
  }

  // Track image updates
  Future<void> trackImageUpdate() async {
    final currentCount = _prefs.getInt(_imageUpdatesKey) ?? 0;
    await _prefs.setInt(_imageUpdatesKey, currentCount + 1);
  }

  // Get profile views count
  int get profileViewsCount => _prefs.getInt(_profileViewsKey) ?? 0;

  // Get image updates count
  int get imageUpdatesCount => _prefs.getInt(_imageUpdatesKey) ?? 0;

  // Get last viewed date
  DateTime? get lastViewed {
    final lastViewedString = _prefs.getString(_lastViewedKey);
    if (lastViewedString != null) {
      try {
        return DateTime.parse(lastViewedString);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Get usage statistics
  Map<String, dynamic> getUsageStats() {
    return {
      'profileViews': profileViewsCount,
      'imageUpdates': imageUpdatesCount,
      'lastViewed': lastViewed?.toIso8601String(),
      'isActiveUser': profileViewsCount > 5,
    };
  }

  // Reset all analytics (for testing or privacy)
  Future<void> resetAnalytics() async {
    await Future.wait([
      _prefs.remove(_profileViewsKey),
      _prefs.remove(_imageUpdatesKey),
      _prefs.remove(_lastViewedKey),
    ]);
  }
}
