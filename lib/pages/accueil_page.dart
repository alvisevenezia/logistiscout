import 'package:flutter/material.dart';
import 'package:logistiscout/models/api_service.dart';
import 'package:logistiscout/models/database_helper.dart';
import '../models/models.dart';
import '../models/api_service.dart';

class AccueilPage extends StatefulWidget {
  const AccueilPage({super.key});
  @override
  State<AccueilPage> createState() => _AccueilPageState();
}

class _AccueilPageState extends State<AccueilPage> {
  List<Evenement> evenements = [];
  List<Tente> tentes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final String groupeId = "1"; // À adapter selon ton contexte
    final evtsApi = await ApiService.getEvenements(groupeId);
    final ttsApi = await ApiService.getTentes(groupeId);
    final evts = evtsApi.map((e) => Evenement.fromJson(e)).toList();
    final tts = ttsApi.map((t) => Tente.fromJson(t)).toList();
    setState(() {
      evenements = evts;
      tentes = tts;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    // Prochains événements (triés par date)
    final prochainsEvts = [...evenements]..sort((a, b) => a.date.compareTo(b.date));
    final now = DateTime.now();
    final evtsAVenir = prochainsEvts.where((e) => e.date.isAfter(now)).take(3).toList();
    // Tentes utilisées dans les prochains événements
    final tentesUtiliseesIds = evtsAVenir.expand((e) => e.tentesAssociees).toSet();
    final tentesUtilisees = tentes.where((t) => tentesUtiliseesIds.contains(t.id)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accueil'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Prochains événements', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (evtsAVenir.isEmpty)
              const Text('Aucun événement à venir.')
            else
              ...evtsAVenir.map((e) => Card(
                    child: ListTile(
                      title: Text(e.nom),
                      subtitle: Text('Du ${e.date.toLocal().toString().split(' ')[0]} au ${e.dateFin.toLocal().toString().split(' ')[0]}\nType : ${e.type}'),
                    ),
                  )),
            const SizedBox(height: 24),
            Text('Tentes utilisées prochainement', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (tentesUtilisees.isEmpty)
              const Text('Aucune tente réservée pour les prochains événements.')
            else
              ...tentesUtilisees.map((t) => Card(
                    child: ListTile(
                      title: Text(t.nom),
                      subtitle: Text('Type : ${t.typeTente} | Unité préférée : ${t.unitePreferee}'),
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}

