import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logistiscout/core/di.dart';
import 'package:logistiscout/domain/entities/ingredient.dart';
import 'package:logistiscout/domain/entities/menu.dart';
import 'package:logistiscout/domain/entities/recipe.dart';
import 'package:logistiscout/domain/entities/tente.dart';
import 'package:logistiscout/services/local_storage_service.dart';
import 'package:logistiscout/services/shopping_list_service.dart';
import 'package:logistiscout/ui/controllers/evenement_detail_controller.dart.dart';
import 'package:logistiscout/ui/widgets/common/date_chips.dart';
import 'package:logistiscout/ui/widgets/common/segmented_meal.dart';
import 'package:logistiscout/ui/widgets/menus/portion_stepper.dart';
import 'package:logistiscout/ui/widgets/menus/recipe_tile.dart';
import 'package:logistiscout/ui/modals/recipe_selector_sheet.dart';
import 'dart:developer' as developer;

class EvenementDetailPage extends ConsumerWidget {
  final String eventId;
  final bool openMenusDirectly;

  const EvenementDetailPage({
    super.key,
    required this.eventId,
    this.openMenusDirectly = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(evenementDetailProvider(eventId));

    if (c.loading || c.event == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final event = c.event!;

    return DefaultTabController(
      length: 3,
      initialIndex: openMenusDirectly ? 2 : 0,
      child: Scaffold(
        appBar: AppBar(
          title: Text(event.nom),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: 'Infos'),
              Tab(text: 'Tentes'),
              Tab(text: 'Menus'),
            ],
          ),
          actions: [
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'shopping_all') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Génération sur tout l’événement...')),
                  );
                } else if (v == 'export') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Export PDF à implémenter')),
                  );
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'shopping_all',
                  child: Text('Liste de courses – tout l’événement'),
                ),
                PopupMenuItem(value: 'export', child: Text('Exporter / Partager')),
              ],
            ),
          ],
        ),
        body: TabBarView(
          children: [
            const _InfosTab(),
            const _TentesTab(),
            _MenusTab(eventDays: event.dateRange),
          ],
        ),
        floatingActionButton: Builder(builder: (ctx) {
          final tab = DefaultTabController.of(ctx);
          if (tab != null && tab.index == 2) {
            return
                FloatingActionButton.extended(
                  heroTag: 'createRecipe',
                  backgroundColor: Colors.green,
                  onPressed: () => _openRecipeCreator(ctx, ref),
                  label: const Text('Créer une recette'),
                  icon: const Icon(Icons.edit),
                );
          }
          return const SizedBox.shrink();
        }),

        bottomNavigationBar: _MenusBottomBar(),
      ),
    );
  }

  Future<void> _openRecipeCreator(BuildContext context, WidgetRef ref) async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final instructionsController = TextEditingController();
    final quantityController = TextEditingController();
    final unitController = TextEditingController();
    final nameController = TextEditingController();

    final ingredientList = <IngredientTotal>[];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            24,
            16,
            MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        'Créer une nouvelle recette',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 🔹 Nom
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Nom de la recette',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 🔹 Description
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      minLines: 1,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),

                    // 🔹 Instructions
                    TextField(
                      controller: instructionsController,
                      decoration: const InputDecoration(
                        labelText: 'Instructions',
                        border: OutlineInputBorder(),
                      ),
                      minLines: 3,
                      maxLines: 6,
                    ),
                    const SizedBox(height: 16),

                    // 🔹 Liste d'ingrédients
                    Text('Ingrédients', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),

                    if (ingredientList.isEmpty)
                      const Text('Aucun ingrédient ajouté.'),
                    ...ingredientList.map((i) => ListTile(
                      title: Text('${i.name} — ${i.quantity} ${i.unit}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => setState(() => ingredientList.remove(i)),
                      ),
                    )),

                    const Divider(height: 32),

                    // 🔹 Formulaire d'ajout d'ingrédient
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: nameController,
                            decoration: const InputDecoration(
                              hintText: 'Nom ingrédient',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: quantityController,
                            decoration: const InputDecoration(
                              hintText: 'Qté',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: unitController,
                            decoration: const InputDecoration(
                              hintText: 'Unité',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Colors.green),
                          tooltip: 'Ajouter ingrédient',
                          onPressed: () {
                            if (nameController.text.isEmpty ||
                                quantityController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Complète le nom et la quantité')),
                              );
                              return;
                            }

                            setState(() {
                              ingredientList.add(
                                IngredientTotal(
                                  name: nameController.text.trim(),
                                  quantity: double.tryParse(quantityController.text) ?? 0,
                                  unit: unitController.text.trim(),
                                ),
                              );
                              nameController.clear();
                              quantityController.clear();
                              unitController.clear();
                            });
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // 🔹 Bouton Enregistrer
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text('Enregistrer'),
                        onPressed: () {
                          if (titleController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Le nom de la recette est obligatoire')),
                            );
                            return;
                          }

                          final newRecipe = Recipe(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            title: titleController.text.trim(),
                            description: descriptionController.text.trim(),
                            instructions: instructionsController.text.trim(),
                            category: RecipeCategory.plat,
                            ingredients: ingredientList,
                          );

                          Navigator.pop(context, newRecipe);
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    ).then((recipe) async {
      if (recipe is Recipe) {
        final controller = ref.read(evenementDetailProvider(eventId));
        final item = MenuItem(
          recipe: recipe,
          baseIngredients: recipe.ingredients,
        );
        await controller.addRecipes([item]);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Recette "${recipe.title}" ajoutée ✅')),
        );
      }
    });
  }

  Future<void> _openRecipeSelector(BuildContext context, WidgetRef ref) async {
    try {
      // 🧠 On récupère le repository de recettes
      final recipeRepo = ref.read(recipeRepositoryProvider);

      // 🔹 Recherche toutes les recettes disponibles (tu peux filtrer si besoin)
      final recipes = await recipeRepo.search();

      if (recipes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucune recette trouvée.')),
        );
        return;
      }

      // 🔹 Ouvre la feuille de sélection
      final result = await showModalBottomSheet<RecipeSelectorResult>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        builder: (_) => SizedBox(
          height: MediaQuery.of(context).size.height * 0.85,
          child: RecipeSelectorSheet(all: recipes),
        ),
      );

      // 🔹 Si des recettes ont été sélectionnées
      if (result != null && result.recipes.isNotEmpty) {
        final controller = ref.read(evenementDetailProvider(eventId));

        for (final recipe in result.recipes) {
          final ingredients = await recipeRepo.getIngredientsForRecipe(
              recipe.id);
          final item = MenuItem(
            recipe: recipe,
            baseIngredients: ingredients,
            menuId: int.tryParse(recipe.id),
          );
          await controller.addRecipeToMealPlan(item);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(
              '${result.recipes.length} recette(s) ajoutée(s) ✅')),
        );
      }
    } catch (e, st) {
      debugPrint('❌ Erreur dans _openRecipeSelector: $e\n$st');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }


}

