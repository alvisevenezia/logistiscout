import 'package:flutter/material.dart';
import '../models/models.dart';
import '../models/database_helper.dart';

class UnitesPage extends StatefulWidget {
  const UnitesPage({super.key});
  @override
  State<UnitesPage> createState() => _UnitesPageState();
}

class _UnitesPageState extends State<UnitesPage> {
  final unites = [
    {'id': 1, 'nom': 'Farfadet'},
    {'id': 2, 'nom': 'Louveteau/Jeannette'},
    {'id': 3, 'nom': 'Scout/Guide'},
    {'id': 4, 'nom': 'Pionnier/Caravelle'},
    {'id': 5, 'nom': 'Compagnon'},
    {'id': 6, 'nom': 'Groupe'},
  ];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    isLoading = false;
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
                      title: Text(unite["nom"] as String),
                    );
                  },
                ),
    );
  }
}

