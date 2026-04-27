import 'package:flutter/material.dart';
import 'package:logistiscout/domain/entities/event.dart';
import 'package:logistiscout/ui/pages/event/evenement_detail_page.dart';
import 'package:logistiscout/ui/pages/tent/widgets/tente_detail_common_widgets.dart';

class TenteEventHistorySection extends StatelessWidget {
  final List<Event> events;
  final String Function(DateTime) formatDate;

  const TenteEventHistorySection({
    super.key,
    required this.events,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    final recent = [...events]..sort((a, b) => b.date.compareTo(a.date));
    final preview = recent.take(3).toList();
    final hasMore = recent.length > 3;

    if (recent.isEmpty) {
      return const TenteSectionCard(
        title: 'Historique des sorties',
        child: Text('Aucune sortie enregistrée pour cette tente.'),
      );
    }

    return TenteSectionCard(
      title: 'Historique des sorties',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...preview.map((event) {
            final ongoing = event.dateFin.isAfter(DateTime.now());
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: ongoing
                    ? Colors.green.shade100
                    : Colors.blue.shade100,
                child: Icon(
                  ongoing ? Icons.campaign : Icons.event_available,
                  color: ongoing ? Colors.green.shade800 : Colors.blue.shade800,
                ),
              ),
              title: Text(
                event.nom,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${formatDate(event.date)} → ${formatDate(event.dateFin)}',
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EventDetailPage(eventId: event.id),
                  ),
                );
              },
            );
          }),
          if (hasMore)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _showAllEvents(context, recent),
                icon: const Icon(Icons.visibility),
                label: const Text('Voir plus'),
              ),
            ),
        ],
      ),
    );
  }

  void _showAllEvents(BuildContext context, List<Event> events) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Historique complet des sorties',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Fermer',
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: events.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final event = events[index];
                      final ongoing = event.dateFin.isAfter(DateTime.now());
                      return Card(
                        elevation: 0,
                        margin: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: ongoing
                                ? Colors.green.shade100
                                : Colors.blue.shade100,
                            child: Icon(
                              ongoing ? Icons.campaign : Icons.event_available,
                              color: ongoing
                                  ? Colors.green.shade800
                                  : Colors.blue.shade800,
                            ),
                          ),
                          title: Text(
                            event.nom,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${formatDate(event.date)} → ${formatDate(event.dateFin)}',
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 18,
                          ),
                          onTap: () {
                            Navigator.pop(sheetContext);
                            if (!context.mounted) {
                              return;
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    EventDetailPage(eventId: event.id),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
