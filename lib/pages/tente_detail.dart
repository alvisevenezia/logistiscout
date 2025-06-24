import 'package:flutter/material.dart';
import 'package:logistiscout/models/api_service.dart';
import 'package:logistiscout/pages/controle_detail.dart';
import 'package:logistiscout/pages/controle_edit_page.dart';
import 'package:logistiscout/pages/controle_saisie_nom_page.dart';
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

  Color _parseColor(String color) {
    try {
      return Color(int.parse(color.replaceFirst('#', '0xff')));
    } catch (e) {
      return Colors.transparent;
    }
  }

  Color _colorForUnite(String unite) {
    switch (unite) {
      case 'Farfadet':
        return Colors.greenAccent;
      case 'Louveteaux-Jeannettes':
        return Colors.yellow[700]!;
      case 'Scout-Guide':
        return Colors.blue;
      case 'Pionnier-Caravelle':
        return Colors.red;
      case 'Compagnon':
        return Colors.green.shade900;
      default:
        return Colors.black;
    }
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
            // Affichage des infos principales
            Row(
              children: [
                const Text('Nom : '),
                Text(
                  tente!.nom,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: _colorForUnite(tente!.unitePreferee),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Capacité : ${tente!.nbPlaces} places'),
            const SizedBox(height: 8),
            Text('État : ${tente!.etat}'),
            const SizedBox(height: 8),
            Text('Type : ${tente!.typeTente}'),
            const SizedBox(height: 8),
            Text('Tapis de sol intégré : ${tente!.tapisSolIntegre ? 'Oui' : 'Non'}'),
            const SizedBox(height: 8),
            // Couleurs
            if (tente!.couleurs.isNotEmpty)
              Row(
                children: [
                  const Text('Couleurs : '),
                  ...tente!.couleurs.map((c) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: _parseColor(c),
                          border: Border.all(),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      )),
                ],
              ),
            const SizedBox(height: 8),
            // Dernier contrôle
            if (tente!.historiqueControles.isNotEmpty) ...[
              Text(
                'Dernière remarque : '
                '${tente!.remarques.isNotEmpty ? tente!.remarques : 'Aucune'}'
              ),
              const SizedBox(height: 8),
              Text(
                'Nombre de sardines (dernier contrôle) : '
                '${tente!.historiqueControles.last.checklist['Nombre de sardines/piquets'] ?? tente!.historiqueControles.last.checklist['sardines'] ?? 'Non renseigné'}'
              ),
              const SizedBox(height: 8),
              // Alerte si une case n'est pas cochée
              if (tente!.historiqueControles.last.checklist.values.any((v) => v == false || v == null))
                Row(
                  children: const [
                    Icon(Icons.warning, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Attention : contrôle incomplet', style: TextStyle(color: Colors.red)),
                  ],
                ),
              const SizedBox(height: 8),
              // Card vers le dernier contrôle
              Card(
                color: Colors.blue.shade50,
                child: ListTile(
                  leading: const Icon(Icons.assignment_turned_in),
                  title: const Text('Voir le dernier contrôle'),
                  subtitle: Text('Effectué le '
                    '${tente!.historiqueControles.last.date.day}/'
                    '${tente!.historiqueControles.last.date.month}/'
                    '${tente!.historiqueControles.last.date.year}'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ControleDetailPage(
                          controle: tente!.historiqueControles.last,
                          tente: tente,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const Divider(),
            ListTile(
              title: const Text('Remarques'),
              subtitle: TextFormField(
                initialValue: tente!.remarques,
                maxLines: 2,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) => setState(() => tente = tente!.copyWith(remarques: val)),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Enregistrer les remarques'),
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
                    const SnackBar(content: Text('Remarques enregistrées !')),
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
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ControleSaisieNomPage(
                      onNomValide: (nomControleur) async {
                        final result = await Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) => ControleEditPage(tente: tente!, nomControleur: nomControleur),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                          ),
                        );
                        if (result == true) {
                          await _refreshTente();
                        }
                      },
                    ),
                  ),
                );
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
                  if (explications[section.key] != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text(
                        explications[section.key]!,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
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
