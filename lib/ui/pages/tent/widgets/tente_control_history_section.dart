import 'package:flutter/material.dart';
import 'package:logistiscout/domain/entities/controle.dart';
import 'package:logistiscout/domain/entities/tente.dart';
import 'package:logistiscout/ui/pages/control/controle_detail_page.dart';
import 'package:logistiscout/ui/pages/tent/widgets/tente_detail_common_widgets.dart';

class TenteControlHistorySection extends StatelessWidget {
  final List<Control> controls;
  final Tent tent;
  final String Function(DateTime) formatDate;

  const TenteControlHistorySection({
    super.key,
    required this.controls,
    required this.tent,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    final recent = [...controls]..sort((a, b) => b.date.compareTo(a.date));
    final preview = recent.take(3).toList();
    final hasMore = recent.length > 3;

    return TenteSectionCard(
      title: 'Historique des contrôles',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (recent.isEmpty)
            const Text('Aucun contrôle enregistré pour cette tente.')
          else ...[
            ...preview.map((control) {
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: Colors.blue.shade100),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: const Icon(
                      Icons.assignment_turned_in,
                      color: Colors.blue,
                    ),
                  ),
                  title: Text(
                    'Contrôle du ${formatDate(control.date)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    control.comment.isNotEmpty
                        ? control.comment
                        : 'Aucune remarque',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 18,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ControleDetailPage(controle: control, tente: tent),
                      ),
                    );
                  },
                ),
              );
            }),
            if (hasMore)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _showAllControls(context, recent),
                  icon: const Icon(Icons.visibility),
                  label: const Text('Voir plus'),
                ),
              ),
          ],
        ],
      ),
    );
  }

  void _showAllControls(BuildContext context, List<Control> controls) {
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
                        'Historique complet des contrôles',
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
                    itemCount: controls.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final control = controls[index];
                      final hasComment = control.comment.trim().isNotEmpty;
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
                            backgroundColor: Colors.blue.shade100,
                            child: const Icon(
                              Icons.assignment_turned_in,
                              color: Colors.blue,
                            ),
                          ),
                          title: Text(
                            'Contrôle du ${formatDate(control.date)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              hasComment ? control.comment : 'Aucune remarque',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
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
                                builder: (_) => ControleDetailPage(
                                  controle: control,
                                  tente: tent,
                                ),
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
