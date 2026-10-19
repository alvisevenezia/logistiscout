import 'package:flutter/foundation.dart';
import 'package:logistiscout/services/api_service.dart';
import 'package:logistiscout/services/token_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ApiEnvironment {
  dev('Dev', ApiService.devBaseUrl),
  prod('Prod', ApiService.prodBaseUrl);

  const ApiEnvironment(this.label, this.baseUrl);

  final String label;
  final String baseUrl;
}

/// Choix du serveur (dev / prod) dans les builds de dev.
///
/// Les builds de production visent toujours la prod et ne proposent pas de
/// choix ; les autres (debug, profile, piste beta) peuvent basculer.
class ApiEnvironmentSettings {
  static const _prefsKey = 'api_environment';

  static bool get canSwitch => isSwitchable(ApiService.defaultBaseUrl);

  @visibleForTesting
  static bool isSwitchable(String buildDefaultBaseUrl) =>
      buildDefaultBaseUrl != ApiService.prodBaseUrl;

  static ApiEnvironment get current =>
      ApiService().baseUrl == ApiService.prodBaseUrl
      ? ApiEnvironment.prod
      : ApiEnvironment.dev;

  /// Réapplique le serveur choisi précédemment ; à appeler au démarrage,
  /// avant le premier appel réseau.
  static Future<void> restore() async {
    if (!canSwitch) return;
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    for (final env in ApiEnvironment.values) {
      if (env.name == saved) {
        ApiService.useBaseUrl(env.baseUrl);
        return;
      }
    }
  }

  /// Bascule de serveur. Les comptes et jetons sont propres à chaque serveur :
  /// la session en cours est effacée.
  static Future<void> select(ApiEnvironment env) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, env.name);
    await TokenStore.instance.clear();
    ApiService.useBaseUrl(env.baseUrl);
  }
}
