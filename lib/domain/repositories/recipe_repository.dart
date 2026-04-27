import '../entities/recipe.dart';
import '../entities/ingredient.dart';

abstract class RecipeRepository {
  Future<List<Recipe>> search({
    String query = '',
    Set<Allergen>? allergens,
    Set<Tag>? tags,
  });
  Future<List<IngredientTotal>> getIngredientsForRecipe(int recipeId);
  Future<void> createRecipe(Recipe recipe);
}
