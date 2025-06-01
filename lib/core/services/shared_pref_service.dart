import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefService {
  static const String key = 'user';

  // Store user
  static Future<void> storeUser(String key, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(data));
    } catch (e) {
      //
    }
  }

  // Retrieve user
  static Future<Map<String, dynamic>?> getUser([String? cKey]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // final prefs = await SharedPreferences.getInstance();
      final String? userJson = prefs.getString(cKey ?? key);
      if (userJson != null) {
        return jsonDecode(userJson);
      }
    } catch (e) {
      //
    }
    return null;
  }

  // Update user
  static Future<void> updateUser(String key, Map<String, dynamic> data) async {
    try {
      await storeUser(key, data);
    } catch (e) {
      //
    }
  }

  // Delete user
  static Future<void> deleteUser([String? cKey]) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove(cKey ?? key);
    } catch (e) {
      //
    }
  }

  static Future<void> storeJsonArray(String key, List<dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(data));
  }

  static Future<List<dynamic>?> getJsonArray(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(key);
    if (jsonString != null) {
      return jsonDecode(jsonString);
    }
    return null;
  }
}
