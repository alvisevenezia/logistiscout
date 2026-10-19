import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logistiscout/core/di.dart';
import 'package:logistiscout/domain/entities/home_tile.dart';
import 'package:logistiscout/domain/entities/tent_status.dart';
import 'package:logistiscout/ui/pages/home/home_tile_editor_page.dart';
import 'package:logistiscout/ui/widgets/home/home_stat_card.dart';

/// Écran « Personnaliser l'aperçu » : ordre, visibilité et vignettes perso.
class HomeTilesPage extends ConsumerWidget {
  const HomeTilesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tilesAsync = ref.watch(homeTilesControllerProvider);
    final controller = ref.read(homeTilesControllerProvider.notifier);
    final statuses =
        ref.watch(accountControllerProvider).valueOrNull?.tentStatuses ??
        const <TentStatusRef>[];

    Future<void> run(Future<void> Function() action) async {
      try {
        await action();
      } catch (_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Impossible d'enregistrer l'aperçu.")),
        );
      }
    }

    Future<void> openEditor([HomeTile? tile]) async {
      final result = await Navigator.of(context).push<HomeTile>(
        MaterialPageRoute(builder: (_) => HomeTileEditorPage(initial: tile)),
      );
      if (result != null) await run(() => controller.upsert(result));
    }

    Future<bool> confirm(String title, String action, {String? body}) async {
      final ok = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: body == null ? null : Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(action),
            ),
          ],
        ),
      );
      return ok == true;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Personnaliser l'aperçu"),
        actions: [
          TextButton(
            onPressed: () async {
              final ok = await confirm(
                "Réinitialiser l'aperçu ?",
                'Réinitialiser',
                body:
                    "Les vignettes perso seront supprimées et l'aperçu d'origine restauré.",
              );
              if (ok) await run(controller.resetDefaults);
            },
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
      body: tilesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (tiles) => ReorderableListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          buildDefaultDragHandles: false,
          header: const Padding(
            padding: EdgeInsets.fromLTRB(4, 8, 4, 12),
            child: Text(
              "Glissez pour réordonner. Touchez une vignette pour choisir ce qu'elle compte.",
            ),
          ),
          itemCount: tiles.length,
          onReorderItem: (oldIndex, newIndex) =>
              run(() => controller.reorder(oldIndex, newIndex)),
          itemBuilder: (context, index) {
            final tile = tiles[index];
            return _TileRow(
              key: ValueKey(tile.id),
              index: index,
              tile: tile,
              summary: _summary(tile, statuses),
              onTap: tile.isCustom || tile.kind == HomeTileKind.operational
                  ? () => openEditor(tile)
                  : null,
              onVisibleChanged: (v) =>
                  run(() => controller.setVisible(tile.id, v)),
              onDelete: () async {
                final ok = await confirm(
                  'Supprimer « ${tile.title} » ?',
                  'Supprimer',
                );
                if (ok) await run(() => controller.remove(tile.id));
              },
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: () => openEditor(),
            icon: const Icon(Icons.add),
            label: const Text('Nouvelle vignette'),
          ),
        ),
      ),
    );
  }

  static String _summary(HomeTile tile, List<TentStatusRef> statuses) {
    String statusNames() {
      final byId = {for (final s in statuses) s.id: s.name};
      return tile.statusIds
          .map((id) => byId[id])
          .whereType<String>()
          .join(' · ');
    }

    switch (tile.kind) {
      case HomeTileKind.tents:
        return 'Toutes les tentes';
      case HomeTileKind.repair:
        return 'Statuts marqués « à réparer »';
      case HomeTileKind.outings:
        return 'Événements à venir';
      case HomeTileKind.usedTents:
        return 'Tentes des prochaines sorties';
      case HomeTileKind.operational:
        return tile.statusIds.isEmpty
            ? 'Tentes non marquées « à réparer »'
            : statusNames();
      case HomeTileKind.custom:
        final parts = [
          if (tile.statusIds.isNotEmpty) statusNames(),
          if (tile.tentTypes.isNotEmpty) tile.tentTypes.join(', '),
        ];
        return parts.isEmpty ? 'Toutes les tentes' : parts.join(' — ');
    }
  }
}

class _TileRow extends StatelessWidget {
  const _TileRow({
    super.key,
    required this.index,
    required this.tile,
    required this.summary,
    required this.onTap,
    required this.onVisibleChanged,
    required this.onDelete,
  });

  final int index;
  final HomeTile tile;
  final String summary;
  final VoidCallback? onTap;
  final ValueChanged<bool> onVisibleChanged;
  final VoidCallback onDelete;

  static const _noData = HomeOverviewData(
    tents: [],
    statuses: [],
    upcomingEventsCount: 0,
    usedTentsCount: 0,
  );

  @override
  Widget build(BuildContext context) {
    final card = homeStatCardFor(tile, _noData);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Opacity(
        opacity: tile.visible ? 1 : 0.6,
        child: Card(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: theme.dividerColor),
          ),
          child: Row(
            children: [
              ReorderableDragStartListener(
                index: index,
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(Icons.drag_indicator),
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: card.colors),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(card.icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                card.title,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (tile.isCustom) ...[
                              const SizedBox(width: 6),
                              _PersoBadge(color: card.colors.first),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tile.visible ? summary : 'Masquée',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (tile.isCustom)
                IconButton(
                  tooltip: 'Supprimer la vignette ${tile.title}',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: tile.visible,
                        onChanged: (v) => onVisibleChanged(v ?? true),
                      ),
                      const Text('Visible'),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PersoBadge extends StatelessWidget {
  const _PersoBadge({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        'PERSO',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
