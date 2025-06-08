import 'package:flutter/material.dart';
import 'package:logistiscout/models/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class TenteDetailPage extends StatefulWidget {
  final Tente? tente;
  final int? tenteId;
  const TenteDetailPage({super.key, this.tente, this.tenteId}) : assert(tente != null || tenteId != null, 'Il faut fournir soit une tente, soit un id');

  @override
  State<TenteDetailPage> createState() => _TenteDetailPageState();
}

class _TenteDetailPageState extends State<TenteDetailPage> {
  late String etat;
  late String remarques;
  late String unite;
  Tente? tente;
  bool loading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    if (widget.tente != null) {
      tente = widget.tente;
      _updateFromTente();
    } else if (widget.tenteId != null) {
      _loadTente(widget.tenteId!);
    }
  }

  Future<void> _loadTente(int id) async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final String groupeId = prefs.getString('groupeId') ?? '';
      final data = await ApiService.getTente(id, groupeId: groupeId);
      setState(() {
        tente = Tente.fromJson(data);
        _updateFromTente();
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Erreur lors du chargement de la tente';
        loading = false;
      });
    }
  }

  void _updateFromTente() {
    if (tente == null) return;
    etat = tente!.etat;
    unite = tente!.unitePreferee.isNotEmpty ? tente!.unitePreferee : "Non affectée";
    if (tente!.historiqueControles.isNotEmpty) {
      remarques = tente!.historiqueControles.last.remarques;
    } else {
      remarques = tente!.remarques;
    }
  }

  Future<void> _refreshTente() async {
    if (tente == null) return;
    final prefs = await SharedPreferences.getInstance();
    final String groupeId = prefs.getString('groupeId') ?? '';
    final updated = await ApiService.getTente(tente!.id, groupeId: groupeId);
    setState(() {
      tente = Tente.fromJson(updated);
      _updateFromTente();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Détail tente')),
        body: Center(child: Text(error!)),
      );
    }
    if (tente == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Détail tente')),
        body: const Center(child: Text('Tente introuvable.')),
      );
    }
    final List<String> types = ['Canadienne', 'Tipi', 'Autre'];
    final List<String> unitesNoms = [
      'Farfadet',
      'Louveteaux-Jeannettes',
      'Scout-Guide',
      'Pionnier-Caravelle',
      'Compagnon',
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text('Détail - ${tente!.nom}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Rafraîchir',
            onPressed: _refreshTente,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextFormField(
              initialValue: tente!.nom,
              decoration: const InputDecoration(labelText: 'Nom'),
              onChanged: (val) => setState(() => tente = tente!.copyWith(nom: val)),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: types.contains(tente!.typeTente) ? tente!.typeTente : 'Autre',
              items: types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (val) => setState(() => tente = tente!.copyWith(typeTente: val ?? 'Autre')),
              decoration: const InputDecoration(labelText: 'Type'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: tente!.nbPlaces.toString(),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Nombre de places'),
              onChanged: (val) => setState(() => tente = tente!.copyWith(nbPlaces: int.tryParse(val) ?? tente!.nbPlaces)),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: tente!.tapisSolIntegre,
              onChanged: (val) => setState(() => tente = tente!.copyWith(tapisSolIntegre: val)),
              title: const Text('Tapis de sol intégré'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: unitesNoms.contains(tente!.unitePreferee) ? tente!.unitePreferee : null,
              items: unitesNoms.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
              onChanged: (val) => setState(() => tente = tente!.copyWith(unitePreferee: val ?? '')),
              decoration: const InputDecoration(labelText: 'Unité préférée'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: ['Bon', 'À réparer', 'HS', 'Perdue'].contains(tente!.etat) ? tente!.etat : 'Bon',
              items: ['Bon', 'À réparer', 'HS', 'Perdue']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setState(() => tente = tente!.copyWith(etat: val ?? 'Bon')),
              decoration: const InputDecoration(labelText: 'État'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: tente!.remarques,
              decoration: const InputDecoration(labelText: 'Remarques'),
              maxLines: 2,
              onChanged: (val) => setState(() => tente = tente!.copyWith(remarques: val)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Enregistrer'),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                final groupeId = prefs.getString('groupeId') ?? '';
                await ApiService.updateTente(tente!.id, {
                  'nom': tente!.nom,
                  'uniteId': tente!.uniteId,
                  'etat': tente!.etat,
                  'remarques': tente!.remarques,
                  'estIntegree': tente!.tapisSolIntegre,
                  'nbPlaces': tente!.nbPlaces,
                  'typeTente': tente!.typeTente,
                  'unitePreferee': tente!.unitePreferee,
                  'couleurs': tente!.couleurs,
                  'groupeId': groupeId,
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Modifications enregistrées !')),
                  );
                }
                await _refreshTente();
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.assignment_turned_in),
              label: const Text('Faire un contrôle'),
              onPressed: () async {
                final result = await showModalBottomSheet<Tente>(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => ControleChecklistSheet(tenteId: tente!.id),
                );
                if (result != null) {
                  await _refreshTente();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ControleChecklistSheet extends StatefulWidget {
  final int? tenteId;
  const ControleChecklistSheet({super.key, this.tenteId});

  @override
  State<ControleChecklistSheet> createState() => _ControleChecklistSheetState();
}

class _ControleChecklistSheetState extends State<ControleChecklistSheet> {
  // Checklist structurée par sections
  final Map<String, List<Map<String, dynamic>>> sections = {
    'Structure et éléments principaux': [
      {
        'label': "Toile extérieure : Pas de trous, de déchirures ni d'usure excessive ; Coutures intactes ; Imperméabilité visiblement préservée",
        'value': false
      },
      {
        'label': "Toile intérieure (si double toit) : Propre et sans moisissure ; Pas de déchirure ni accroc",
        'value': false
      },
      {
        'label': "Sol de tente : Étanche, sans déchirure ni perforation ; Soudures/coutures intactes",
        'value': false
      },
      {
        'label': "Mâts (ou arceaux selon modèle) : En bon état, non tordus ; Présents en nombre suffisant ; Assemblage fonctionnel",
        'value': false
      },
      {
        'label': "Haubans : Présents, attachés solidement ; Corde non effilochée ; Réglages fonctionnels",
        'value': false
      },
      {
        'label': "Cordes supplémentaires : Présentes et utilisables",
        'value': false
      },
      // Sardines/ Piquets: champ nombre + cases à cocher
      {
        'label': "Sardines / Piquets : Nombre conforme au besoin (compter)",
        'value': false,
        'isCount': true
      },
      {
        'label': "Sardines / Piquets : Forme correcte (non pliée)",
        'value': false
      },
      {
        'label': "Sardines / Piquets : Propres",
        'value': false
      },
    ],
    'Fixations et fermetures': [
      {
        'label': "Fermetures éclair : Fonctionnelles, sans blocage ; Dents intactes",
        'value': false
      },
      {
        'label': "Œillets / Systèmes de serrage : Présents et utilisables",
        'value': false
      },
      {
        'label': "Crochets ou attaches de haubanage : Présents, bien cousus ou soudés",
        'value': false
      },
    ],
    'Accessoires et rangement': [
      {
        'label': "Housse de rangement : Présente, propre et sans trou ; Étiquette lisible",
        'value': false
      },
      {
        'label': "Système de pliage / ficelles d'attache : Pratiques et complets",
        'value': false
      },
      {
        'label': "Présence d'une fiche d'identification (nom patrouille, numéro tente)",
        'value': false
      },
    ],
    'État général': [
      {
        'label': "Propreté extérieure et intérieure : Nettoyée avant rangement ; Absence de boue, sable, feuilles, etc.",
        'value': false
      },
      {
        'label': "Tente sèche : Bien séchée avant stockage",
        'value': false
      },
      {
        'label': "Odeurs : Pas d'odeur de moisi",
        'value': false
      },
    ],
  };
  final TextEditingController commentaireController = TextEditingController();
  final TextEditingController sardinesCountController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: DraggableScrollableSheet(
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final section in sections.entries) ...[
                  Text(section.key, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...section.value.map((item) {
                    if (item['isCount'] == true) {
                      return Row(
                        children: [
                          Expanded(
                            child: CheckboxListTile(
                              title: Text(item['label']),
                              value: item['value'],
                              onChanged: (val) {
                                setState(() {
                                  item['value'] = val ?? false;
                                });
                              },
                            ),
                          ),
                          SizedBox(
                            width: 80,
                            child: TextField(
                              controller: sardinesCountController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Nb',
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      );
                    } else {
                      return CheckboxListTile(
                        title: Text(item['label']),
                        value: item['value'],
                        onChanged: (val) {
                          setState(() {
                            item['value'] = val ?? false;
                          });
                        },
                      );
                    }
                  }),
                  const SizedBox(height: 16),
                ],
                Text('Observations complémentaires', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                TextField(
                  controller: commentaireController,
                  decoration: const InputDecoration(labelText: 'Commentaires libres'),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    // Construction de la checklist à sauvegarder
                    final Map<String, dynamic> checklistResult = {};
                    for (final section in sections.entries) {
                      for (final item in section.value) {
                        checklistResult[item['label']] = item['value'];
                      }
                    }
                    checklistResult['Nombre de sardines/piquets'] = sardinesCountController.text;
                    if (widget.tenteId != null) {
                      try {
                        await ApiService.addControle({
                          'tenteId': widget.tenteId!,
                          'userId': 0, // à remplacer plus tard par l'id utilisateur
                          'date': DateTime.now().toIso8601String(),
                          'checklist': checklistResult,
                          'remarques': commentaireController.text,
                        });
                        // Met à jour l'historique et les remarques de la tente après ajout du contrôle
                        final updatedTenteJson = await ApiService.getTente(widget.tenteId!);
                        final updatedTente = await Tente.fromApiJson(updatedTenteJson);
                        // Met à jour la liste des tentes sur la page précédente après ajout du contrôle
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context, updatedTente);
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erreur lors de l\'ajout du contrôle : $e')),
                        );
                        // Ne pas faire de Navigator.pop ici pour éviter l'erreur !_debugLocked
                      }
                    }
                  },
                  child: const Text('Valider le contrôle'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
