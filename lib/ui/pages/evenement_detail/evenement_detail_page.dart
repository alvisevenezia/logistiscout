import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logistiscout/ui/pages/evenement_detail/tabs/infos_tab.dart';
import 'package:logistiscout/ui/pages/evenement_detail/tabs/menus_tab.dart';
import 'package:logistiscout/ui/pages/evenement_detail/tabs/tents_tab.dart';
import 'package:logistiscout/ui/controllers/evenement_detail_controller.dart';
import 'package:logistiscout/ui/pages/evenement_detail/widgets/shopping_list_sheet.dart';

class EvenementDetailPage extends ConsumerWidget {
  final int eventId;
  final bool openMenusDirectly;

  const EvenementDetailPage({
    super.key,
    required this.eventId,
    this.openMenusDirectly = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(evenementDetailProvider(eventId));

    if (c.loading || c.event == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final event = c.event!;

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
                PopupMenuItem(value: 'export', child: Text('Exporter / Partager')),
              ],
            ),
          ],
        ),
        body: TabBarView(
          children: [
            const InfosTab(),
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
          foregroundColor:
          onPressed == null ? Colors.grey : Theme.of(context).colorScheme.primary,
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
    final page = context.findAncestorWidgetOfExactType<EvenementDetailPage>()!;
    final c = ref.watch(evenementDetailProvider(page.eventId));

    if (c.currentPlan == null || c.event == null) {
      return const SizedBox.shrink();
    }

    final plan = c.currentPlan!;

    return BottomAppBar(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Center(child: Row(
          children: [
            _BottomBarButton(
              icon: Icons.list_alt,
              label: 'Courses',
              onPressed: () async {
                final controller = ref.read(evenementDetailProvider(page.eventId));
                final ingredients = await controller.computeTotalIngredientsForEvent();
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
                    content: Text('Partager / Imprimer (PDF) à implémenter')),
              ),
            ),
          ],
        ),
        ),

    );


  }

}

