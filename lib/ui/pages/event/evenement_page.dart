import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logistiscout/core/di.dart';
import 'package:logistiscout/domain/entities/event.dart';
import 'package:logistiscout/domain/entities/group_unit.dart';
import 'package:logistiscout/services/local_storage_service.dart';
import 'package:logistiscout/ui/controllers/evenement_controller.dart';
import 'package:logistiscout/ui/pages/event/evenement_detail_page.dart';
import 'package:logistiscout/ui/pages/event/widgets/event_form_sheet.dart';
import 'package:logistiscout/ui/widgets/common/event_card.dart';
import '../../controllers/tentes_controller.dart';

class EvenementsPage extends ConsumerStatefulWidget {
  const EvenementsPage({super.key});

  @override
  ConsumerState<EvenementsPage> createState() => _EvenementsPageState();
}

class _EvenementsPageState extends ConsumerState<EvenementsPage> {
  String _searchQuery = '';
  String? _selectedType;

  final List<String> _typesEvenement = const [
    'Camp',
    'Sortie',
    'Réunion',
    'Formation',
    'Week-end',
    'Autre',
  ];

  @override
  Widget build(BuildContext context) {
    final asyncEvents = ref.watch(evenementsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Événements')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Rechercher un événement...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 12,
                      ),
                    ),
                    onChanged: (value) =>
                        setState(() => _searchQuery = value.toLowerCase()),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  hint: const Text('Type'),
                  value: _selectedType,
                  onChanged: (value) => setState(() => _selectedType = value),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Tous')),
                    ..._typesEvenement.map(
                      (t) => DropdownMenuItem(value: t, child: Text(t)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 📋 Liste des événements
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref.read(tentesProvider.notifier).reload();
                await ref.read(evenementsProvider.notifier).reload();
              },
              child: asyncEvents.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Erreur : $e')),
                data: (events) {
                  final filtered = events.where((evt) {
                    final matchesName = evt.nom.toLowerCase().contains(
                      _searchQuery,
                    );
                    final matchesType =
                        _selectedType == null || evt.type == _selectedType;
                    return matchesName && matchesType;
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(child: Text('Aucun événement trouvé.'));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),

                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return EventCard(
                        event: filtered[index],
                        onOpen: () => {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EventDetailPage(
                                eventId: filtered[index].id,
                                openMenusDirectly: false,
                              ),
                            ),
                          ),
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Ajouter un évènement',
        onPressed: () async {
          await showEventFormSheet(
            context: context,
            ref: ref,
            controller: ref.read(evenementsProvider.notifier),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
