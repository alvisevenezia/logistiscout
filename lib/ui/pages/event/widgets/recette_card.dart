import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logistiscout/domain/entities/menu.dart';
import 'package:logistiscout/domain/entities/recipe.dart';
import 'package:logistiscout/ui/controllers/recipe_prociders.dart';

class RecetteCard extends ConsumerWidget {
  final MenuItem item;
  final VoidCallback onDelete;

  const RecetteCard({
    super.key,
    required this.item,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipeAsync = ref.watch(recipeProvider(item.recipeId));

    return recipeAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(12),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          contentPadding: const EdgeInsets.all(12),
          title: const Text(
            'Erreur de chargement',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            'Impossible de charger la recette (id: inconnu)',
            style: TextStyle(color: Colors.redAccent),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: onDelete,
          ),
        ),
      ),
      data: (Recipe recipe) => Card(
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
            recipe.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          leading: CircleAvatar(
            backgroundColor: Colors.green.shade100,
            child: Text(
              recipe.title.isNotEmpty
                  ? recipe.title[0].toUpperCase()
                  : '?',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: onDelete,
            tooltip: 'Supprimer la recette',
          ),
        ),
      ),
    );
  }
}
