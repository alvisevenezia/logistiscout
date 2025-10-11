// lib/ui/pages/menus/recipe_actions.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logistiscout/core/di.dart';
import 'package:logistiscout/domain/entities/ingredient.dart';
import 'package:logistiscout/domain/entities/menu.dart';
import 'package:logistiscout/domain/entities/recipe.dart';
import 'package:logistiscout/ui/controllers/evenement_detail_controller.dart.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logistiscout/domain/entities/menu.dart';
import 'package:logistiscout/domain/entities/recipe.dart';
import 'package:logistiscout/ui/controllers/evenement_detail_controller.dart.dart';
import 'package:logistiscout/core/di.dart';
import 'package:logistiscout/ui/pages/evenement_detail/widgets/recipe_selector_sheet.dart';

Future<void> openRecipeSelector(
    BuildContext context,
    WidgetRef ref,
    String eventId,
    ) async {
  final recipeRepo = ref.read(recipeRepositoryProvider);
  final controller = ref.read(evenementDetailProvider(eventId));

  final recipes = await recipeRepo.search();

  if (recipes.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Aucune recette trouvée.')),
    );
    return;
  }

  // 🔹 Identifiants des recettes déjà présentes dans le plan courant
  final existingIds = controller.currentPlan?.items
      .map((i) => i.recipe.id)
      .toSet() ??
      {};

  // 🔹 Affiche la bottom sheet
  final selected = await showModalBottomSheet<List<Recipe>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => RecipeSelectorSheet(
      recipes: recipes,
      existingIds: existingIds,
    ),
  );

  if (selected == null || selected.isEmpty) return;

  // 🔹 Ajoute seulement les nouvelles recettes
  for (final r in selected) {
    if (existingIds.contains(r.id)) continue; // sécurité
    final ingredients = await recipeRepo.getIngredientsForRecipe(r.id);
    final item = MenuItem(recipe: r, baseIngredients: ingredients);
    await controller.addRecipeToMealPlan(item);
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('${selected.length} recette(s) ajoutée(s) ✅')),
  );
}

/// Ouvrir l’UI de création et ENREGISTRER une nouvelle recette côté backend
Future<void> openRecipeCreator(
    BuildContext context,
    WidgetRef ref,
    String eventId,
    ) async {
  final title = TextEditingController();
  final description = TextEditingController();
  final instructions = TextEditingController();
  final qty = TextEditingController();
  final unit = TextEditingController();
  final ingredients = <IngredientTotal>[];

  final recipe = await showModalBottomSheet<Recipe>(
    context: context,
    isScrollControlled: true,
    builder: (_) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          16, 24, 16, MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Créer une nouvelle recette',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: title,
                  decoration: const InputDecoration(
                    labelText: 'Nom de la recette',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: description,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: instructions,
                  minLines: 3, maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Instructions',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Ingrédients', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...ingredients.map((i) => ListTile(
                  title: Text('${i.name} — ${i.quantity} ${i.unit}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => setState(() => ingredients.remove(i)),
                  ),
                )),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: qty,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'Quantité', border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: unit,
                        decoration: const InputDecoration(
                          hintText: 'Unité', border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 4,
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Nom ingrédient', border: OutlineInputBorder(),
                        ),
                        onSubmitted: (name) {
                          if (name.isEmpty) return;
                          final q = double.tryParse(qty.text) ?? 0;
                          ingredients.add(IngredientTotal(name: name, quantity: q, unit: unit.text));
                          qty.clear(); unit.clear();
                          setState(() {});
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Enregistrer'),
                    onPressed: () {
                      final r = Recipe(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: title.text,
                        description: description.text,
                        instructions: instructions.text,
                        category: RecipeCategory.plat,
                        ingredients: ingredients,
                      );
                      Navigator.pop(context, r);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  if (recipe == null) return;

  // Enregistrer la recette dans la base (sans forcément l’ajouter au repas)
  final controller = ref.read(evenementDetailProvider(eventId));
  await controller.addRecipes([
    MenuItem(recipe: recipe, baseIngredients: recipe.ingredients),
  ]);

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Recette "${recipe.title}" créée ✅')),
  );
}