class _InfosTab extends ConsumerWidget {
  const _InfosTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = context.findAncestorWidgetOfExactType<EvenementDetailPage>()!;
    final c = ref.watch(evenementDetailProvider(page.eventId));

    if (c.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final evt = c.event;
    if (evt == null) {
      return const Center(child: Text('Aucun événement trouvé.'));
    }

    final duration = evt.date.difference(evt.dateFin).inDays.abs() + 1;
    final unitNames = evt.unites.isNotEmpty
        ? evt.unites.map((id) => _unitName(id)).join(", ")
        : "Non spécifiée";

    final totalPlaces = c.allTentes
        .where((t) => evt.tentesAssociees.contains(t.id))
        .fold<int>(0, (sum, t) => sum + (t.nbPlaces ?? 0));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoCard(
            icon: Icons.event,
            title: evt.nom,
            subtitle: "${evt.type} • $unitNames",
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.date_range,
            label: "Période",
            value: "Du ${_formatDate(evt.date)} au ${_formatDate(evt.dateFin)} ($duration jours)",
          ),
          const Divider(),
          _InfoRow(
            icon: Icons.people,
            label: "Unité(s)",
            value: unitNames,
          ),
          _InfoRow(
            icon: Icons.chair_alt,
            label: "Tentes assignées",
            value: "${evt.tentesAssociees.length} (${totalPlaces} places)",
          ),
          const SizedBox(height: 24),
          Center(
            child: FilledButton.icon(
              icon: const Icon(Icons.edit),
              label: const Text("Modifier l'événement"),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Ouverture de l'édition bientôt 💡")),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  String _unitName(int id) {
    switch (id) {
      case 0:
        return 'Farfadets';
      case 1:
        return 'Louveteaux/Jeannettes';
      case 2:
        return 'Scouts/Guides';
      case 3:
        return 'Pionniers/Caravelles';
      case 4:
        return 'Compagnons';
      case 5:
        return 'Maitrise';
      case 6:
        return 'Groupe complet';
      default:
        return 'Unité inconnue';
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[700]),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w600),
            ),
          ),
          Flexible(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(subtitle),
      ),
    );
  }
}


