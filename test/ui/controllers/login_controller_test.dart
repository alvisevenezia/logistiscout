import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistiscout/services/api_service.dart';
import 'package:logistiscout/ui/controllers/login_controller.dart';
import 'package:mocktail/mocktail.dart';

class MockApiService extends Mock implements ApiService {}

void main() {
  group('LoginController', () {
    test('login echoue si le backend ne renvoie pas de id', () async {
      final api = MockApiService();
      when(() => api.loginGroup(any(), any())).thenAnswer(
        (_) async => {'access_token': 'token', 'refresh_token': 'refresh'},
      );

      final container = ProviderContainer(
        overrides: [
          loginControllerProvider.overrideWith(
            (ref) => LoginController(ref, api),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(loginControllerProvider.notifier);
      final ok = await notifier.login('bad-login', 'bad-pass');

      expect(ok, isFalse);
      expect(container.read(loginControllerProvider), isA<AsyncError<void>>());
      verify(() => api.loginGroup('bad-login', 'bad-pass')).called(1);
    });
  });
}
