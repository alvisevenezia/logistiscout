import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logistiscout/services/api_service.dart';
import 'package:logistiscout/services/local_storage_service.dart';
import 'dart:developer' as developer;

class LoginController extends StateNotifier<AsyncValue<void>> {
  final ApiService _api;
  final LocalStorageService _localStorage = LocalStorageService.instance;

  LoginController(this._api) : super(const AsyncData(null));

  /// Performs login and saves credentials
  Future<bool> login(String userlogin, String mdp) async {
    state = const AsyncLoading();
    try {
      final response = await _api.loginGroupe(userlogin.trim(), mdp.trim());

      developer.log('[LoginController] API response: $response');

      if (response == null || response['id'] == null) {
        throw Exception('Identifiants incorrects ou groupe introuvable');
      }

      await _localStorage.saveUsername(userlogin);
      await _localStorage.saveGroupId(response['id'].toString());
      await _localStorage.saveToken(response['token']);

      developer.log('[LoginController] ✅ Login successful');
      developer.log('[LoginController] userlogin=$userlogin, groupId=${response['id']}, token=${response['token']}');

      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      developer.log('[LoginController] ❌ Login failed', error: e, stackTrace: st);
      state = AsyncError(e, st);
      return false;
    }
  }
}

final loginControllerProvider =
StateNotifierProvider<LoginController, AsyncValue<void>>(
      (ref) => LoginController(ApiService()),
);
