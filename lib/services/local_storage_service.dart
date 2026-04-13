import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

class LocalStorageService {
  LocalStorageService._();
  static final LocalStorageService instance = LocalStorageService._();

  static const _usernameKey = 'username';
  static const _controleurKey = 'controleurName';
  static const _tokenKey = 'token';

  Future<SharedPreferences> get _prefs async => await SharedPreferences.getInstance();

  Future<void> saveUsername(String username) async {
    final prefs = await _prefs;
    await prefs.setString(_usernameKey, username);
  }

  Future<String?> getUsername() async {
    final prefs = await _prefs;
    return prefs.getString(_usernameKey);
  }

  Future<void> saveToken(String token) async {
    final prefs = await _prefs;
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    final prefs = await _prefs;
    return prefs.getString(_tokenKey);
  }

  Future<void> clearAll() async {
    final prefs = await _prefs;
    await prefs.clear();
    developer.log('[LocalStorageService] 🧹 Cleared all keys');
  }

  Future<void> clearGroupData() async {
    final prefs = await _prefs;
    await prefs.remove(_tokenKey);
    developer.log('[LocalStorageService] 🧽 Cleared group-related keys');
  }

  Future<void> saveControllerName(String name) async {
    final prefs = await _prefs;
    await prefs.setString(_controleurKey, name);
  }

  Future<String?> getControllerName() async {
    final prefs = await _prefs;
    return prefs.getString(_controleurKey);
  }
}
