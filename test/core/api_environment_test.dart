import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistiscout/core/api_environment.dart';
import 'package:logistiscout/services/api_service.dart';
import 'package:logistiscout/services/token_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    ApiService.reconfigure(baseUrl: ApiService.devBaseUrl);
  });

  test('le choix n est propose que si le build ne vise pas la prod', () {
    expect(ApiEnvironmentSettings.isSwitchable(ApiService.devBaseUrl), isTrue);
    expect(
      ApiEnvironmentSettings.isSwitchable(ApiService.prodBaseUrl),
      isFalse,
    );
  });

  test('choisir un serveur bascule l instance deja utilisee', () async {
    final api = ApiService();

    await ApiEnvironmentSettings.select(ApiEnvironment.prod);

    expect(api.baseUrl, ApiService.prodBaseUrl);
    expect(ApiEnvironmentSettings.current, ApiEnvironment.prod);
    expect(ApiService.baseUrlListenable.value, ApiService.prodBaseUrl);
  });

  test('le choix est memorise et reapplique au demarrage', () async {
    await ApiEnvironmentSettings.select(ApiEnvironment.prod);
    ApiService.reconfigure(baseUrl: ApiService.devBaseUrl);

    await ApiEnvironmentSettings.restore();

    expect(ApiService().baseUrl, ApiService.prodBaseUrl);
  });

  test('changer de serveur efface la session', () async {
    await TokenStore.instance.saveAccessToken('token-dev');
    await TokenStore.instance.saveRefreshToken('refresh-dev');

    await ApiEnvironmentSettings.select(ApiEnvironment.prod);

    expect(await TokenStore.instance.readAccessToken(), isNull);
    expect(await TokenStore.instance.readRefreshToken(), isNull);
  });

  test('message d erreur lisible extrait du detail structure', () {
    expect(
      ApiService.extractErrorDetail(
        '{"detail":{"code":"S3_UPLOAD_FAILED","message":"Stockage indisponible."}}',
      ),
      'Stockage indisponible.',
    );
    expect(ApiService.extractErrorDetail('{"detail":"Introuvable"}'), 'Introuvable');
    expect(ApiService.extractErrorDetail('<html>502</html>'), isNull);
  });
}
