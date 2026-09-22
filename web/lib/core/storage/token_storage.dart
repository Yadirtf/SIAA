// Almacenamiento de sesión y tokens para navegador web (SharedPreferences)
// T-PLT-01.8, T-AUT-01.5
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class WebTokenStorage {
  static const _keyAccessToken = 'siaa_web_access_token';
  static const _keyRefreshToken = 'siaa_web_refresh_token';
  static const _keyUser = 'siaa_web_user';

  static Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    Map<String, dynamic>? usuario,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccessToken, accessToken);
    await prefs.setString(_keyRefreshToken, refreshToken);
    if (usuario != null) {
      await prefs.setString(_keyUser, jsonEncode(usuario));
    }
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAccessToken);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRefreshToken);
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyUser);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyRefreshToken);
    await prefs.remove(_keyUser);
  }
}
