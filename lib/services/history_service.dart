import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/detection_result.dart';

class HistoryService {
  static const String _historyKey = 'detection_history';

  static Future<void> saveResult(DetectionResult result) async {
    final prefs = await SharedPreferences.getInstance();

    List<String> history = prefs.getStringList(_historyKey) ?? [];

    // Tambah hasil baru ke awal list
    history.insert(0, jsonEncode(result.toJson()));

    // Batasi maksimal 50 riwayat
    if (history.length > 50) {
      history = history.take(50).toList();
    }

    await prefs.setStringList(_historyKey, history);
  }

  static Future<List<DetectionResult>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();

    List<String> history = prefs.getStringList(_historyKey) ?? [];

    return history.map((item) {
      Map<String, dynamic> json = jsonDecode(item);
      return DetectionResult.fromJson(json);
    }).toList();
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }
}
