import 'package:flutter/material.dart';
import 'package:logistiscout/models/api_service.dart';
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
    final userlogin = idController.text.trim();
    final mdp = mdpController.text.trim();
    if (userlogin.isEmpty || mdp.isEmpty) {
      setState(() { error = 'Veuillez remplir les deux champs.'; loading = false; });
      return;
    }
    // Vérification côté serveur
    final response = await ApiService.loginGroupe(userlogin, mdp);
    if (response == null) {
      setState(() { error = 'Identifiants invalides.'; loading = false; });
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', response['token'] ?? '');
    await prefs.setString('groupeId', response['id'].toString());
    await prefs.setString('groupe_nom', response['nom'] ?? '');
    await prefs.setString('userlogin', response['userlogin'] ?? '');
    setState(() { loading = false; });
    // Après connexion, demander le nom de l'utilisateur
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SaisieNomUtilisateurPage(
            onNomValide: () {
              Navigator.of(context).pushReplacementNamed('/accueil');
            },
          ),
        ),
      );
    }
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

class SaisieNomUtilisateurPage extends StatefulWidget {
  final VoidCallback onNomValide;
  const SaisieNomUtilisateurPage({super.key, required this.onNomValide});

  @override
  State<SaisieNomUtilisateurPage> createState() => _SaisieNomUtilisateurPageState();
}

class _SaisieNomUtilisateurPageState extends State<SaisieNomUtilisateurPage> {
  final TextEditingController nomController = TextEditingController();
  bool boutonActif = false;

  @override
  void initState() {
    super.initState();
    nomController.addListener(() {
      setState(() {
        boutonActif = nomController.text.trim().isNotEmpty;
      });
    });
  }

  Future<void> _validerNom() async {
    final nom = nomController.text.trim();
    if (nom.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('nom_utilisateur', nom);
      widget.onNomValide();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saisie du nom utilisateur')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomController,
                decoration: const InputDecoration(labelText: 'Nom utilisateur'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: boutonActif ? _validerNom : null,
                child: const Text('Valider'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
