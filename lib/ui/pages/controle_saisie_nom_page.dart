import 'package:flutter/material.dart';
import 'package:logistiscout/services/local_storage_service.dart';

class ControleSaisieNomPage extends StatefulWidget {
  final Future<void> Function(String) onNomValide;

  const ControleSaisieNomPage({super.key, required this.onNomValide});

  @override
  State<ControleSaisieNomPage> createState() => _ControleSaisieNomPageState();
}

class _ControleSaisieNomPageState extends State<ControleSaisieNomPage> {
  final _controller = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedName();
  }

  Future<void> _loadSavedName() async {
    final savedName = await LocalStorageService.instance.getControllerName();
    if (mounted) {
      setState(() {
        if (savedName != null && savedName.isNotEmpty) {
          _controller.text = savedName;
        }
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Nom du contrôleur')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Avant de commencer le contrôle, veuillez confirmer ou saisir votre nom :',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Nom du contrôleur',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: const Text('Valider'),
              onPressed: () async {
                final name = _controller.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Veuillez entrer votre nom.')),
                  );
                  return;
                }

                // ✅ Enregistrer le nom
                await LocalStorageService.instance.saveControllerName(name);

                // ✅ Continuer le flux
                await widget.onNomValide(name);
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
