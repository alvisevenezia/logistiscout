import 'package:flutter/material.dart';
import 'package:logistiscout/domain/entities/ingredient.dart';
import 'package:logistiscout/domain/entities/recipe.dart';

class RecipeTile extends StatelessWidget {
  final Recipe recipe;
  final List<IngredientTotal> totals;
  final VoidCallback onDelete;
  final VoidCallback onView;
  final VoidCallback onDuplicate;
  final VoidCallback onMove;

  const RecipeTile({
    super.key,
    required this.recipe,
    required this.totals,
    required this.onDelete,
    required this.onView,
    required this.onDuplicate,
    required this.onMove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ExpansionTile(
        title: Text(
          recipe.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Wrap(
          spacing: 6,
          children: [
            Chip(label: Text(recipe.menuType.name)),
            if (recipe.tags.contains(Tag.vegetarian))
              const Chip(label: Text('Végétarien')),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            switch (v) {
              case 'delete':
                onDelete();
                break;
              case 'duplicate':
                onDuplicate();
                break;
              case 'move':
                onMove();
                break;
              case 'view':
                onView();
                break;
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'view', child: Text('Voir fiche recette')),
            PopupMenuItem(value: 'duplicate', child: Text('Dupliquer vers…')),
            PopupMenuItem(value: 'move', child: Text('Déplacer vers…')),
            PopupMenuItem(value: 'delete', child: Text('Supprimer')),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: totals
                  .map(
                    (i) => Text('- ${i.name}: ${i.quantity.toStringAsFixed(2)} ${i.unit}'),
              )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
