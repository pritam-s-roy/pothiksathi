import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyCurrentUser = 'pothiksathi_user';
  static const String _keyDriverProfile = 'pothiksathi_driver_profile';
  static const String _keyCachedTimetables = 'pothiksathi_cached_timetables';
  static const String _keyTimetableCachedAt = 'pothiksathi_timetable_cached_at';

  static Future<void> saveUser(Map<String, dynamic> userMap) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCurrentUser, jsonEncode(userMap));
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keyCurrentUser);
    if (data == null) return null;
    try {
      return jsonDecode(data) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveDriverProfile(Map<String, dynamic> profileMap) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDriverProfile, jsonEncode(profileMap));
  }

  static Future<Map<String, dynamic>?> getDriverProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keyDriverProfile);
    if (data == null) return null;
    try {
      return jsonDecode(data) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> cacheTimetables(List<Map<String, dynamic>> timetables) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCachedTimetables, jsonEncode(timetables));
    await prefs.setString(_keyTimetableCachedAt, DateTime.now().toIso8601String());
  }

  static Future<List<Map<String, dynamic>>?> getCachedTimetables() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keyCachedTimetables);
    if (data == null) return null;
    try {
      final List decoded = jsonDecode(data);
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return null;
    }
  }

  static Future<DateTime?> getTimetableCachedAt() async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString(_keyTimetableCachedAt);
    if (dateStr == null) return null;
    return DateTime.tryParse(dateStr);
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCurrentUser);
    await prefs.remove(_keyDriverProfile);
  }
}
