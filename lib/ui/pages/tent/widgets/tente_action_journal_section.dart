import 'package:flutter/material.dart';
import 'package:logistiscout/domain/entities/controle.dart';
import 'package:logistiscout/domain/entities/tente.dart';
import 'package:logistiscout/ui/pages/control/controle_detail_page.dart';
import 'package:logistiscout/ui/pages/tent/widgets/tente_detail_common_widgets.dart';

class TenteActionJournalSection extends StatelessWidget {
  final List<Control> controls;
  final Tent tent;
  final String Function(DateTime) formatDate;

  const TenteActionJournalSection({
    super.key,
    required this.controls,
    required this.tent,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    final recent = [...controls]..sort((a, b) => b.date.compareTo(a.date));

    if (recent.isEmpty) {
      return const TenteSectionCard(
        title: 'Journal d’actions',
        child: Text('Aucune action tracée pour le moment.'),
      );
    }

    final preview = recent.take(3).toList();
    final hasMore = recent.length > preview.length;

    return TenteSectionCard(
      title: 'Journal d’actions',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Dernières actions tracées.'),
          const SizedBox(height: 8),
          ...preview.map(
            (control) => _ActionJournalTile(
              control: control,
              formatDate: formatDate,
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
          ),
          if (hasMore)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _showAllActions(context, recent),
                icon: const Icon(Icons.visibility),
                label: const Text('Voir plus'),
              ),
            ),
        ],
      ),
    );
  }

  void _showAllActions(BuildContext context, List<Control> controls) {
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
                        'Journal complet des actions',
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
                      return _ActionJournalTile(
                        control: control,
                        formatDate: formatDate,
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
                        dense: false,
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

class _ActionJournalTile extends StatelessWidget {
  final Control control;
  final String Function(DateTime) formatDate;
  final VoidCallback onTap;
  final bool dense;

  const _ActionJournalTile({
    required this.control,
    required this.formatDate,
    required this.onTap,
    this.dense = true,
  });

  @override
  Widget build(BuildContext context) {
    final actor = _actorLabel(control);
    final completed = _completedItems(control.checklist);
    final pending = _pendingItems(control.checklist);
    final photoCount = control.imageUrls.isNotEmpty
        ? control.imageUrls.length
        : (control.imageUrl?.isNotEmpty ?? false)
        ? 1
        : 0;
    final note = control.comment.trim().isEmpty
        ? 'Aucune remarque'
        : control.comment.trim();

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.blue.shade100),
      ),
      child: ListTile(
        dense: dense,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: const Icon(Icons.assignment_turned_in, color: Colors.blue),
        ),
        title: Text(
          'Contrôle du ${formatDate(control.date)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Qui: $actor'),
              if (completed.isNotEmpty) Text('Quoi: ${completed.join(', ')}'),
              if (pending.isNotEmpty) Text('À corriger: ${pending.join(', ')}'),
              Text('Pourquoi: $note'),
              if (photoCount > 0) Text('Pièces jointes: $photoCount photo(s)'),
            ],
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
        onTap: onTap,
      ),
    );
  }

  static String _actorLabel(Control control) {
    final rawName =
        control.checklist['nom_controleur']?.toString().trim() ?? '';
    if (rawName.isNotEmpty) {
      return rawName;
    }
    return 'Utilisateur #${control.userId}';
  }

  static List<String> _completedItems(Map<String, dynamic> checklist) {
    final items = <String>[];
    checklist.forEach((key, value) {
      if (key == 'nom_controleur') {
        return;
      }
      if (value is bool && value) {
        items.add(key);
        return;
      }
      if (value is String && value.trim().isNotEmpty) {
        items.add('$key: ${value.trim()}');
      }
    });
    return items.take(3).toList();
  }

  static List<String> _pendingItems(Map<String, dynamic> checklist) {
    final items = <String>[];
    checklist.forEach((key, value) {
      if (key == 'nom_controleur') {
        return;
      }
      if (value is bool && !value) {
        items.add(key);
      }
    });
    return items.take(2).toList();
  }
}
