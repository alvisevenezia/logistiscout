import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SaisieNomUtilisateurPage extends StatefulWidget {
  final VoidCallback onNomValide;
  const SaisieNomUtilisateurPage({Key? key, required this.onNomValide}) : super(key: key);

  @override
  State<SaisieNomUtilisateurPage> createState() => _SaisieNomUtilisateurPageState();
}

class _SaisieNomUtilisateurPageState extends State<SaisieNomUtilisateurPage> {
  final TextEditingController nomController = TextEditingController();
  String? erreur;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNomUtilisateur();
  }

  Future<void> _loadNomUtilisateur() async {
    final prefs = await SharedPreferences.getInstance();
    final nom = prefs.getString('nomUtilisateur');
    if (nom != null && nom.isNotEmpty) {
      nomController.text = nom;
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _saveNomUtilisateur(String nom) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nomUtilisateur', nom);
  }

  @override
  void dispose() {
    nomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Qui se connecte ?')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Merci d’indiquer qui utilise l’application.\n\nCe nom sera utilisé pour les contrôles et l’historique.',
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: nomController,
                    decoration: InputDecoration(
                      labelText: 'Nom et prénom',
                      errorText: erreur,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Continuer'),
                    onPressed: nomController.text.trim().isEmpty
                        ? null
                        : () async {
                            if (nomController.text.trim().isEmpty) {
                              setState(() => erreur = 'Le nom est obligatoire');
                              return;
                            }
                            await _saveNomUtilisateur(nomController.text.trim());
                            widget.onNomValide();
                          },
                  ),
                ],
              ),
            ),
    );
  }
}

