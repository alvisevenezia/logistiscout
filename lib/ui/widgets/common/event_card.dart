import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logistiscout/core/di.dart';
import 'package:logistiscout/domain/entities/event.dart';

class EventCard extends ConsumerWidget {
  final Event event;
  final VoidCallback onOpen;
  final bool detail;

  const EventCard({
    super.key,
    required this.event,
    required this.onOpen,
    this.detail = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(accountControllerProvider).valueOrNull;
    final unitsById = {
      for (final unit in (group?.units ?? const []))
        int.tryParse(unit.id): unit,
    };

    final mainUnitId = event.unites.isNotEmpty ? event.unites.first : null;
    final mainUnit = mainUnitId != null ? unitsById[mainUnitId] : null;

    final cardColor = detail
        ? mainUnit != null
              ? Color(mainUnit.color)
              : Colors.grey.shade200
        : Colors.grey.shade100;

    final unitLabel = mainUnit != null ? mainUnit.name : 'Aucune unité';

    final textColor = detail
        ? ThemeData.estimateBrightnessForColor(cardColor) == Brightness.dark
              ? Colors.white
              : Colors.black
        : Colors.black87;

    return Card(
      color: cardColor,
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: detail
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: cardColor,
          child: Icon(
            Icons.event,
            color: detail
                ? Colors.white
                : (mainUnit != null ? Color(mainUnit.color) : Colors.black54),
          ),
        ),
        title: Text(
          event.nom[0].toUpperCase() + event.nom.substring(1),
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '📅 Du ${_formatDate(event.date)} au ${_formatDate(event.dateFin)}',
                style: TextStyle(color: textColor),
              ),
              Text(
                '🗂️ Type : ${event.type}',
                style: TextStyle(color: textColor),
              ),
              Text(
                '🏕️ Unité : $unitLabel',
                style: TextStyle(color: textColor),
              ),
              if (detail) ...[
                Text(
                  '⛺ Tentes : ${event.associatedTents.isEmpty ? "Aucune" : event.associatedTents.join(", ")}',
                  style: TextStyle(color: textColor),
                ),
              ],
            ],
          ),
        ),

        onTap: () {
          context.push('/events/${event.id}');
        },
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
