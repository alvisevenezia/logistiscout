import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logistiscout/domain/entities/issue.dart';
import 'package:logistiscout/ui/controllers/items_controller.dart';
import 'package:logistiscout/ui/pages/tent/widgets/tente_detail_common_widgets.dart';
import 'package:logistiscout/ui/widgets/issues/issue_dialog.dart';

/// Section « Signalements » d'une fiche tente ou matériel : problèmes
/// ouverts, bouton pour les clore et bouton pour en signaler un nouveau.
class IssuesSection extends ConsumerWidget {
  final IssueTarget target;
  final String targetName;
  final int maxQuantity;

  const IssuesSection({
    super.key,
    required this.target,
    required this.targetName,
    this.maxQuantity = 1,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final issuesAsync = ref.watch(openIssuesForTargetProvider(target));

    return TenteSectionCard(
      title: 'Signalements',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          issuesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('Erreur chargement signalements : $e'),
            data: (issues) => issues.isEmpty
                ? const Text('Aucun problème signalé.')
                : Column(
                    children: [
                      for (final issue in issues)
                        _IssueTile(issue: issue, maxQuantity: maxQuantity),
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.report_problem_outlined),
            label: const Text('Signaler un problème'),
            onPressed: () => showIssueDialog(
              context,
              target: target,
              targetName: targetName,
              maxQuantity: maxQuantity,
            ),
          ),
        ],
      ),
    );
  }
}

class _IssueTile extends ConsumerStatefulWidget {
  final Issue issue;
  final int maxQuantity;

  const _IssueTile({required this.issue, required this.maxQuantity});

  @override
  ConsumerState<_IssueTile> createState() => _IssueTileState();
}

class _IssueTileState extends ConsumerState<_IssueTile> {
  bool _busy = false;

  Future<void> _close(IssueState state) async {
    setState(() => _busy = true);
    try {
      await ref.read(issueActionsProvider).setState(widget.issue, state);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Action impossible : $e')));
    }
  }

  void _showPhoto(String url) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        clipBehavior: Clip.antiAlias,
        child: InteractiveViewer(child: Image.network(url, fit: BoxFit.contain)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final issue = widget.issue;
    final details = [
      issue.usable ? 'Utilisable' : 'Hors service',
      if (widget.maxQuantity > 1) '${issue.quantity} / ${widget.maxQuantity}',
      _fmtDate(issue.createdAt),
      if ((issue.reporterName ?? '').isNotEmpty) issue.reporterName!,
    ].join(' · ');

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        issue.usable ? Icons.warning_amber : Icons.error_outline,
        color: issue.usable ? Colors.orange.shade700 : Colors.red.shade700,
      ),
      title: Text(
        issue.description,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(details),
      trailing: _busy
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (issue.photoUrl != null)
                  IconButton(
                    tooltip: 'Voir la photo',
                    icon: const Icon(Icons.photo),
                    onPressed: () => _showPhoto(issue.photoUrl!),
                  ),
                PopupMenuButton<IssueState>(
                  tooltip: 'Clore',
                  icon: const Icon(Icons.more_vert),
                  onSelected: _close,
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: IssueState.resolved,
                      child: Text('Résolu'),
                    ),
                    PopupMenuItem(
                      value: IssueState.dismissed,
                      child: Text('Classer sans suite'),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
}
