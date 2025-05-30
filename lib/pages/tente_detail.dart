import 'package:flutter/material.dart';
import '../models/models.dart';
import '../models/database_helper.dart';

class TenteDetailPage extends StatelessWidget {
  final Tente tente;
  const TenteDetailPage({super.key, required this.tente});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Détail - ${tente.nom}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.assignment_turned_in),
            tooltip: 'Contrôle',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) => ControleChecklistSheet(tenteId: tente.id),
              );
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
            Text('Unité : ${tente.uniteId != null ? tente.uniteId.toString() : "Non affectée"}'),
            const SizedBox(height: 8),
            Text('État : ${tente.etat}'),
            const SizedBox(height: 8),
            Text('Remarques : ${tente.remarques}'),
            const SizedBox(height: 16),
            Text('Historique des contrôles :', style: Theme.of(context).textTheme.titleMedium),
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
                    await DatabaseHelper.instance.insertControle(
                      Controle(
                        id: 0,
                        tenteId: widget.tenteId!,
                        userId: 0, // à remplacer plus tard par l'id utilisateur
                        date: DateTime.now(),
                        checklist: checklistResult,
                        remarques: commentaireController.text,
                      ),
                    );
                  }
                  Navigator.pop(context);
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

