import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

class LocalStorageService {
  LocalStorageService._();
  static final LocalStorageService instance = LocalStorageService._();

  static const _usernameKey = 'username';
  static const _groupIdKey = 'groupId';
  static const _controleurKey = 'controleurName';
  static const _tokenKey = 'token';
  static const _installationIdKey = 'installationId';
  static const _termsAcceptedPrefix = 'termsAccepted';

  Future<SharedPreferences> get _prefs async =>
      await SharedPreferences.getInstance();

  Future<void> saveUsername(String username) async {
    final prefs = await _prefs;
    await prefs.setString(_usernameKey, username);
  }

  Future<void> saveGroupId(String groupId) async {
    final prefs = await _prefs;
    await prefs.setString(_groupIdKey, groupId);
  }

  Future<String?> getGroupId() async {
    final prefs = await _prefs;
    return prefs.getString(_groupIdKey);
  }

  Future<String?> getUsername() async {
    final prefs = await _prefs;
    return prefs.getString(_usernameKey);
  }

  Future<void> saveToken(String token) async {
    final prefs = await _prefs;
    await prefs.setString(_tokenKey, token);
  }

  Future<String> getOrCreateInstallationId() async {
    final prefs = await _prefs;
    final existing = prefs.getString(_installationIdKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final generated =
        '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}-${DateTime.now().millisecond.toRadixString(36)}';
    await prefs.setString(_installationIdKey, generated);
    return generated;
  }

  Future<String?> getInstallationId() async {
    final prefs = await _prefs;
    return prefs.getString(_installationIdKey);
  }

  Future<void> saveInstallationId(String installationId) async {
    final prefs = await _prefs;
    await prefs.setString(_installationIdKey, installationId);
  }

  String _termsAcceptedKey(String subject, String termsVersion) {
    final normalizedIdentity = subject.trim().toLowerCase();
    return '$_termsAcceptedPrefix:$normalizedIdentity:$termsVersion';
  }

  Future<bool> hasAcceptedTerms({
    required String userIdentity,
    required String termsVersion,
  }) async {
    if (userIdentity.trim().isEmpty) {
      return false;
    }

    final prefs = await _prefs;
    return prefs.getBool(_termsAcceptedKey(userIdentity, termsVersion)) ??
        false;
  }

  Future<bool> hasAcceptedTermsForDevice({
    required String installationId,
    required String termsVersion,
    String? legacyUserIdentity,
    String? legacyGroupId,
  }) async {
    if (installationId.trim().isEmpty) {
      return false;
    }

    if (await hasAcceptedTerms(
      userIdentity: installationId,
      termsVersion: termsVersion,
    )) {
      return true;
    }

    final legacyCandidates = <String?>[legacyUserIdentity, legacyGroupId];
    for (final candidate in legacyCandidates) {
      if (candidate == null || candidate.trim().isEmpty) {
        continue;
      }

      final accepted = await hasAcceptedTerms(
        userIdentity: candidate,
        termsVersion: termsVersion,
      );
      if (accepted) {
        await acceptTerms(
          userIdentity: installationId,
          termsVersion: termsVersion,
        );
        return true;
      }
    }

    return false;
  }

  Future<void> acceptTerms({
    required String userIdentity,
    required String termsVersion,
  }) async {
    if (userIdentity.trim().isEmpty) {
      return;
    }

    final prefs = await _prefs;
    await prefs.setBool(_termsAcceptedKey(userIdentity, termsVersion), true);
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
