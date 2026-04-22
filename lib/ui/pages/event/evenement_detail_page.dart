import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logistiscout/ui/controllers/evenement_controller.dart';
import 'package:logistiscout/ui/controllers/evenement_detail_controller.dart';
import 'package:logistiscout/ui/pages/event/tabs/infos_tab.dart';
import 'package:logistiscout/ui/pages/event/tabs/tents_tab.dart';
import 'package:logistiscout/ui/pages/event/widgets/event_form_sheet.dart';

class EventDetailPage extends ConsumerWidget {
  final int eventId;

  const EventDetailPage({super.key, required this.eventId});

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

    final onDeleteEvent = () async {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text("Supprimer l'évènement ?"),
          content: Text(
            "Supprimer « ${event.nom} » ? Cette action est irréversible.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Supprimer'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await ref.read(evenementsProvider.notifier).deleteEvenement(event.id);
        if (context.mounted) {
          Navigator.pop(context);
        }
      }
    };

    return DefaultTabController(
      length: 2,
      initialIndex: 0,
      child: Scaffold(
        appBar: AppBar(
          title: Text(event.nom),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: 'Infos'),
              Tab(text: 'Tentes'),
            ],
          ),
          actions: [
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'export') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Export PDF à implémenter')),
                  );
                } else if (v == 'delete') {
                  onDeleteEvent();
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'export',
                  child: Text('Exporter / Partager'),
                ),
                PopupMenuItem(value: 'delete', child: Text('Supprimer')),
              ],
            ),
          ],
        ),
        body: TabBarView(
          children: [
            InfosTab(onEdit: onEditEvent),
            const TentsTab(),
          ],
        ),
      ),
    );
  }
}
