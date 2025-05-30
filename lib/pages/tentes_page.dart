import 'package:flutter/material.dart';
import '../models/models.dart';
import '../models/database_helper.dart';
import 'tente_detail.dart';

class TentesPage extends StatefulWidget {
  const TentesPage({super.key});
  @override
  State<TentesPage> createState() => _TentesPageState();
}

class _TentesPageState extends State<TentesPage> {
  List<Tente> tentes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTentes();
  }

  Future<void> _loadTentes() async {
    final data = await DatabaseHelper.instance.getAllTentes();
    setState(() {
      tentes = data;
      isLoading = false;
    });
  }

  Future<void> _ajouterTente() async {
    final nomController = TextEditingController();
    bool tapisSolIntegre = false;
    String typeTente = 'Canadienne';
    int nbPlaces = 6;
    String unitePreferee = '';
    final List<String> types = ['Canadienne', 'Tipi', 'Autre'];
    // Charger les unités existantes depuis la BDD
    final unites = await DatabaseHelper.instance.getAllUnites();
    final List<String> unitesNoms = unites.map((u) => u.nom).toList();
    if (unitesNoms.isNotEmpty) unitePreferee = unitesNoms.first;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Nouvelle tente'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nomController,
                  decoration: const InputDecoration(labelText: 'Nom de la tente'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: typeTente,
                  items: types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (val) {
                    setStateDialog(() {
                      typeTente = val!;
                      if (typeTente == 'Canadienne') nbPlaces = 6;
                      else if (typeTente == 'Tipi') nbPlaces = 8;
                      else nbPlaces = 0;
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Type de tente'),
                ),
                const SizedBox(height: 8),
                if (typeTente == 'Canadienne')
                  DropdownButtonFormField<int>(
                    value: nbPlaces,
                    items: [6, 8].map((n) => DropdownMenuItem(value: n, child: Text('$n places'))).toList(),
                    onChanged: (val) => setStateDialog(() => nbPlaces = val ?? 6),
                    decoration: const InputDecoration(labelText: 'Nombre de places'),
                  )
                else if (typeTente == 'Tipi')
                  DropdownButtonFormField<int>(
                    value: nbPlaces,
                    items: [8, 10, 12].map((n) => DropdownMenuItem(value: n, child: Text('$n places'))).toList(),
                    onChanged: (val) => setStateDialog(() => nbPlaces = val ?? 8),
                    decoration: const InputDecoration(labelText: 'Nombre de places'),
                  )
                else
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Nombre de places'),
                    onChanged: (val) => nbPlaces = int.tryParse(val) ?? 0,
                  ),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: tapisSolIntegre,
                  onChanged: (val) => setStateDialog(() => tapisSolIntegre = val),
                  title: const Text('Tapis de sol intégré'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: unitePreferee.isNotEmpty ? unitePreferee : null,
                  items: unitesNoms.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                  onChanged: (val) => setStateDialog(() => unitePreferee = val ?? ''),
                  decoration: const InputDecoration(labelText: 'Unité préférée'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
    if (result == true && nomController.text.isNotEmpty) {
      await DatabaseHelper.instance.insertTente(Tente(
        id: 0,
        nom: nomController.text,
        uniteId: null,
        etat: 'Bon',
        remarques: '',
        agenda: [],
        historiqueControles: [],
        tapisSolIntegre: tapisSolIntegre,
        nbPlaces: nbPlaces,
        typeTente: typeTente,
        unitePreferee: unitePreferee,
      ));
      await _loadTentes();
    }
  }

  Future<void> _supprimerTente(int id) async {
    await DatabaseHelper.instance.deleteTente(id);
    _loadTentes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tentes')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : tentes.isEmpty
              ? const Center(child: Text('Aucune tente enregistrée.'))
              : ListView.builder(
                  itemCount: tentes.length,
                  itemBuilder: (context, index) {
                    final tente = tentes[index];
                    return ListTile(
                      title: Text(tente.nom),
                      subtitle: Text('État: \'${tente.etat}\' | Unité: \'${tente.uniteId ?? "Non affectée"}\''),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Supprimer la tente'),
                                  content: Text('Supprimer ${tente.nom} ?'),
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
                                _supprimerTente(tente.id);
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TenteDetailPage(tente: tente),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _ajouterTente,
        child: const Icon(Icons.add),
        tooltip: 'Ajouter une tente',
      ),
    );
  }
}

