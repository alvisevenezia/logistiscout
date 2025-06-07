import 'package:flutter/material.dart';
import 'package:logistiscout/models/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

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
    final prefs = await SharedPreferences.getInstance();
    final String groupeId = prefs.getString('groupeId') ?? '';
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
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('groupe_id');
              await prefs.remove('groupe_mdp');
              await prefs.remove('groupeId');
              await prefs.remove('token');
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
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
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        color: _getUniteColor(e.unites.isNotEmpty ? e.unites.first : null),
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getUniteColor(e.unites.isNotEmpty ? e.unites.first : null),
                        child: const Icon(Icons.groups, color: Colors.white),
                      ),
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
              ...tentesUtilisees.map((t) => buildTenteCard(t)),
          ],
        ),
      ),
    );
  }

  Widget buildTenteCard(Tente tente) {
    // Couleurs d'unité (à adapter selon ta logique)
    final Map<String, Color> uniteColors = {
      'Farfadet': Colors.greenAccent.shade200,
      'Louveteaux-Jeannettes': Colors.orange.shade600,
      'Scout-Guide': Colors.blue.shade600,
      'Pionnier-Caravelle': Colors.red.shade600,
      'Compagnon': Colors.green.shade600,
    };
    final Color uniteColor = uniteColors[tente.unitePreferee] ?? Colors.grey.shade200;
    // Couleur principale de la tente (première couleur de la liste)
    final Color tenteColor = tente.couleurs.isNotEmpty ? _parseColor(tente.couleurs.first) : Colors.grey.shade400;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 3,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: uniteColor, width: 3), // Bordure couleur unité
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              leading: CircleAvatar(
                backgroundColor: tenteColor,
                child: const Icon(Icons.cabin, color: Colors.white),
              ),
              title: Text(tente.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Unité : ${tente.unitePreferee}'),
            ),
          ),
          // Affichage des rectangles de couleur de la tente en haut à droite
          if (tente.couleurs.isNotEmpty)
            Positioned(
              top: 10,
              right: 18,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: tente.couleurs.take(5).map<Widget>((couleur) => Container(
                  width: 18,
                  height: 10,
                  margin: const EdgeInsets.only(left: 2),
                  decoration: BoxDecoration(
                    color: _parseColor(couleur),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                )).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Color _parseColor(String couleur) {
    try {
      if (couleur.startsWith('#')) {
        return Color(int.parse(couleur.substring(1), radix: 16) + 0xFF000000);
      }
      switch (couleur.toLowerCase()) {
        case 'rouge':
          return Colors.red;
        case 'vert':
          return Colors.green;
        case 'bleu':
          return Colors.blue;
        case 'jaune':
          return Colors.yellow;
        case 'orange':
          return Colors.orange;
        case 'violet':
          return Colors.purple;
        case 'noir':
          return Colors.black;
        case 'blanc':
          return Colors.white;
        case 'gris':
          return Colors.grey;
        default:
          return Colors.grey.shade400;
      }
    } catch (e) {
      return Colors.grey.shade400;
    }
  }

  Color _getUniteColor(int? uniteId) {
    switch (uniteId) {
      case 1:
        return Colors.greenAccent.shade200; // Farfadet
      case 2:
        return Colors.orange.shade600; // Louveteaux-Jeannettes
      case 3:
        return Colors.blue.shade600; // Scout-Guide
      case 4:
        return Colors.red.shade600; // Pionnier-Caravelle
      case 5:
        return Colors.green.shade600; // Compagnon
      case 6:
        return Colors.deepPurple.shade600; // Groupe
      default:
        return Colors.grey.shade300;
    }
  }
}

