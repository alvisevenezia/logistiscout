import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logistiscout/core/di.dart';
import 'package:logistiscout/domain/entities/event.dart';
import 'package:logistiscout/ui/controllers/evenement_controller.dart';
import 'package:logistiscout/ui/controllers/evenement_detail_controller.dart';
import 'package:logistiscout/ui/pages/event/tabs/infos_tab.dart';
import 'package:logistiscout/ui/pages/event/tabs/menus_tab.dart';
import 'package:logistiscout/ui/pages/event/tabs/tents_tab.dart';
import 'package:logistiscout/ui/pages/event/widgets/shopping_list_sheet.dart';
import 'package:logistiscout/ui/pages/event/widgets/event_form_sheet.dart';

class EventDetailPage extends ConsumerWidget {
  final int eventId;
  final bool openMenusDirectly;

  const EventDetailPage({
    super.key,
    required this.eventId,
    this.openMenusDirectly = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(evenementDetailProvider(eventId));

    if (c.loading || c.event == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final event = c.event!;
    final onEditEvent = () async {
      await showEventFormSheet(
        context: context,
        ref: ref,
        controller: ref.read(evenementsProvider.notifier),
        event: event,
        onSaved: (_) async {
          await ref.read(evenementDetailProvider(event.id)).init(event.id);
        },
      );
    };

    return DefaultTabController(
      length: 3,
      initialIndex: openMenusDirectly ? 2 : 0,
      child: Scaffold(
        appBar: AppBar(
          title: Text(event.nom),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: 'Infos'),
              Tab(text: 'Tentes'),
              Tab(text: 'Menus'),
            ],
          ),
          actions: [
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'export') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Export PDF à implémenter')),
                  );
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'export',
                  child: Text('Exporter / Partager'),
                ),
              ],
            ),
          ],
        ),
        body: TabBarView(
          children: [
            InfosTab(onEdit: onEditEvent),
            const TentsTab(),
            MenusTab(eventDays: event.dateRange),
          ],
        ),
        bottomNavigationBar: _MenusBottomBar(),
      ),
    );
  }
}

class _BottomBarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _BottomBarButton({
    required this.icon,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      child: TextButton.icon(
        style: TextButton.styleFrom(
          foregroundColor: onPressed == null
              ? Colors.grey
              : Theme.of(context).colorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class _MenusBottomBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = context.findAncestorWidgetOfExactType<EventDetailPage>()!;
    final c = ref.watch(evenementDetailProvider(page.eventId));

    if (c.currentPlan == null || c.event == null) {
      return const SizedBox.shrink();
    }

    final plan = c.currentPlan!;

    return BottomAppBar(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Center(
        child: Row(
          children: [
            _BottomBarButton(
              icon: Icons.list_alt,
              label: 'Courses',
              onPressed: () async {
                final controller = ref.read(
                  evenementDetailProvider(page.eventId),
                );
                final ingredients = await controller
                    .computeTotalIngredientsForEvent();
                if (context.mounted) {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => ShoppingListSheet(ingredients: ingredients),
                  );
                }
              },
            ),
            _BottomBarButton(
              icon: Icons.share,
              label: 'Exporter',
              onPressed: plan.items.isEmpty
                  ? null
                  : () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Partager / Imprimer (PDF) à implémenter',
                        ),
                      ),
                    ),
            ),
            _BottomBarButton(
              icon: Icons.remove_circle,
              label: "Supprimer",
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Supprimer l'évènement ?"),
                    content: Text(
                      "Supprimer l'évènement ? Cette action est irréversible.",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Annuler'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Supprimer'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ref
                      .read(evenementsProvider.notifier)
                      .deleteEvenement(page.eventId);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
