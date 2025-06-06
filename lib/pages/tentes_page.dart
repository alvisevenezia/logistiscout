import 'package:flutter/material.dart';
import '../models/models.dart';
import '../models/database_helper.dart';
import '../models/api_service.dart';
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
    final groupeId = 'test'; // À remplacer par l'id du groupe courant (SharedPreferences)
    final data = await ApiService.getTentes(groupeId);
    final futures = data.map<Future<Tente>>((json) => Tente.fromApiJson(json)).toList();
    final loadedTentes = await Future.wait(futures);
    setState(() {
      tentes = loadedTentes;
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
    // Liste fixe des unités SGDF
    final List<String> unitesNoms = [
      'Farfadet',
      'Louveteaux-Jeannettes',
      'Scout-Guide',
      'Pionnier-Caravelle',
      'Compagnon',
    ];
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
      await ApiService.addTente({
        'nom': nomController.text,
        'uniteId': null,
        'etat': 'Bon',
        'remarques': '',
        'tapisSolIntegre': tapisSolIntegre,
        'nbPlaces': nbPlaces,
        'typeTente': typeTente,
        'unitePreferee': unitePreferee,
      });
      await _loadTentes();
    }
  }

  Future<void> _supprimerTente(int id) async {
    await ApiService.deleteTente(id);
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
                    final Color etatColor;
                    switch (tente.etat.toLowerCase()) {
                      case 'bon':
                        etatColor = Colors.green.shade100;
                        break;
                      case 'moyen':
                        etatColor = Colors.orange.shade100;
                        break;
                      case 'mauvais':
                        etatColor = Colors.red.shade100;
                        break;
                      default:
                        etatColor = Colors.grey.shade200;
                    }
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      color: etatColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.blue.shade100, width: 1),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: const Icon(Icons.cabin, color: Color(0xFF003a5d)),
                        ),
                        title: Text(
                          tente.nom,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('État : ${tente.etat}', style: const TextStyle(fontSize: 14)),
                            Text('Unité : ${tente.unitePreferee ?? "Non affectée"}', style: const TextStyle(fontSize: 13)),
                            if (tente.historiqueControles.isNotEmpty)
                              Text('Dernier contrôle : ${tente.historiqueControles.last.date.toLocal().toString().split(' ')[0]}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TenteDetailPage(tente: tente),
                            ),
                          );
                        },
                        trailing: IconButton(
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

