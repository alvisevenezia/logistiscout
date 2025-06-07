import 'package:flutter/material.dart';
import 'package:logistiscout/models/api_service.dart';
import '../models/models.dart';
import '../models/database_helper.dart';

class TenteDetailPage extends StatefulWidget {
  final Tente tente;
  const TenteDetailPage({super.key, required this.tente});

  @override
  State<TenteDetailPage> createState() => _TenteDetailPageState();
}

class _TenteDetailPageState extends State<TenteDetailPage> {
  late String etat;
  late String remarques;
  late String unite;
  late Tente tente;

  @override
  void initState() {
    super.initState();
    tente = widget.tente;
    _updateFromTente();
  }

  void _updateFromTente() {
    etat = tente.etat;
    unite = tente.unitePreferee.isNotEmpty ? tente.unitePreferee : "Non affectée";
    if (tente.historiqueControles.isNotEmpty) {
      remarques = tente.historiqueControles.last.remarques;
    } else {
      remarques = tente.remarques;
    }
  }

  Future<void> _refreshTente() async {
    final updated = await ApiService.getTente(tente.id);
    setState(() {
      tente = Tente.fromJson(updated);
      _updateFromTente();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Détail - ${tente.nom}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.assignment_turned_in),
            tooltip: 'Contrôle',
            onPressed: () async {
              final result = await showModalBottomSheet<Tente>(
                context: context,
                isScrollControlled: true,
                builder: (context) => ControleChecklistSheet(tenteId: tente.id),
              );
              if (result != null) {
                setState(() {
                  tente = result;
                  _updateFromTente();
                });
              } else {
                await _refreshTente();
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nom : ${tente.nom}', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Unité : $unite'),
            const SizedBox(height: 8),
            Text('État : $etat'),
            const SizedBox(height: 8),
            Text('Tapis de sol intégrée : ${tente.tapisSolIntegre ? "Oui" : "Non"}'),
            const SizedBox(height: 8),
            Text('Remarques : $remarques'),
            const SizedBox(height: 16),
            Text('Historique des contrôles :', style: Theme.of(context).textTheme.titleMedium),
            if (tente.historiqueControles.isNotEmpty) ...[
              Card(
                color: Colors.blue.shade50,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  title: Text('Dernier contrôle du '
                      '${tente.historiqueControles.last.date.toLocal().toString().split(' ')[0]}'),
                  subtitle: Text('Remarques : '
                      '${tente.historiqueControles.last.remarques ?? "Aucune remarque"}'),
                ),
              ),
            ],
            Expanded(
              child: tente.historiqueControles.isEmpty
                  ? const Text('Aucun contrôle enregistré.')
                  : ListView.builder(
                      itemCount: tente.historiqueControles.length,
                      itemBuilder: (context, index) {
                        final controle = tente.historiqueControles[index];
                        return ListTile(
                          title: Text('Contrôle du ${controle.date.toLocal().toString().split(' ')[0]}'),
                          subtitle: Text('Remarques : ${controle.remarques}\nContrôlé par utilisateur ${controle.userId}'),
                        );
                      },
                    ),
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
    return DraggableScrollableSheet(
      expand: false,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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
                      Navigator.pop(context, updatedTente);
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
    );
  }
}