class _TentesTab extends ConsumerWidget {
  const _TentesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = context.findAncestorWidgetOfExactType<EvenementDetailPage>()!;
    final c = ref.watch(evenementDetailProvider(page.eventId));

    if (c.loading) return const Center(child: CircularProgressIndicator());
    if (c.event == null) return const Center(child: Text('Aucun événement trouvé'));
    if (c.error != null) return Center(child: Text('Erreur : ${c.error}'));

    final event = c.event!;
    final assigned = c.allTentes
        .where((t) => event.tentesAssociees.contains(t.id))
        .toList()
      ..sort((a, b) => a.nom.compareTo(b.nom));

    final available = c.availableTentes
        .where((t) => !event.tentesAssociees.contains(t.id))
        .toList()
      ..sort((a, b) => a.nom.compareTo(b.nom));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: _TenteSection(
              title: 'Tentes assignées',
              color: Colors.blue.shade50,
              tentes: assigned,
              controller: c,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            icon: const Icon(Icons.swap_horiz),
            label: const Text('Basculer la sélection'),
            onPressed: c.selectedTenteIds.isEmpty
                ? null
                : () async {
              await c.applyTenteChanges();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tentes mises à jour ✅')),
              );
            },
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _TenteSection(
              title: 'Tentes disponibles',
              color: Colors.green.shade50,
              tentes: available,
              controller: c,
            ),
          ),
        ],
      ),
    );
  }
}

class _TenteSection extends StatelessWidget {
  final String title;
  final Color color;
  final List<Tente> tentes;
  final EvenementDetailController controller;

