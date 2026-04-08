import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logistiscout/ui/controllers/login_controller.dart';
import 'package:logistiscout/services/local_storage_service.dart';
import 'package:logistiscout/ui/pages/auth/forgot_password_page.dart';
import 'package:logistiscout/ui/pages/auth/register_page.dart';
import 'package:logistiscout/ui/pages/control/controle_saisie_nom_page.dart';

class LoginPage extends ConsumerStatefulWidget {
  final VoidCallback? onLogin; // ✅ Optional callback for after successful login

  const LoginPage({super.key, this.onLogin});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginControllerProvider);

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

                            // 🔹 Continue le flux normal
                            widget.onLogin?.call();
                          }
                        }
                      },
              ),

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
              // Error message
              if (loginState.hasError)
                if (loginState.error.toString().contains(
                  '401',
                )) // 🔹 Check for specific error
                  const Text(
                    'Identifiant ou mot de passe incorrect',
                    style: TextStyle(color: Colors.red),
                  )
                else
                  Text(
                    loginState.error?.toString().replaceFirst(
                          'Exception: ',
                          '',
                        ) ??
                        'Erreur inconnue',
                    style: const TextStyle(color: Colors.red),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
