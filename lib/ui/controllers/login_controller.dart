import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logistiscout/services/api_service.dart';
import 'dart:developer' as developer;

class LoginController extends StateNotifier<AsyncValue<void>> {
  final ApiService _api;

  LoginController(this._api) : super(const AsyncData(null));

  /// Performs login and saves credentials
  Future<bool> login(String userlogin, String mdp) async {
    state = const AsyncLoading();
    try {
      final response = await _api.loginGroupe(userlogin.trim(), mdp.trim());
      if (response == null || response['id'] == null) {
        throw Exception('Identifiants incorrects ou groupe introuvable');
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userlogin', userlogin);
      await prefs.setString('groupeId', response['id'].toString());
      await prefs.setString('token', response['token'] ?? '');

      prefs.getKeys().forEach((key) async {
        developer.log('$key: ${prefs.get(key)}');
      });


      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

}

final loginControllerProvider =
StateNotifierProvider<LoginController, AsyncValue<void>>(
      (ref) => LoginController(ApiService()),
);
