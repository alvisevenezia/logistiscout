import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logistiscout/core/di.dart';
import 'package:logistiscout/domain/entities/ingredient.dart';
import 'package:logistiscout/domain/entities/menu.dart';
import 'package:logistiscout/domain/entities/menu_type.dart';
import 'package:logistiscout/domain/entities/recipe.dart';
import 'package:logistiscout/ui/controllers/evenement_detail_controller.dart';
import 'package:logistiscout/ui/pages/evenement_detail/widgets/recipe_selector_sheet.dart';

Future<void> openRecipeSelector(
    BuildContext context,
    WidgetRef ref,
    int eventId,
    ) async {
  final recipeRepo = ref.read(recipeRepositoryProvider);
  final controller = ref.read(evenementDetailProvider(eventId));

  final recipes = await recipeRepo.search();

  if (recipes.isEmpty && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Aucune recette trouvée.')),
    );
    return;
  }

  // 🔹 Identifiants des recettes déjà présentes dans le plan courant
  final existingIds = controller.currentPlan?.items
      .map((i) => i.recipeId)
      .toSet() ??
      {};

  // 🔹 Affiche la bottom sheet
  final selectedRecipe = await showModalBottomSheet<List<Recipe>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => RecipeSelectorSheet(
      recipes: recipes,
      existingIds: existingIds,
    ),
  );

  if (selectedRecipe == null || selectedRecipe.isEmpty) return;

  for (final recipe in selectedRecipe) {
    if (existingIds.contains(recipe.id)) continue; // sécurité
    final item = MenuItem(
        id: -1,
        eventId: eventId,
        recipeId: recipe.id,
        dayNumber: controller.dayOffset,
        mealType: MealType.dejeuner,
        portions: controller.currentPlan?.portions ?? 1,
    );
    await controller.addMenuItemToMealPlan(item);
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('${selectedRecipe.length} recette(s) ajoutée(s) ✅')),
  );
}

Future<void> openRecipeCreator(
    BuildContext context,
    WidgetRef ref,
    int eventId,
    ) async {
  final title = TextEditingController();
  final description = TextEditingController();
  final instructions = TextEditingController();
  final qty = TextEditingController();
  final unit = TextEditingController();
  final ingredients = <IngredientTotal>[];
  var type = MenuType.plat;

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
                DropdownButtonFormField<MenuType>(
                  initialValue: type,
                  items: MenuType.values
                      .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(e.name),
                  ))
                      .toList(),
                  onChanged: (v) => type = v ?? MenuType.plat,
                  decoration: const InputDecoration(labelText: 'Unité'),
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
                          hintText: 'Type', border: OutlineInputBorder(),
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
                        id: -1,
                        title: title.text,
                        menuType: type,
                        description: description.text,
                        instructions: instructions.text,
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
  await controller.createRecipes([recipe]);

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Recette "${recipe.title}" créée ✅')),
  );
}
