import 'package:flutter/material.dart';
import '../models/models.dart';
import '../models/api_service.dart';
import 'controle_saisie_nom_page.dart';

class ControleEditPage extends StatefulWidget {
  final Tente tente;
  final String nomControleur;
  const ControleEditPage({Key? key, required this.tente, required this.nomControleur}) : super(key: key);

  @override
  State<ControleEditPage> createState() => _ControleEditPageState();
}

class _ControleEditPageState extends State<ControleEditPage> {
  late Map<String, dynamic> checklist;
  late TextEditingController remarquesController;
  late TextEditingController sardinesController;

  @override
  void initState() {
    super.initState();
    checklist = {};
    remarquesController = TextEditingController(text: widget.tente.remarques ?? '');
    sardinesController = TextEditingController();
    // Pas de pré-remplissage automatique de la checklist
  }

  @override
  void dispose() {
    remarquesController.dispose();
    sardinesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, String> explications = {
      'Structure et éléments principaux':
          "Vérifier l'état général de la toile, du sol, des mâts, haubans, cordes et sardines/piquets.",
      'Fixations et fermetures':
          "Contrôler les fermetures éclair, œillets, systèmes de serrage et attaches de haubanage.",
      'Accessoires et rangement':
          "Présence et état de la housse, du système de pliage et de la fiche d'identification.",
      'État général':
          "Propreté, séchage complet et absence d'odeur de moisi.",
    };

    final Map<String, List<Map<String, String>>> sections = {
      'Structure et éléments principaux': [
        {'label': "Toile extérieure"},
        {'label': "Toile intérieure"},
        {'label': "Sol de tente"},
        {'label': "Mâts/arceaux"},
        {'label': "Haubans"},
        {'label': "Cordes supplémentaires"},
        {'label': "Sardines / Piquets : Nombre conforme au besoin (compter)"},
        {'label': "Sardines / Piquets : Forme correcte (non pliée)"},
        {'label': "Sardines / Piquets : Propres"},
      ],
      'Fixations et fermetures': [
        {'label': "Fermetures éclair"},
        {'label': "Œillets / Systèmes de serrage"},
        {'label': "Crochets ou attaches de haubanage"},
      ],
      'Accessoires et rangement': [
        {'label': "Housse de rangement"},
        {'label': "Système de pliage / ficelles d'attache"},
        {'label': "Fiche d'identification"},
      ],
      'État général': [
        {'label': "Propreté extérieure et intérieure"},
        {'label': "Tente sèche"},
        {'label': "Odeurs"},
      ],
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau contrôle')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            ...sections.entries.map((section) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(section.key, style: Theme.of(context).textTheme.titleMedium),
                if (explications[section.key] != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text(
                      explications[section.key]!,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ...section.value.map((item) {
                  final label = item['label'] ?? '';
                  final key = 'verifie_valide_$label';
                  final remarqueKey = 'remarque_$label';
                  checklist[key] ??= false;
                  checklist[remarqueKey] ??= '';
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(label)),
                          Checkbox(
                            value: checklist[key],
                            onChanged: (val) => setState(() => checklist[key] = val ?? false),
                          ),
                          const Text('Vérifié et validé', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 8),
              ],
            )),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: sardinesController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Nombre de sardines/piquets'),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Attendu : ${widget.tente.typeTente == 'Canadienne' ? '24'
                    : widget.tente.typeTente == 'Tipi' ? '27' : '-'}',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: remarquesController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Remarques'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Valider le contrôle'),
              onPressed: () async {
                if (widget.nomControleur.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Veuillez saisir le nom de la personne qui fait le contrôle.')),
                  );
                  return;
                }
                final Map<String, dynamic> toSend = {};
                for (final section in sections.entries) {
                  for (final item in section.value) {
                    final label = item['label'] ?? '';
                    toSend['verifie_valide_$label'] = checklist['verifie_valide_$label'] ?? false;
                    toSend['remarque_$label'] = checklist['remarque_$label'] ?? '';
                  }
                }
                toSend['Nombre de sardines/piquets'] = sardinesController.text;
                toSend['nom_controleur'] = widget.nomControleur.trim();
                await ApiService.addControle({
                  'tenteId': widget.tente.id,
                  'userId': 0,
                  'date': DateTime.now().toIso8601String(),
                  'checklist': toSend,
                  'remarques': remarquesController.text,
                });
                // Ajout de la mise à jour de la tente avec tous les champs obligatoires
                await ApiService.updateTente(widget.tente.id, {
                  'nom': widget.tente.nom,
                  'uniteId': widget.tente.uniteId,
                  'etat': widget.tente.etat,
                  'remarques': remarquesController.text,
                  'estIntegree': widget.tente.tapisSolIntegre,
                  'nbPlaces': widget.tente.nbPlaces,
                  'typeTente': widget.tente.typeTente,
                  'unitePreferee': widget.tente.unitePreferee,
                  'couleurs': widget.tente.couleurs,
                  'groupeId': widget.tente.groupeId,
                });
                if (mounted) Navigator.pop(context, true);
              },
            ),
          ],
        ),
      ),
    );
  }
}

