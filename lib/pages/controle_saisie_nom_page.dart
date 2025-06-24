import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ControleSaisieNomPage extends StatefulWidget {
  final void Function(String nomControleur) onNomValide;
  const ControleSaisieNomPage({Key? key, required this.onNomValide}) : super(key: key);

  @override
  State<ControleSaisieNomPage> createState() => _ControleSaisieNomPageState();
}

class _ControleSaisieNomPageState extends State<ControleSaisieNomPage> {
  final TextEditingController nomController = TextEditingController();
  String? erreur;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNomControleur();
  }

  Future<void> _loadNomControleur() async {
    final prefs = await SharedPreferences.getInstance();
    final nom = prefs.getString('nomControleur');
    if (nom != null && nom.isNotEmpty) {
      nomController.text = nom;
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _saveNomControleur(String nom) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nom_utilisateur', nom);
  }

  @override
  void dispose() {
    nomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Identification du contrôleur')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Avant de commencer le contrôle, veuillez indiquer qui réalise ce contrôle.\n\n⚠️ Le contrôle engage votre responsabilité sur l\'état de la tente.',
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: nomController,
                    decoration: InputDecoration(
                      labelText: 'Nom et prénom du contrôleur',
                      errorText: erreur,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Commencer le contrôle'),
                    onPressed: nomController.text.trim().isEmpty
                        ? null
                        : () async {
                            if (nomController.text.trim().isEmpty) {
                              setState(() => erreur = 'Le nom est obligatoire');
                              return;
                            }
                            await _saveNomControleur(nomController.text.trim());
                            widget.onNomValide(nomController.text.trim());
                          },
                  ),
                ],
              ),
            ),
    );
  }
}

