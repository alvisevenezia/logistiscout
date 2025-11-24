import '../entities/recipe.dart';
import '../entities/ingredient.dart';

abstract class RecipeRepository {
  Future<List<Recipe>> search({
    String query = '',
    Set<RecipeCategory>? categories,
    Set<Allergen>? allergens,
    Set<Tag>? tags,
  });
  Future<List<IngredientTotal>> getIngredientsForRecipe(String recipeId);
  Future<void> createRecipe(Recipe recipe);
}
