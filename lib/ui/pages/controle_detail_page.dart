import 'package:flutter/material.dart';
import 'package:logistiscout/domain/entities/controle.dart';
import 'package:logistiscout/domain/entities/tente.dart';

class ControleDetailPage extends StatelessWidget {
  final Controle controle;
  final Tente tente;

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
      appBar: AppBar(
        title: const Text('Détail du contrôle'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // 🏕 Info tente
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 1,
              child: ListTile(
                leading: const Icon(Icons.cabin, color: Colors.blueAccent),
                title: Text(
                  tente.nom,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text('${tente.typeTente} • ${tente.nbPlaces} places'),
              ),
            ),

            const SizedBox(height: 16),

            // 📋 Info contrôle
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informations du contrôle',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Divider(height: 20),
                    _InfoRow(label: 'Date', value: _formatDate(controle.date)),
                    _InfoRow(label: 'Utilisateur (ID)', value: controle.userId.toString()),
                    const SizedBox(height: 10),
                    if (controle.remarques.isNotEmpty) ...[
                      Text('Remarques :',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(controle.remarques),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ✅ Checklist
            if (controle.checklist.isNotEmpty)
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Checklist du contrôle',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Divider(height: 20),
                      ...controle.checklist.entries.map((entry) {
                        final value = entry.value;
                        Widget icon;

                        // Support booleans, strings, or numbers
                        if (value is bool) {
                          icon = Icon(
                            value ? Icons.check_circle : Icons.cancel,
                            color: value ? Colors.green : Colors.redAccent,
                          );
                        } else if (value is String && value.isNotEmpty) {
                          icon = const Icon(Icons.text_snippet, color: Colors.blueGrey);
                        } else {
                          icon = const Icon(Icons.help_outline, color: Colors.grey);
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  entry.key,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
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
            style:
            Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
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
