import 'package:flutter/material.dart';
import '../models/models.dart';
import '../models/database_helper.dart';

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
    final data = await DatabaseHelper.instance.getAllEvenements();
    setState(() {
      evenements = data;
      isLoading = false;
    });
  }

  Future<List<int>> _tentesIndisponibles(DateTime debut, DateTime fin, {int? evenementId}) async {
    final evenements = await DatabaseHelper.instance.getAllEvenements();
    List<int> indispo = [];
    for (final evt in evenements) {
      if (evenementId != null && evt.id == evenementId) continue;
      final chevauche =
        (debut.isBefore(evt.dateFin) && fin.isAfter(evt.date));
      if (chevauche) {
        indispo.addAll(evt.tentesAssociees);
      }
    }
    return indispo.toSet().toList();
  }

  Future<void> _ajouterEvenement() async {
    final TextEditingController nomController = TextEditingController();
    String typeRencontre = 'Rencontre';
    DateTime? debut;
    DateTime? fin;
    List<int> materielSelectionne = [];
    final tentes = await DatabaseHelper.instance.getAllTentes();
    List<int> tentesIndisponibles = [];
    final List<String> types = ['Rencontre', 'WE', 'Camp'];
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
                            setStateDialog(() {
                              debut = picked;
                            });
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
                            setStateDialog(() {
                              debut = picked.start;
                              fin = picked.end;
                            });
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
                if (typeRencontre != 'Rencontre' && debut != null && fin != null)
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
                if (nomController.text.isNotEmpty && debut != null && (typeRencontre == 'Rencontre' || fin != null)) {
                  await DatabaseHelper.instance.insertEvenement(
                    Evenement(
                      id: 0,
                      nom: nomController.text,
                      date: debut!,
                      tentesAssociees: materielSelectionne,
                      type: typeRencontre,
                      dateFin: fin ?? debut!,
                    ),
                    fin ?? debut!,
                    materielSelectionne,
                  );
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
    final TextEditingController nomController = TextEditingController(text: evenement.nom);
    final TextEditingController typeController = TextEditingController(text: evenement.type);
    DateTime? debut = evenement.date;
    DateTime? fin = evenement.dateFin;
    List<int> materielSelectionne = List.from(evenement.tentesAssociees);
    final tentes = await DatabaseHelper.instance.getAllTentes();
    List<int> tentesIndisponibles = await _tentesIndisponibles(debut!, fin!, evenementId: evenement.id);
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
                  await DatabaseHelper.instance.deleteEvenement(evenement.id);
                  await DatabaseHelper.instance.insertEvenement(
                    Evenement(
                      id: evenement.id,
                      nom: nomController.text,
                      date: debut!,
                      tentesAssociees: materielSelectionne,
                      type: typeController.text,
                      dateFin: fin!,
                    ),
                    fin!,
                    materielSelectionne,
                  );
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
    await DatabaseHelper.instance.deleteEvenement(id);
    _loadEvenements();
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
                    return ListTile(
                      title: Text(evt.nom),
                      subtitle: Text('Début : ${evt.date.toLocal().toString().split(' ')[0]} | Fin : ${evt.dateFin?.toLocal().toString().split(' ')[0] ?? ''}\nType : ${evt.type ?? ''}\nTentes : ${evt.tentesAssociees.join(', ')}'),
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
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _ajouterEvenement,
        child: const Icon(Icons.add),
        tooltip: 'Ajouter un événement',
      ),
    );
  }
}

