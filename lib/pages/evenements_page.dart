import 'package:flutter/material.dart';
import 'package:logistiscout/models/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class EvenementsPage extends StatefulWidget {
  const EvenementsPage({super.key});
  @override
  State<EvenementsPage> createState() => _EvenementsPageState();
}

class _EvenementsPageState extends State<EvenementsPage> {
  List<Evenement> evenements = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvenements();
  }

  Future<void> _loadEvenements() async {
    final prefs = await SharedPreferences.getInstance();
    final String groupeId = prefs.getString('groupeId') ?? '';
    final dataApi = await ApiService.getEvenements(groupeId);
    final data = dataApi.map((e) => Evenement.fromJson(e)).toList();
    setState(() {
      evenements = data;
      isLoading = false;
    });
  }

  Future<List<int>> _tentesIndisponibles(DateTime debut, DateTime fin, {int? evenementId}) async {
    final prefs = await SharedPreferences.getInstance();
    final String groupeId = prefs.getString('groupeId') ?? '';
    final evenements = await ApiService.getEvenementsParPeriode(groupeId, debut, fin);
    List<int> indispo = [];
    for (final evt in evenements) {
      if (evenementId != null && evt['id'] == evenementId) continue;
      final evtDebut = DateTime.parse(evt['date']);
      final evtFin = DateTime.parse(evt['dateFin'] ?? evt['date']);
      final chevauche = (debut.isBefore(evtFin) && fin.isAfter(evtDebut));
      if (chevauche) {
        if (evt['tentesAssociees'] != null) {
          indispo.addAll(List<int>.from(evt['tentesAssociees']));
        }
      }
    }
    return indispo.toSet().toList();
  }

  Future<void> _ajouterEvenement() async {
    final prefs = await SharedPreferences.getInstance();
    final String groupeId = prefs.getString('groupeId') ?? '';
    final TextEditingController nomController = TextEditingController();
    String typeRencontre = 'Rencontre';
    DateTime? debut;
    DateTime? fin;
    List<int> materielSelectionne = [];
    final tentesApi = await ApiService.getTentes(groupeId);
    final tentes = tentesApi.map((t) => Tente.fromJson(t)).toList();
    List<int> tentesIndisponibles = [];
    final List<String> types = ['Rencontre', 'WE', 'Camp'];

    // Liste des unités hardcodée
    final unites = [
      {'id': 1, 'nom': 'Farfadet'},
      {'id': 2, 'nom': 'Louveteau/Jeannette'},
      {'id': 3, 'nom': 'Scout/Guide'},
      {'id': 4, 'nom': 'Pionnier/Caravelle'},
      {'id': 5, 'nom': 'Compagnon'},
      {'id': 6, 'nom': 'Groupe'},
    ];
    List<int> unitesSelectionnees = [];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Nouvel événement'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nomController,
                  decoration: const InputDecoration(labelText: "Nom de l'événement"),
                ),
                DropdownButtonFormField<String>(
                  value: typeRencontre,
                  items: types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (val) {
                    setStateDialog(() {
                      typeRencontre = val!;
                      debut = null;
                      fin = null;
                      materielSelectionne.clear();
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Type de rencontre'),
                ),
                const SizedBox(height: 8),
                // Sélection de la date ou de la plage de dates selon le type
                if (typeRencontre == 'Rencontre')
                  Row(
                    children: [
                      const Text('Date :'),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            debut = picked;
                            fin = picked;
                            tentesIndisponibles = await _tentesIndisponibles(debut!, fin!);
                            setStateDialog(() {});
                          }
                        },
                        child: Text(debut == null ? 'Choisir' : debut!.toLocal().toString().split(' ')[0]),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      const Text('Début/Fin :'),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                            initialDateRange: (debut != null && fin != null)
                                ? DateTimeRange(start: debut!, end: fin!)
                                : null,
                          );
                          if (picked != null) {
                            debut = picked.start;
                            fin = picked.end;
                            tentesIndisponibles = await _tentesIndisponibles(debut!, fin!);
                            setStateDialog(() {});
                          }
                        },
                        child: Text((debut == null || fin == null)
                            ? 'Choisir'
                            : '${debut!.toLocal().toString().split(' ')[0]} → ${fin!.toLocal().toString().split(' ')[0]}'),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                if (debut != null && fin != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Matériel nécessaire :'),
                      ...tentes.map((m) => CheckboxListTile(
                            value: materielSelectionne.contains(m.id),
                            onChanged: tentesIndisponibles.contains(m.id)
                                ? null
                                : (val) {
                                    setStateDialog(() {
                                      if (val == true) {
                                        materielSelectionne.add(m.id);
                                      } else {
                                        materielSelectionne.remove(m.id);
                                      }
                                    });
                                  },
                            title: Row(
                              children: [
                                Text(m.nom),
                                if (tentesIndisponibles.contains(m.id))
                                  const Padding(
                                    padding: EdgeInsets.only(left: 8),
                                    child: Icon(Icons.block, color: Colors.red, size: 18),
                                  ),
                              ],
                            ),
                            subtitle: tentesIndisponibles.contains(m.id)
                                ? const Text('Indisponible sur cette période', style: TextStyle(color: Colors.red, fontSize: 12))
                                : null,
                          )),
                    ],
                  ),
                const SizedBox(height: 8),
                const Text('Unité concernée :'),
                DropdownButtonFormField<int>(
                  value: unitesSelectionnees.isNotEmpty ? unitesSelectionnees.first : null,
                  items: unites.map((u) => DropdownMenuItem(
                    value: u['id'] as int,
                    child: Text(u['nom'].toString()),
                  )).toList(),
                  onChanged: (val) {
                    setStateDialog(() {
                      unitesSelectionnees = val != null ? [val] : [];
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Unité'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nomController.text.isNotEmpty && debut != null && fin != null) {
                  final evenementMap = {
                    'nom': nomController.text,
                    'date': debut!.toIso8601String(),
                    'dateFin': fin!.toIso8601String(),
                    'type': typeRencontre,
                    'tentesAssociees': materielSelectionne,
                    'unites': unitesSelectionnees,
                    'groupeId': groupeId,
                  };
                  await ApiService.addEvenement(evenementMap);
                  await _loadEvenements();
                  Navigator.pop(context);
                }
              },
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _modifierEvenement(Evenement evenement) async {
    final prefs = await SharedPreferences.getInstance();
    final String groupeId = prefs.getString('groupeId') ?? '';
    final TextEditingController nomController = TextEditingController(text: evenement.nom);
    final TextEditingController typeController = TextEditingController(text: evenement.type);
    DateTime? debut = evenement.date;
    DateTime? fin = evenement.dateFin;
    List<int> materielSelectionne = List.from(evenement.tentesAssociees);
    final tentesApi = await ApiService.getTentes(groupeId);
    final tentes = tentesApi.map((t) => Tente.fromJson(t)).toList();
    List<int> tentesIndisponibles = await _tentesIndisponibles(debut, fin, evenementId: evenement.id);

    // Liste des unités hardcodée
    final unites = [
      {'id': 1, 'nom': 'Farfadet'},
      {'id': 2, 'nom': 'Louveteau/Jeannette'},
      {'id': 3, 'nom': 'Scout/Guide'},
      {'id': 4, 'nom': 'Pionnier/Caravelle'},
      {'id': 5, 'nom': 'Compagnon'},
      {'id': 6, 'nom': 'Groupe'},
    ];
    List<int> unitesSelectionnees = List.from(evenement.unites);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Modifier l\'événement'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nomController,
                  decoration: const InputDecoration(labelText: "Nom de l'événement"),
                ),
                TextField(
                  controller: typeController,
                  decoration: const InputDecoration(labelText: "Type de rencontre"),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Début :'),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: debut ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setStateDialog(() async {
                            debut = picked;
                            tentesIndisponibles = await _tentesIndisponibles(debut!, fin!, evenementId: evenement.id);
                          });
                        }
                      },
                      child: Text(debut == null ? 'Choisir' : debut!.toLocal().toString().split(' ')[0]),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text('Fin :'),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: fin ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setStateDialog(() async {
                            fin = picked;
                            tentesIndisponibles = await _tentesIndisponibles(debut!, fin!, evenementId: evenement.id);
                          });
                        }
                      },
                      child: Text(fin == null ? 'Choisir' : fin!.toLocal().toString().split(' ')[0]),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Matériel nécessaire :'),
                ...tentes.map((m) => CheckboxListTile(
                      value: materielSelectionne.contains(m.id),
                      onChanged: tentesIndisponibles.contains(m.id)
                          ? null
                          : (val) {
                              setStateDialog(() {
                                if (val == true) {
                                  materielSelectionne.add(m.id);
                                } else {
                                  materielSelectionne.remove(m.id);
                                }
                              });
                            },
                      title: Row(
                        children: [
                          Text(m.nom),
                          if (tentesIndisponibles.contains(m.id))
                            const Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: Icon(Icons.block, color: Colors.red, size: 18),
                            ),
                        ],
                      ),
                      subtitle: tentesIndisponibles.contains(m.id)
                          ? const Text('Indisponible sur cette période', style: TextStyle(color: Colors.red, fontSize: 12))
                          : null,
                    )),
                const SizedBox(height: 8),
                const Text('Unité concernée :'),
                DropdownButtonFormField<int>(
                  value: unitesSelectionnees.isNotEmpty ? unitesSelectionnees.first : null,
                  items: unites.map((u) => DropdownMenuItem(
                    value: u['id'] as int,
                    child: Text(u['nom'].toString()),
                  )).toList(),
                  onChanged: (val) {
                    setStateDialog(() {
                      unitesSelectionnees = val != null ? [val] : [];
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Unité'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nomController.text.isNotEmpty && debut != null && fin != null) {
                  final evenementMap = {
                    'nom': nomController.text,
                    'date': debut!.toIso8601String(),
                    'dateFin': fin!.toIso8601String(),
                    'type': typeController.text,
                    'tentesAssociees': materielSelectionne,
                    'unites': unitesSelectionnees,
                    'groupeId': groupeId,
                  };
                  await ApiService.updateEvenement(evenement.id, evenementMap);
                  await _loadEvenements();
                  Navigator.pop(context);
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _supprimerEvenement(int id) async {
    await ApiService.deleteEvenement(id);
    await _loadEvenements();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Événements')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : evenements.isEmpty
              ? const Center(child: Text('Aucun événement enregistré.'))
              : ListView.builder(
                  itemCount: evenements.length,
                  itemBuilder: (context, index) {
                    final evt = evenements[index];
                    // Couleurs par unité principale
                    final Map<int, Color> uniteColors = {
                      1: Colors.greenAccent.shade200, // Farfadet
                      2: Colors.orange.shade600, // Louveteau/Jeannette
                      3: Colors.blue.shade600,   // Scout/Guide
                      4: Colors.red.shade600,    // Pionnier/Caravelle
                      5: Colors.green.shade600,  // Compagnon
                      6: Colors.deepPurple.shade600,   // Chef/Groupe
                    };
                    final int uniteId = (evt.unites.isNotEmpty) ? evt.unites.first : 6;
                    final Color cardColor = uniteColors[uniteId] ?? Colors.grey.shade100;
                    return Card(
                      color: cardColor,
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      elevation: 3,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        title: Text(evt.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Début : 	${evt.date.toLocal().toString().split(' ')[0]}'),
                            Text('Fin : 	${evt.dateFin.toLocal().toString().split(' ')[0]}'),
                            Text('Type : ${evt.type}'),
                            Text('Tentes : ${evt.tentesAssociees.join(', ')}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _modifierEvenement(evt),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Supprimer l\'événement'),
                                    content: Text('Supprimer ${evt.nom} ?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Annuler'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text('Supprimer'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  _supprimerEvenement(evt.id);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _ajouterEvenement,
        tooltip: 'Ajouter un événement',
        child: const Icon(Icons.add),
      ),
    );
  }
}

