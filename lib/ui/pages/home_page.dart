import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logistiscout/domain/entities/event.dart';
import 'package:logistiscout/domain/entities/tente.dart';
import 'package:logistiscout/services/local_storage_service.dart';
import 'package:logistiscout/ui/controllers/home_controller.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(accueilControllerProvider);
    final controller = ref.read(accueilControllerProvider.notifier);

    if (state.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (state.error != null) {
      return Scaffold(body: Center(child: Text('Erreur: ${state.error}')));
    }

    final evtsAVenir = [...state.evenements]..sort((a, b) => a.date.compareTo(b.date));
    final now = DateTime.now();
    final prochainsEvts = evtsAVenir.where((e) => e.date.isAfter(now)).take(3).toList();

    final tentesUtiliseesIds = prochainsEvts.expand((e) => e.tentesAssociees).toSet();
    final tentesUtilisees = state.tentes.where((t) => tentesUtiliseesIds.contains(t.id)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accueil'),
        actions: [
          // 🧹 Bouton pour vider les SharedPreferences
          IconButton(
            icon: const Icon(Icons.cleaning_services_outlined),
            tooltip: 'Vider les préférences locales',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Réinitialiser ?'),
                  content: const Text(
                      'Cela va effacer vos données locales (nom du contrôleur, groupe, etc.). Continuer ?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Annuler'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Confirmer'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await LocalStorageService.instance.clearAll();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Préférences locales effacées ✅')),
                  );
                }
              }
            },
          ),

          // 🚪 Bouton de déconnexion
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: () async {
              await controller.logout(ref);
              if (context.mounted) {
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
            Text('Prochains événements',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (prochainsEvts.isEmpty)
              const Text('Aucun événement à venir.')
            else
              ...prochainsEvts.map((e) => _buildEvenementCard(e)),

            const SizedBox(height: 24),
            Text('Tentes utilisées prochainement',
                style: Theme.of(context).textTheme.titleLarge),
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

  Widget _buildEvenementCard(Event e) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.event),
        title: Text(e.nom),
        subtitle: Text(
          'Du ${e.date.toLocal()} au ${e.dateFin.toLocal()} - Type : ${e.type}',
        ),
      ),
    );
  }

  Widget buildTenteCard(Tente tente) {
    return Card(
      child: ListTile(
        title: Text(tente.nom),
        subtitle: Text('Unité : ${tente.unitePreferee}'),
      ),
    );
  }
}
