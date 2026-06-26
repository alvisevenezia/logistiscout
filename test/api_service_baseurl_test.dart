import 'package:flutter_test/flutter_test.dart';
import 'package:logistiscout/services/api_service.dart';

void main() {
  test('baseUrl par défaut = prod quand aucun override', () {
    ApiService.reconfigure(
      baseUrl: const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'https://api.logistiscout.fr',
      ),
    );
    expect(ApiService().baseUrl, 'https://api.logistiscout.fr');
  });

  test('baseUrl explicite respecté (cas env beta)', () {
    ApiService.reconfigure(baseUrl: 'https://beta.api.logistiscout.fr');
    expect(ApiService().baseUrl, 'https://beta.api.logistiscout.fr');
  });
}
