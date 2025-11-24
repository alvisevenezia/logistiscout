import 'package:logistiscout/domain/entities/ingredient.dart';
import 'package:logistiscout/domain/entities/recipe.dart';
import 'package:logistiscout/domain/repositories/recipe_repository.dart';
import 'package:logistiscout/services/api_service.dart';

class RecipeRepositoryImpl implements RecipeRepository {
  final ApiService api;

  RecipeRepositoryImpl(this.api);

  @override
  Future<List<Recipe>> search({
    String query = '',
    Set<RecipeCategory>? categories,
    Set<Allergen>? allergens,
    Set<Tag>? tags,
  }) async {
    final data = await api.getMenuList();

    final filtered = data.where((menu) {
      final name = (menu['nom'] ?? '').toString().toLowerCase();
      return query.isEmpty || name.contains(query.toLowerCase());
    });

    return filtered.map((menu) {
      return Recipe(
        id: menu['id'].toString(),
        title: menu['nom'],
        category: _parseCategory(menu['type_repas']),
      );
    }).toList();
  }

  @override
  Future<void> createRecipe(Recipe recipe) async {
    final payload = {
      'nom': recipe.title,
      'description': recipe.description,
      'instructions': recipe.instructions ,
      'type_repas': recipe.category.name,
      'ingredients': recipe.ingredients
          .map((i) => {
        'nom': i.name,
        'quantite': i.quantity,
        'unite': i.unit,
      })
          .toList(),
      'allergens': recipe.allergens.map((a) => a.name).toList(),
      'tags': recipe.tags.map((t) => t.name).toList(),
    };

    await api.createMenu(payload);
  }



  @override
  Future<List<IngredientTotal>> getIngredientsForRecipe(String recipeId) async {
    final data = await api.getMenu(int.parse(recipeId));
    final ingredients = (data['ingredients'] as List)
        .map((i) => IngredientTotal(
      name: i['nom'],
      quantity: (i['quantite'] as num).toDouble(),
      unit: i['unite'],
    ))
        .toList();
    return ingredients;
  }

  RecipeCategory _parseCategory(String? raw) {
    switch (raw?.toLowerCase()) {
      case 'petitdej':
      case 'petit-déj':
      case 'petit_dej':
        return RecipeCategory.entree;
      case 'déjeuner':
      case 'dejeuner':
        return RecipeCategory.plat;
      case 'dîner':
      case 'diner':
        return RecipeCategory.dessert;
      default:
        return RecipeCategory.plat;
    }
  }
}
