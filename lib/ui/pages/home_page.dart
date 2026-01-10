import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logistiscout/domain/entities/event.dart';
import 'package:logistiscout/domain/entities/tente.dart';
import 'package:logistiscout/services/local_storage_service.dart';
import 'package:logistiscout/services/token_store.dart';
import 'package:logistiscout/ui/controllers/home_controller.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(accueilControllerProvider);
    final controller = ref.read(accueilControllerProvider.notifier);

    // Compute lists only when data is present
    final now = DateTime.now();
    final evtsAVenir = [...state.evenements]..sort((a, b) => a.date.compareTo(b.date));
    final prochainsEvts = evtsAVenir.where((e) => e.date.isAfter(now)).take(3).toList();

    final tentesUtiliseesIds = prochainsEvts.expand((e) => e.associatedTents).toSet();
    final tentesUtilisees = state.tentes.where((t) => tentesUtiliseesIds.contains(t.id)).toList();
    final tentesToRepair = state.tentes.where((t) => t.state != TentState.good).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accueil'),
        bottom: state.isLoading
            ? const PreferredSize(
          preferredSize: Size.fromHeight(4),
          child: LinearProgressIndicator(),
        )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services_outlined),
            tooltip: 'Vider les préférences locales',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Réinitialiser ?'),
                  content: const Text(
                    'Cela va effacer vos données locales (nom du contrôleur, groupe, etc.). Continuer ?',
                  ),
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
                await TokenStore.instance.clear();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Préférences locales effacées ✅')),
                  );
                }
              }
            },
          ),

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

      // ✅ Body always exists; we switch content inside it
      body: Stack(
        children: [
          // Main content area
          _HomeBody(
            isLoading: state.isLoading,
            error: state.error,
            isOffline: state.isOffline,
            hasData: state.evenements.isNotEmpty || state.tentes.isNotEmpty,
            prochainsEvts: prochainsEvts,
            tentesUtilisees: tentesUtilisees,
            tentesToRepair: tentesToRepair,
            onRetry: () => controller.refresh(ref), // add this method in controller
          ),

          // Optional: loading overlay (keeps content visible underneath)
          if (state.isLoading)
            const Positioned.fill(
              child: IgnorePointer(
                ignoring: true, // user can still scroll/click logout in AppBar
                child: DecoratedBox(
                  decoration: BoxDecoration(color: Color(0x33FFFFFF)),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
        ],
      ),
    );
  }

}

class _HomeBody extends StatelessWidget {
  const _HomeBody({
    required this.isLoading,
    required this.error,
    required this.isOffline,
    required this.hasData,
    required this.prochainsEvts,
    required this.tentesUtilisees,
    required this.tentesToRepair,
    required this.onRetry,
  });

  final bool isLoading;
  final String? error;
  final bool isOffline;
  final bool hasData;

  final List<Event> prochainsEvts;
  final List<Tent> tentesUtilisees;
  final List<Tent> tentesToRepair;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    // If there's an error AND no data at all => full error UI
    if (error != null && !hasData) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Erreur: $error', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    // Otherwise: show content, and if offline/error => show banner on top
    return Column(
      children: [
        if (isOffline)
          MaterialBanner(
            content: const Text('Hors connexion — affichage des dernières données'),
            actions: [
              TextButton(onPressed: onRetry, child: const Text('Réessayer')),
            ],
          )
        else if (error != null)
          MaterialBanner(
            content: Text('Erreur: $error'),
            actions: [
              TextButton(onPressed: onRetry, child: const Text('Réessayer')),
            ],
          ),

        Expanded(
          child: SingleChildScrollView(
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
                  ...prochainsEvts.map((e) => _HomeBody.evenementCard(e)),

                const SizedBox(height: 24),
                Text('Tentes utilisées prochainement',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                if (tentesUtilisees.isEmpty)
                  const Text('Aucune tente réservée pour les prochains événements.')
                else
                  ...tentesUtilisees.map((t) => _HomeBody.tenteCard(t)),

                const SizedBox(height: 24),
                Text('Tentes à réparer',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                if (tentesToRepair.isEmpty)
                  const Text('Aucune tente réservée pour les prochains événements.')
                else
                  ...tentesToRepair.map((t) => _HomeBody.tenteCard(t)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget evenementCard(Event e) {
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

  static Widget tenteCard(Tent tente) {
    return Card(
      child: ListTile(
        title: Text(tente.nom),
        subtitle: Text('Unité : ${tente.assignedUnit}'),
      ),
    );
  }
}


