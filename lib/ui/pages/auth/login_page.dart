import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logistiscout/core/legal_constants.dart';
import 'package:logistiscout/services/app_exception.dart';
import 'package:logistiscout/ui/controllers/login_controller.dart';
import 'package:logistiscout/services/local_storage_service.dart';
import 'package:logistiscout/ui/pages/auth/forgot_password_page.dart';
import 'package:logistiscout/ui/pages/auth/register_page.dart';
import 'package:logistiscout/ui/pages/control/controle_saisie_nom_page.dart';

class LoginPage extends ConsumerStatefulWidget {
  final VoidCallback? onLogin; // ✅ Optional callback for after successful login
  final String termsVersion;

  const LoginPage({super.key, this.onLogin, this.termsVersion = kTermsVersion});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  String _errorMessageFor(Object error) {
    if (error is AppException) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        final backend = error.message.trim().toLowerCase();
        if (backend == 'mot de passe incorrect') {
          return 'Mot de passe incorrect.';
        }
        if (backend == 'compte introuvable ou supprimé') {
          return 'Ce compte a été supprimé ou n\'existe plus.';
        }
        if (backend == 'identifiants invalides') {
          return 'Identifiant ou mot de passe incorrect.';
        }
      }
      return error.message;
    }
    return error.toString().replaceFirst('Exception: ', '');
  }

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginControllerProvider);
    final uiError = loginState.asError?.error;

    ref.listen<AsyncValue<void>>(loginControllerProvider, (previous, next) {
      final currentError = next.asError?.error;
      final previousError = previous?.asError?.error;

      if (!mounted ||
          currentError == null ||
          identical(currentError, previousError)) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(_errorMessageFor(currentError)),
            backgroundColor: Colors.red,
          ),
        );
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Connexion')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 40),
              Text(
                'Bienvenue 👋',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Connectez-vous pour accéder à votre espace LogistiScout',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),

              TextFormField(
                controller: _loginController,
                decoration: const InputDecoration(
                  labelText: 'Identifiant',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Champ obligatoire' : null,
              ),
              const SizedBox(height: 16),

              // Mot de passe
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Champ obligatoire' : null,
              ),
              const SizedBox(height: 24),

              // Connexion button
              ElevatedButton.icon(
                icon: const Icon(Icons.login),
                label: loginState.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Se connecter'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                onPressed: loginState.isLoading
                    ? null
                    : () async {
                        if (_formKey.currentState?.validate() ?? false) {
                          final success = await ref
                              .read(loginControllerProvider.notifier)
                              .login(
                                _loginController.text.trim(),
                                _passwordController.text.trim(),
                              );
                          if (success && mounted) {
                            final installationId = await LocalStorageService
                                .instance
                                .getOrCreateInstallationId();
                            final groupId = await LocalStorageService.instance
                                .getGroupId();
                            final savedName = await LocalStorageService.instance
                                .getControllerName();

                            if (savedName == null || savedName.isEmpty) {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (ctx) =>
                                      ControllerPageName.controlerNamePage(
                                        onNomValide: (_) async {},
                                      ),
                                ),
                              );
                            }

                            final username = await LocalStorageService.instance
                                .getUsername();
                            final hasAcceptedTerms = await LocalStorageService
                                .instance
                                .hasAcceptedTermsForDevice(
                                  installationId: installationId,
                                  termsVersion: widget.termsVersion,
                                  legacyUserIdentity: username,
                                  legacyGroupId: groupId,
                                );

                            if (!hasAcceptedTerms && mounted) {
                              final encodedUser = Uri.encodeQueryComponent(
                                installationId,
                              );
                              context.go('/terms?user=$encodedUser&next=/home');
                              return;
                            }

                            // 🔹 Continue le flux normal
                            widget.onLogin?.call();
                          }
                        }
                      },
              ),

              if (uiError != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessageFor(uiError),
                  style: const TextStyle(color: Colors.red),
                ),
              ],

              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ForgotPasswordPage(),
                    ),
                  );
                },
                child: const Text('Mot de passe oublié ?'),
              ),

              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterPage()),
                  );
                },
                child: const Text("Créer un compte"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
