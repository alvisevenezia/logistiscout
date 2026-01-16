import 'package:flutter/material.dart';
import 'package:logistiscout/domain/entities/controle.dart';
import 'package:logistiscout/domain/entities/tente.dart';
import 'package:logistiscout/ui/widgets/common/hearder_card.dart';

class ControleDetailPage extends StatelessWidget {
  final Control controle;
  final Tent tente;

  const ControleDetailPage({
    super.key,
    required this.controle,
    required this.tente,
  });

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Détail du contrôle')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: HeaderCard(tent: tente),
          ),
          Expanded(
            child: ListView(
              children: [

                // 📋 Info contrôle
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Informations du contrôle',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Divider(height: 20),
                        _InfoRow(
                          label: 'Date',
                          value: _formatDate(controle.date),
                        ),
                        if (controle.checklist.containsKey(
                          "nom_controleur",
                        )) ...[
                          _InfoRow(
                            label: 'Contrôleur',
                            value: controle.checklist['nom_controleur'],
                          ),
                        ],
                        if (controle.checklist.containsKey(
                          "Nombre de sardines/piquets",
                        )) ...[
                          _InfoRow(
                            label: 'Nombre de sardines',
                            value:
                                ((controle.checklist["Nombre de sardines/piquets"] ==
                                                null ||
                                            controle
                                                .checklist["Nombre de sardines/piquets"]
                                                .toString()
                                                .isEmpty)
                                        ? 0
                                        : controle
                                              .checklist["Nombre de sardines/piquets"])
                                    .toString(),
                          ),
                        ],

                        if (controle.comment.isNotEmpty) ...[
                          Text(
                            'Remarques ',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(controle.comment),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ✅ Checklist
                if (controle.checklist.isNotEmpty)
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Checklist du contrôle',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const Divider(height: 20),
                          ...controle.checklist.entries
                              .where((entry) => entry.value is bool)
                              .map((entry) {
                                final value = entry.value;
                                Widget icon = Icon(
                                  value ? Icons.check_circle : Icons.cancel,
                                  color: value
                                      ? Colors.green
                                      : Colors.redAccent,
                                );

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6.0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          entry.key,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      icon,
                                    ],
                                  ),
                                );
                              }),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
