import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logistiscout/domain/entities/controle.dart';
import 'package:logistiscout/domain/entities/tente.dart';
import 'package:logistiscout/ui/controllers/controle_controller.dart';

class ControleEditPage extends ConsumerStatefulWidget {
  final Tent tente;
  final String nomControleur;

  const ControleEditPage({
    super.key,
    required this.tente,
    required this.nomControleur,
  });

  @override
  ConsumerState<ControleEditPage> createState() => _ControleEditPageState();
}

class _ControleEditPageState extends ConsumerState<ControleEditPage> {
  final TextEditingController remarquesController = TextEditingController();
  final TextEditingController sardinesController = TextEditingController();
  final Map<String, bool> checklist = {};

  @override
  void dispose() {
    remarquesController.dispose();
    sardinesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sections = _sections();
    final explications = _explications();

    return Scaffold(
      appBar: AppBar(
        title: Text('Contrôle - ${widget.tente.nom}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            for (final section in sections.entries) ...[
              Text(
                section.key,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (explications[section.key] != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text(
                    explications[section.key]!,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              const SizedBox(height: 4),
              for (final item in section.value)
                CheckboxListTile(
                  title: Text(item),
                  value: checklist[item] ?? false,
                  onChanged: (v) => setState(() => checklist[item] = v ?? false),
                  dense: true,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              const Divider(height: 20),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: sardinesController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de sardines/piquets',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Attendu : ${_expectedSardines(widget.tente.tentType)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: remarquesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Remarques générales',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Valider le contrôle'),
              onPressed: () async {
                if (widget.nomControleur.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Veuillez saisir le nom du contrôleur.')));
                  return;
                }

                final payload = {
                  for (final e in checklist.entries) e.key: e.value,
                  'Nombre de sardines/piquets': sardinesController.text,
                  'nom_controleur': widget.nomControleur.trim(),
                };

                final controle = Control(
                  id: null,
                  tentId: widget.tente.id,
                  date: DateTime.now(),
                  comment: remarquesController.text.trim(),
                  checklist: payload,
                  userId: 0
                );

                await ref
                    .read(controlProvider(widget.tente.id).notifier)
                    .addControl(controle);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Contrôle enregistré avec succès !')));
                  Navigator.pop(context, true);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Map<String, List<String>> _sections() => {
    'Structure et éléments principaux': [
      'Toile extérieure',
      'Toile intérieure',
      'Sol de tente',
      'Mâts / arceaux',
      'Haubans',
      'Cordes supplémentaires',
      'Sardines / Piquets en nombre conforme',
      'Sardines / Piquets en bon état',
      'Sardines / Piquets propres',
    ],
    'Fixations et fermetures': [
      'Fermetures éclair',
      'Œillets / Systèmes de serrage',
      'Crochets / attaches de haubanage',
    ],
    'Accessoires et rangement': [
      'Housse de rangement',
      'Système de pliage / ficelles d’attache',
      'Fiche d’identification',
    ],
    'État général': [
      'Propreté extérieure et intérieure',
      'Tente sèche',
      'Pas d’odeur de moisi',
    ],
  };

  Map<String, String> _explications() => {
    'Structure et éléments principaux':
    "Vérifier l'état de la toile, du sol, des mâts, haubans et sardines.",
    'Fixations et fermetures':
    "Contrôler les fermetures, œillets et attaches.",
    'Accessoires et rangement':
    "Présence et état de la housse et des accessoires.",
    'État général':
    "La tente doit être propre, sèche et sans odeur de moisi.",
  };

  String _expectedSardines(String typeTente) {
    switch (typeTente.toLowerCase()) {
      case 'canadienne':
        return '24';
      case 'tipi':
        return '27';
      default:
        return '-';
    }
  }
}
