import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistiscout/ui/pages/auth/auth_gate.dart';

// Jetons JWT non signés (seule la date d'expiration est lue au démarrage).
const _validAccess =
    'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjo0MTAyNDQ0ODAwfQ.x';
const _expiredAccess =
    'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxMDAwMDAwMDAwfQ.x';

void main() {
  Future<String?> value(String? v) async => v;

  test('jeton d acces valide: session ouverte sans rafraichir', () async {
    var refreshed = false;
    final ok = await hasValidSession(
      readAccessToken: () => value(_validAccess),
      readRefreshToken: () => value('r'),
      refresh: () async => refreshed = true,
    );
    expect(ok, isTrue);
    expect(refreshed, isFalse);
  });

  test('jeton d acces expire: on tente le rafraichissement', () async {
    final ok = await hasValidSession(
      readAccessToken: () => value(_expiredAccess),
      readRefreshToken: () => value('r'),
      refresh: () async => true,
    );
    expect(ok, isTrue);
  });

  test('rafraichissement refuse: ecran de connexion', () async {
    final ok = await hasValidSession(
      readAccessToken: () => value(_expiredAccess),
      readRefreshToken: () => value('r'),
      refresh: () async => false,
    );
    expect(ok, isFalse);
  });

  test('jeton illisible: compte comme expire, pas de blocage', () async {
    final ok = await hasValidSession(
      readAccessToken: () => value('pas-un-jwt'),
      readRefreshToken: () => value(null),
      refresh: () async => true,
    );
    expect(ok, isFalse);
  });

  test('trousseau en erreur: ecran de connexion et jetons effaces', () async {
    var cleared = false;
    final ok = await hasValidSession(
      readAccessToken: () =>
          Future.error(PlatformException(code: '-25308', message: 'keychain')),
      readRefreshToken: () => value('r'),
      refresh: () async => true,
      clearTokens: () async => cleared = true,
    );
    expect(ok, isFalse);
    expect(cleared, isTrue);
  });

  test('trousseau qui ne repond pas: on n attend pas indefiniment', () async {
    final ok = await hasValidSession(
      readAccessToken: () => Completer<String?>().future,
      readRefreshToken: () => value('r'),
      refresh: () async => true,
      timeout: const Duration(milliseconds: 50),
    );
    expect(ok, isFalse);
  });

  test('rafraichissement en erreur reseau: ecran de connexion', () async {
    final ok = await hasValidSession(
      readAccessToken: () => value(null),
      readRefreshToken: () => value('r'),
      refresh: () => Future.error(Exception('offline')),
    );
    expect(ok, isFalse);
  });
}
