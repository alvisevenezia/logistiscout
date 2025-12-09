import 'package:logistiscout/domain/entities/ingredient.dart';
import 'package:logistiscout/domain/entities/menu_type.dart';
import 'package:logistiscout/domain/entities/recipe.dart';
import 'package:logistiscout/domain/repositories/recipe_repository.dart';
import 'package:logistiscout/services/api_service.dart';

class RecipeRepositoryImpl implements RecipeRepository {
  final ApiService api;

  RecipeRepositoryImpl(this.api);

  @override
  Future<List<Recipe>> search({
    String query = '',
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
        id: menu['id'],
        title: menu['title'],
        menuType: MenuType.plat,
      );
    }).toList();
  }

  @override
  Future<void> createRecipe(Recipe recipe) async {
    final payload = {
      'title': recipe.title,
      'description': recipe.description,
      'instructions': recipe.instructions ,
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
  Future<List<IngredientTotal>> getIngredientsForRecipe(int recipeId) async {
    final data = await api.getReceipe(recipeId);
    final ingredients = (data['ingredients'] as List)
        .map((i) => IngredientTotal(
      name: i['nom'],
      quantity: (i['quantite'] as num).toDouble(),
      unit: i['unite'],
    ))
        .toList();
    return ingredients;
  }

}
