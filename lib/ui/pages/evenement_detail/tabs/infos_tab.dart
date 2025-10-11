import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logistiscout/ui/controllers/evenement_detail_controller.dart.dart';
import 'package:logistiscout/ui/pages/evenement_detail/evenement_detail_page.dart';
import 'package:logistiscout/ui/pages/evenement_detail/widgets/info_card.dart';

class InfosTab extends ConsumerWidget {
  const InfosTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = context.findAncestorWidgetOfExactType<EvenementDetailPage>()!;
    final c = ref.watch(evenementDetailProvider(page.eventId));

    if (c.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final evt = c.event;
    if (evt == null) {
      return const Center(child: Text('Aucun événement trouvé.'));
    }

    final duration = evt.date.difference(evt.dateFin).inDays.abs() + 1;
    final unitNames = evt.unites.isNotEmpty
        ? evt.unites.map((id) => _unitName(id)).join(", ")
        : "Non spécifiée";

    final totalPlaces = c.allTentes
        .where((t) => evt.tentesAssociees.contains(t.id))
        .fold<int>(0, (sum, t) => sum + (t.nbPlaces ?? 0));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoCard(
            icon: Icons.event,
            title: evt.nom,
            subtitle: "${evt.type} • $unitNames",
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.date_range,
            label: "Période",
            value: "Du ${_formatDate(evt.date)} au ${_formatDate(evt.dateFin)} ($duration jours)",
          ),
          const Divider(),
          _InfoRow(
            icon: Icons.people,
            label: "Unité(s)",
            value: unitNames,
          ),
          _InfoRow(
            icon: Icons.chair_alt,
            label: "Tentes assignées",
            value: "${evt.tentesAssociees.length} (${totalPlaces} places)",
          ),
          const SizedBox(height: 24),
          Center(
            child: FilledButton.icon(
              icon: const Icon(Icons.edit),
              label: const Text("Modifier l'événement"),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Ouverture de l'édition bientôt 💡")),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  String _unitName(int id) {
    switch (id) {
      case 0:
        return 'Farfadets';
      case 1:
        return 'Louveteaux/Jeannettes';
      case 2:
        return 'Scouts/Guides';
      case 3:
        return 'Pionniers/Caravelles';
      case 4:
        return 'Compagnons';
      case 5:
        return 'Maitrise';
      case 6:
        return 'Groupe complet';
      default:
        return 'Unité inconnue';
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[700]),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                  color: Colors.grey[800], fontWeight: FontWeight.w600),
            ),
          ),
          Flexible(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}