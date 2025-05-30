import 'package:flutter/material.dart';
import '../models/models.dart';
import '../models/database_helper.dart';

class UnitesPage extends StatefulWidget {
  const UnitesPage({super.key});
  @override
  State<UnitesPage> createState() => _UnitesPageState();
}

class _UnitesPageState extends State<UnitesPage> {
  List<Unite> unites = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUnites();
  }

  Future<void> _loadUnites() async {
    final data = await DatabaseHelper.instance.getAllUnites();
    setState(() {
      unites = data;
      isLoading = false;
    });
  }

  Future<void> _ajouterUnite() async {
    final TextEditingController nomController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouvelle unité'),
        content: TextField(
          controller: nomController,
          decoration: const InputDecoration(labelText: 'Nom de l\'unité'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, nomController.text),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await DatabaseHelper.instance.insertUnite(Unite(
        id: 0,
        nom: result,
        tentesIds: [],
      ));
      await _loadUnites();
    }
  }

  Future<void> _supprimerUnite(int id) async {
    await DatabaseHelper.instance.deleteUnite(id);
    _loadUnites();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Unités')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : unites.isEmpty
              ? const Center(child: Text('Aucune unité enregistrée.'))
              : ListView.builder(
                  itemCount: unites.length,
                  itemBuilder: (context, index) {
                    final unite = unites[index];
                    return ListTile(
                      title: Text(unite.nom),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Supprimer l\'unité'),
                              content: Text('Supprimer ${unite.nom} ?'),
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
                            _supprimerUnite(unite.id);
                          }
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _ajouterUnite,
        child: const Icon(Icons.add),
        tooltip: 'Ajouter une unité',
      ),
    );
  }
}

