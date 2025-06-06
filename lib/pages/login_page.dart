import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback onLogin;
  const LoginPage({super.key, required this.onLogin});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController idController = TextEditingController();
  final TextEditingController mdpController = TextEditingController();
  bool loading = false;
  String? error;

  Future<void> _login() async {
    setState(() { loading = true; error = null; });
    final id = idController.text.trim();
    final mdp = mdpController.text.trim();
    if (id.isEmpty || mdp.isEmpty) {
      setState(() { error = 'Veuillez remplir les deux champs.'; loading = false; });
      return;
    }
    // Ici, on pourrait vérifier le couple id/mdp côté serveur ou localement
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('groupe_id', id);
    await prefs.setString('groupe_mdp', mdp);
    widget.onLogin();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connexion Groupe')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: idController,
                  decoration: const InputDecoration(labelText: 'ID du groupe'),
                  enabled: !loading,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: mdpController,
                  decoration: const InputDecoration(labelText: 'Mot de passe du groupe'),
                  obscureText: true,
                  enabled: !loading,
                ),
                const SizedBox(height: 24),
                if (error != null)
                  Text(error!, style: const TextStyle(color: Colors.red)),
                ElevatedButton(
                  onPressed: loading ? null : _login,
                  child: loading ? const CircularProgressIndicator() : const Text('Connexion'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

