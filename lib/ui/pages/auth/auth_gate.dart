import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:logistiscout/core/legal_constants.dart';
import 'package:logistiscout/services/api_service.dart';
import 'package:logistiscout/services/local_storage_service.dart';
import 'package:logistiscout/services/token_store.dart';

/// Indique si une session valide existe au démarrage.
///
/// Ne lève jamais : un trousseau illisible, un jeton corrompu ou un appel
/// qui ne répond pas renvoient `false` (écran de connexion) au lieu de
/// bloquer l'app sur l'écran de chargement.
Future<bool> hasValidSession({
  required Future<String?> Function() readAccessToken,
  required Future<String?> Function() readRefreshToken,
  required Future<bool> Function() refresh,
  Future<void> Function()? clearTokens,
  Duration timeout = const Duration(seconds: 15),
}) async {
  try {
    final access = await readAccessToken().timeout(timeout);
    if (access != null && access.isNotEmpty && !_isExpired(access)) {
      return true;
    }

    final refreshToken = await readRefreshToken().timeout(timeout);
    if (refreshToken == null || refreshToken.isEmpty) return false;
    return await refresh().timeout(timeout);
  } catch (e, st) {
    developer.log(
      'Startup session check failed, falling back to login',
      name: 'AuthGate',
      error: e,
      stackTrace: st,
    );
    // Des jetons illisibles bloqueraient chaque démarrage : on repart propre.
    try {
      await clearTokens?.call().timeout(timeout);
    } catch (_) {}
    return false;
  }
}

/// Un jeton mal formé compte comme expiré.
bool _isExpired(String token) {
  try {
    return JwtDecoder.isExpired(token);
  } catch (_) {
    return true;
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final storage = TokenStore.instance;
    final loggedIn = await hasValidSession(
      readAccessToken: storage.readAccessToken,
      readRefreshToken: storage.readRefreshToken,
      refresh: () => ApiService().refreshToken(),
      clearTokens: storage.clear,
    );

    if (!mounted) return;

    if (!loggedIn) {
      context.go('/login');
      return;
    }

    String? nextRoute;
    try {
      nextRoute = await _routeAfterLogin();
    } catch (e, st) {
      developer.log(
        'Reading local preferences failed at startup',
        name: 'AuthGate',
        error: e,
        stackTrace: st,
      );
      nextRoute = '/home';
    }

    if (!mounted) return;
    context.go(nextRoute);
  }

  /// Accueil si les conditions d'utilisation sont acceptées sur cet appareil,
  /// sinon l'écran d'acceptation.
  Future<String> _routeAfterLogin() async {
    final installationId = await LocalStorageService.instance
        .getOrCreateInstallationId();
    final username = await LocalStorageService.instance.getUsername();
    final groupId = await LocalStorageService.instance.getGroupId();

    final accepted = await LocalStorageService.instance
        .hasAcceptedTermsForDevice(
          installationId: installationId,
          termsVersion: kTermsVersion,
          legacyUserIdentity: username,
          legacyGroupId: groupId,
        );
    if (accepted) return '/home';

    final encodedUser = Uri.encodeQueryComponent(installationId);
    return '/terms?user=$encodedUser&next=/home';
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
