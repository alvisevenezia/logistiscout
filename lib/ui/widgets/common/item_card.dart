import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logistiscout/core/di.dart';
import 'package:logistiscout/domain/entities/group_unit.dart';
import 'package:logistiscout/domain/entities/item.dart';
import 'package:logistiscout/domain/entities/tent_status.dart';
import 'package:logistiscout/ui/controllers/items_controller.dart';
import 'package:logistiscout/ui/widgets/common/item_visuals.dart';

/// Carte d'un matériel dans les listes : même présentation que [TentCard].
class ItemCard extends ConsumerWidget {
  final Item item;

  const ItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(accountControllerProvider).valueOrNull;
    final types = ref.watch(itemTypesProvider).valueOrNull ?? const [];
    final type = itemTypeByKey(types, item.typeKey);
    final unit = _unitById(group?.units ?? const [], item.uniteId);
    final status = itemDisplayStatus(
      item,
      group?.tentStatuses ?? const <TentStatusRef>[],
    );
    final chipColor = Color(status.color);

    final subtitle = [
      type?.name ?? 'Matériel',
      itemQuantityLabel(item, type),
      if (unit != null) unit.name,
    ].join(' • ');

    return Card(
      elevation: 2,
      color: chipColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/materiel/${item.id}'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: unit != null
                    ? Color(unit.color)
                    : Colors.grey.shade500,
                child: Icon(itemTypeIcon(type), color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.nom,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        ItemStatusChip(label: status.label, color: chipColor),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                    if (item.colors.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      ItemColorTags(colors: item.colors),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black45),
            ],
          ),
        ),
      ),
    );
  }
}

/// En-tête de la fiche matériel : même présentation que [HeaderCard].
class ItemHeaderCard extends ConsumerWidget {
  final Item item;

  const ItemHeaderCard({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(accountControllerProvider).valueOrNull;
    final types = ref.watch(itemTypesProvider).valueOrNull ?? const [];
    final type = itemTypeByKey(types, item.typeKey);
    final unit = _unitById(group?.units ?? const [], item.uniteId);
    final status = itemDisplayStatus(
      item,
      group?.tentStatuses ?? const <TentStatusRef>[],
    );

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: unit != null
                  ? Color(unit.color)
                  : Colors.grey.shade500,
              child: Icon(itemTypeIcon(type), color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.nom,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      ItemStatusChip(
                        label: status.label,
                        color: Color(status.color),
                        bold: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      type?.name ?? 'Matériel',
                      itemQuantityLabel(item, type),
                      if (unit != null) unit.name,
                    ].join(' • '),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (item.colors.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ItemColorTags(colors: item.colors),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ItemStatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool bold;

  const ItemStatusChip({
    super.key,
    required this.label,
    required this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: bold ? 10 : 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class ItemColorTags extends StatelessWidget {
  final List<String> colors;

  const ItemColorTags({super.key, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      children: colors.take(6).map((c) {
        return Container(
          width: 16,
          height: 10,
          decoration: BoxDecoration(
            color: _parseColor(c),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: Colors.white, width: 1),
          ),
        );
      }).toList(),
    );
  }

  static Color _parseColor(String s) {
    try {
      if (s.startsWith('#')) {
        return Color(int.parse(s.substring(1), radix: 16) + 0xFF000000);
      }
    } catch (_) {}
    return Colors.grey.shade400;
  }
}

GroupUnit? _unitById(List<GroupUnit> units, int? uniteId) {
  if (uniteId == null) return null;
  for (final u in units) {
    if (int.tryParse(u.id) == uniteId) return u;
  }
  return null;
}
