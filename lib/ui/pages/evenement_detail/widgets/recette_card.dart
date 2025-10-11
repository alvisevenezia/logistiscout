import 'package:flutter/material.dart';
import 'package:logistiscout/domain/entities/menu.dart';

class RecetteCard extends StatelessWidget {
  final MenuItem item;
  final VoidCallback onDelete;

  const RecetteCard({
    super.key,
    required this.item,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final recipe = item.recipe;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        title: Text(
          recipe.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          recipe.description ?? 'Aucune description.',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade100,
          child: Text(
            recipe.title.isNotEmpty ? recipe.title[0].toUpperCase() : '?',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: onDelete,
          tooltip: 'Supprimer la recette',
        ),
      ),
    );
  }
}