  const _TenteSection({
    required this.title,
    required this.color,
    required this.tentes,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$title (${tentes.length})', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Expanded(
          child: ListView(
            children: tentes.map((t) {
              final selected = controller.selectedTenteIds.contains(t.id);
              return GestureDetector(
                onTap: () => controller.toggleTenteSelection(t.id),
                child: _TenteCard(
                  tente: t,
                  selected: selected,
                  highlightColor: color,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}



class _TenteCard extends StatelessWidget {
  final Tente tente;
  final bool selected;
  final Color? highlightColor;

  const _TenteCard({
    required this.tente,
    required this.selected,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: selected ? highlightColor ?? Colors.blue.shade50 : Colors.white,
      child: ListTile(
        leading: Icon(
          selected ? Icons.check_circle : Icons.house_siding_outlined,
          color: selected ? Colors.blue : Colors.grey,
        ),
        title: Text(tente.nom),
        subtitle: Text('${tente.typeTente} • ${tente.nbPlaces} places'),
        trailing: Text(tente.unitePreferee ?? ''),
      ),
    );
  }
}




class _MenusTab extends ConsumerWidget {
  final List<DateTime> eventDays;
  const _MenusTab({required this.eventDays});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = context.findAncestorWidgetOfExactType<EvenementDetailPage>()!;
    final c = ref.watch(evenementDetailProvider(page.eventId));

    if (c.event == null || c.currentPlan == null || c.selectedDate == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final plan = c.currentPlan!;
    final selectedDate = c.selectedDate!;
    final selectedMeal = c.selectedMeal;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DateChips(days: eventDays, selected: selectedDate, onSelected: c.changeDate),
          const SizedBox(height: 8),
          SegmentedMeal(value: selectedMeal, onChanged: c.changeMeal),
          PortionStepper(
            value: plan.portions,
            tooltip: 'Les quantités d’ingrédients sont recalculées automatiquement.',
            onChanged: c.setPortions,
          ),
          const Divider(),
          plan.items.isEmpty
              ? _EmptyState(onAdd: () => _openSelector(context,ref))
              : Column(
            children: [
              const _RecipeList(),
              const SizedBox(height: 24),

              // ✅ Boutons sous la liste
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: IconButton(
                      icon: const Icon(Icons.add_circle_sharp),
                      onPressed: () => _openSelector(context, ref),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 80),
            ],
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _openSelector(BuildContext context, WidgetRef ref) {
    final page = context.findAncestorWidgetOfExactType<EvenementDetailPage>()!;
    page._openRecipeSelector(context, ref);
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.restaurant_menu, size: 72),
          const SizedBox(height: 12),
          const Text('Aucune recette', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Ajouter des recettes'),
          ),
        ],
      ),
    );
  }
}

class _RecipeList extends ConsumerWidget {
  const _RecipeList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = context.findAncestorWidgetOfExactType<EvenementDetailPage>()!;
    final c = ref.watch(evenementDetailProvider(page.eventId));

    if (c.currentPlan == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final plan = c.currentPlan!;
    final totals = plan.totals();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: plan.items.length,
          onReorder: c.moveRecipe,
          itemBuilder: (_, i) {
            final item = plan.items[i];
            final recipeTotals = item.forPortions(plan.portions);
            return KeyedSubtree(
              key: ValueKey(item.recipe.id),
              child: RecipeTile(
                recipe: item.recipe,
                totals: recipeTotals,
                onDelete: () {
                  c.removeRecipeAt(i);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Recette supprimée: ${item.recipe.title}')),
                  );
                },
                onView: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Fiche recette'),
                      content: Text(item.recipe.title),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
                      ],
                    ),
                  );
                },
                onMove: () {
                  final target = c.selectedMeal == MealType.dejeuner ? MealType.diner : MealType.dejeuner;
                  c.duplicateTo([MapEntry(c.selectedDate!, target)]);
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('Recette déplacée (exemple)')));
                },
                onDuplicate: () {
                  c.duplicateTo([MapEntry(c.selectedDate!.add(const Duration(days: 1)), c.selectedMeal)]);
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('Menu dupliqué vers demain')));
                },
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Totaux pour le repas', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              ...totals.map(
                    (i) => Text('- ${i.name}: ${i.quantity.toStringAsFixed(2)} ${i.unit}'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BottomBarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _BottomBarButton({
    required this.icon,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      child: TextButton.icon(
        style: TextButton.styleFrom(
          foregroundColor:
          onPressed == null ? Colors.grey : Theme.of(context).colorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}


class _MenusBottomBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = context.findAncestorWidgetOfExactType<EvenementDetailPage>()!;
    final c = ref.watch(evenementDetailProvider(page.eventId));

    if (c.currentPlan == null || c.event == null) {
      return const SizedBox.shrink();
    }

    final plan = c.currentPlan!;
    final shopping = ShoppingListService();

    return BottomAppBar(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Center(child: Row(
          children: [
            _BottomBarButton(
              icon: Icons.copy,
              label: 'Dupliquer',
              onPressed: () async {
                await c.duplicateTo([
                  MapEntry(plan.date.add(const Duration(days: 1)), plan.meal)
                ]);
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Dupliqué vers demain')));
              },
            ),
            _BottomBarButton(
              icon: Icons.list_alt,
              label: 'Courses',
              onPressed: () {
                final totals = shopping.generateFor(plan);
                showModalBottomSheet(
                  context: context,
                  builder: (_) => ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      const Text('Liste de courses (repas courant)',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...totals.map(
                            (i) => ListTile(
                          title: Text(i.name),
                          trailing:
                          Text('${i.quantity.toStringAsFixed(2)} ${i.unit}'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            _BottomBarButton(
              icon: Icons.share,
              label: 'Exporter',
              onPressed: plan.items.isEmpty
                  ? null
                  : () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Partager / Imprimer (PDF) à implémenter')),
              ),
            ),
          ],
        ),
        ),

    );


  }

}

