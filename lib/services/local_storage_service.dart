import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

class LocalStorageService {
  LocalStorageService._();
  static final LocalStorageService instance = LocalStorageService._();

  static const _groupIdKey = 'groupId';
  static const _usernameKey = 'username';
  static const _controleurKey = 'controleurName';
  static const _tokenKey = 'token';

  Future<SharedPreferences> get _prefs async => await SharedPreferences.getInstance();

  // === 🧩 Group ID ===
  Future<void> saveGroupId(String groupId) async {
    final prefs = await _prefs;
    await prefs.setString(_groupIdKey, groupId);
    developer.log('[LocalStorageService] ✅ Saved groupId=$groupId');
  }

  Future<String?> getGroupId() async {
    final prefs = await _prefs;
    final id = prefs.getString(_groupIdKey);
    developer.log('[LocalStorageService] 🔍 Loaded groupId=$id');
    return id;
  }

  // === 👤 Username ===
  Future<void> saveUsername(String username) async {
    final prefs = await _prefs;
    await prefs.setString(_usernameKey, username);
  }

  Future<String?> getUsername() async {
    final prefs = await _prefs;
    return prefs.getString(_usernameKey);
  }

  // === 🪪 Token ===
  Future<void> saveToken(String token) async {
    final prefs = await _prefs;
    await prefs.setString(_tokenKey, token);
    developer.log('[LocalStorageService] 🔐 Saved token (length=${token.length})');
  }

  Future<String?> getToken() async {
    final prefs = await _prefs;
    final token = prefs.getString(_tokenKey);
    developer.log('[LocalStorageService] 🔍 Loaded token: ${token != null ? "exists" : "null"}');
    return token;
  }

  Future<void> clearToken() async {
    final prefs = await _prefs;
    await prefs.remove(_tokenKey);
    developer.log('[LocalStorageService] 🧽 Cleared token');
  }

  // === 🧹 Clear all ===
  Future<void> clearAll() async {
    final prefs = await _prefs;
    await prefs.clear();
    developer.log('[LocalStorageService] 🧹 Cleared all keys');
  }

  Future<void> clearGroupData() async {
    final prefs = await _prefs;
    await prefs.remove(_groupIdKey);
    await prefs.remove(_tokenKey);
    developer.log('[LocalStorageService] 🧽 Cleared group-related keys');
  }

  // === 🧑‍💼 Contrôleur ===
  Future<void> saveControleurName(String name) async {
    final prefs = await _prefs;
    await prefs.setString(_controleurKey, name);
  }

  Future<String?> getControleurName() async {
    final prefs = await _prefs;
    return prefs.getString(_controleurKey);
  }
}
