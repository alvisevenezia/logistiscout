import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logistiscout/services/api_service.dart';
import 'package:logistiscout/services/local_storage_service.dart';
import 'dart:developer' as developer;

import 'package:logistiscout/services/token_store.dart';

class LoginController extends StateNotifier<AsyncValue<void>> {
  final ApiService _api;
  final LocalStorageService _localStorage = LocalStorageService.instance;
  final TokenStore _tokenStore = TokenStore.instance;

  LoginController(this._api) : super(const AsyncData(null));

  Future<bool> login(String userLogin, String mdp) async {
    state = const AsyncLoading();
    try {
      final response = await _api.loginGroup(userLogin.trim(), mdp.trim());

      developer.log('[LoginController] API response: $response');

      if (response['id'] == null) {
        throw Exception('Identifiants incorrects ou groupe introuvable');
      }

      await _localStorage.saveUsername(userLogin);
      await _localStorage.saveGroupId(response['id'].toString());
      await _tokenStore.saveAccessToken(response['access_token']);
      await _tokenStore.saveRefreshToken(response['refresh_token']);

      developer.log('[LoginController] ✅ Login successful');
      developer.log('[LoginController] userlogin=$userLogin, groupId=${response['id']}, token=${response['access_token']}');

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
