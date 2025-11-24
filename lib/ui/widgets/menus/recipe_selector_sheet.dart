import 'package:flutter/material.dart';
import 'package:logistiscout/domain/entities/recipe.dart';

class RecipeSelectorResult {
  final List<Recipe> recipes;
  const RecipeSelectorResult(this.recipes);
}

class RecipeSelectorSheet extends StatefulWidget {
  final List<Recipe> all;

  const RecipeSelectorSheet({super.key, required this.all});

  @override
  State<RecipeSelectorSheet> createState() => _RecipeSelectorSheetState();
}

class _RecipeSelectorSheetState extends State<RecipeSelectorSheet> {
  final Set<Recipe> _selected = {};
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.all.where((r) {
      return r.title.toLowerCase().contains(_query.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choisir une recette'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher une recette...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('Aucune recette trouvée'))
                : ListView.separated(
              padding: const EdgeInsets.all(8),
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemCount: filtered.length,
              itemBuilder: (context, i) {
                final recipe = filtered[i];
                final selected = _selected.contains(recipe);

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    color: selected ? Colors.green.shade50 : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected ? Colors.green : Colors.grey.shade300,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(10),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green.shade100,
                      child: Icon(
                        _categoryIcon(recipe.category),
                        color: Colors.green.shade700,
                      ),
                    ),
                    title: Text(recipe.title,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      recipe.description.isNotEmpty == true
                          ? recipe.description
                          : _categoryLabel(recipe.category),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Icon(
                      selected ? Icons.check_circle : Icons.add_circle_outline,
                      color: selected ? Colors.green : Colors.grey,
                    ),
                    onTap: () {
                      setState(() {
                        if (selected) {
                          _selected.remove(recipe);
                        } else {
                          _selected.add(recipe);
                        }
                      });
                    },
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check),
                label: Text('Ajouter ${_selected.length} recette(s)'),
                onPressed: _selected.isEmpty
                    ? null
                    : () => Navigator.pop(
                  context,
                  RecipeSelectorResult(_selected.toList()),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: Colors.green.shade600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _categoryIcon(RecipeCategory category) {
    switch (category) {
      case RecipeCategory.entree:
        return Icons.local_dining;
      case RecipeCategory.plat:
        return Icons.restaurant;
      case RecipeCategory.dessert:
        return Icons.icecream;
      case RecipeCategory.boisson:
        return Icons.local_cafe;
    }
  }

  String _categoryLabel(RecipeCategory category) {
    switch (category) {
      case RecipeCategory.entree:
        return 'Entrée';
      case RecipeCategory.plat:
        return 'Plat principal';
      case RecipeCategory.dessert:
        return 'Dessert';
      case RecipeCategory.boisson:
        return 'Boisson';
    }
  }
}
