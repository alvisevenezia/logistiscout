import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:logistiscout/core/legal_constants.dart';
import 'package:logistiscout/services/api_service.dart';
import 'package:logistiscout/services/local_storage_service.dart';
import 'package:logistiscout/services/token_store.dart';

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

    final access = await storage.readAccessToken();
    final refresh = await storage.readRefreshToken();

    bool loggedIn = false;

    if (access != null && access.isNotEmpty) {
      // If token is NOT expired => logged in
      loggedIn = !JwtDecoder.isExpired(access);
    }

    // If access expired but we have refresh token, try refresh once
    if (!loggedIn && refresh != null && refresh.isNotEmpty) {
      try {
        final api = ApiService();
        final ok = await api.refreshToken();
        loggedIn = ok;
      } catch (_) {
        loggedIn = false;
      }
    }

    if (!mounted) return;

    if (!loggedIn) {
      context.go('/login');
      return;
    }

    final username = await LocalStorageService.instance.getUsername();
    if (username == null || username.trim().isEmpty) {
      context.go('/login');
      return;
    }

    final accepted = await LocalStorageService.instance.hasAcceptedTerms(
      userIdentity: username,
      termsVersion: kTermsVersion,
    );

    if (!mounted) {
      return;
    }

    if (accepted) {
      context.go('/home');
      return;
    }

    final encodedUser = Uri.encodeQueryComponent(username);
    context.go('/terms?user=$encodedUser&next=/home');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
