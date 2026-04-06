import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logistiscout/core/di.dart';
import 'package:logistiscout/domain/entities/tente.dart';
import 'package:logistiscout/ui/controllers/evenement_detail_controller.dart';
import 'package:logistiscout/ui/pages/event/evenement_detail_page.dart';

class TentsTab extends ConsumerWidget {
  const TentsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = context.findAncestorWidgetOfExactType<EventDetailPage>()!;
    final c = ref.watch(evenementDetailProvider(page.eventId));

    if (c.loading) return const Center(child: CircularProgressIndicator());
    if (c.event == null)
      return const Center(child: Text('Aucun événement trouvé'));
    if (c.error != null) return Center(child: Text('Erreur : ${c.error}'));

    final event = c.event!;
    final assigned =
        c.allTentes.where((t) => event.associatedTents.contains(t.id)).toList()
          ..sort((a, b) => a.nom.compareTo(b.nom));

    final available =
        c.availableTentes
            .where((t) => !event.associatedTents.contains(t.id))
            .toList()
          ..sort((a, b) => a.nom.compareTo(b.nom));

    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(evenementDetailProvider(page.eventId).notifier)
            .loadTentes();
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: _TenteSection(
                title: 'Tentes assignées',
                color: Colors.blue.shade50,
                tentes: assigned,
                controller: c,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.swap_horiz),
              label: const Text('Basculer la sélection'),
              onPressed: c.selectedTenteIds.isEmpty
                  ? null
                  : () async {
                      await c.applyTenteChanges();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tentes mises à jour ✅')),
                      );
                    },
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _TenteSection(
                title: 'Tentes disponibles',
                color: Colors.green.shade50,
                tentes: available,
                controller: c,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TenteSection extends StatelessWidget {
  final String title;
  final Color color;
  final List<Tent> tentes;
  final EvenementDetailController controller;

  const _TenteSection({
    required this.title,
    required this.color,
    required this.tentes,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title (${tentes.length})',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView(
            children: tentes.map((t) {
              final selected = controller.selectedTenteIds.contains(t.id);
              return GestureDetector(
                onTap: () => controller.toggleTenteSelection(t.id),
                child: _TenteCard(
                  tente: t,
                  selected: selected,
                  highlightColor: color,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _TenteCard extends ConsumerWidget {
  final Tent tente;
  final bool selected;
  final Color? highlightColor;

  const _TenteCard({
    required this.tente,
    required this.selected,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(accountControllerProvider).valueOrNull;
    int? matchedColor;
    for (final u in (group?.units ?? const [])) {
      if (int.tryParse(u.id) == tente.uniteId) {
        matchedColor = u.color;
        break;
      }
    }

    return Card(
      color: matchedColor != null ? Color(matchedColor) : Colors.grey.shade500,
      //color: selected ? highlightColor ?? Colors.blue.shade50 : Colors.white,
      child: ListTile(
        leading: Icon(
          selected ? Icons.check_circle : Icons.house_siding_outlined,
          color: selected ? Colors.blue : Colors.white,
        ),
        title: Text(tente.nom),
        subtitle: Text('${tente.tentType} • ${tente.nbPlaces} places'),
        trailing: Text(tente.assignedUnit),
      ),
    );
  }
}
