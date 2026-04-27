import 'dart:convert';

import 'package:logistiscout/data/models/receipe_dto.dart';
import 'package:logistiscout/domain/entities/ingredient.dart';
import 'package:logistiscout/domain/entities/menu_type.dart';
import 'package:logistiscout/domain/entities/recipe.dart';

RecipeDto recipeToDto(Recipe recipe) {
  return RecipeDto(
    id: recipe.id.toString(),
    title: recipe.title,
    description: recipe.description,
    ingredients: json.encode(recipe.ingredients),
    instructions: recipe.instructions,
    mealType: recipe.menuType.name,
    allergens: '',
    tags: '',
  );
}

Recipe recipeDtoToRecipe(RecipeDto dto) {
  final ingredientsList = json.decode(dto.ingredients) as List<dynamic>;
  final ingredients = ingredientsList.map((i) {
    final ingredientMap = i as Map<String, dynamic>;
    return IngredientTotal(
      name: ingredientMap['name'] ?? 'Ingrédient inconnu',
      quantity: (ingredientMap['quantity'] as num?)?.toDouble() ?? 0,
      unit: ingredientMap['unit'] ?? '',
    );
  }).toList();

  return Recipe(
    id: int.parse(dto.id),
    title: dto.title,
    description: dto.description,
    instructions: dto.instructions,
    menuType: MenuType.values.firstWhere((e) => e.name == dto.mealType),
    ingredients: ingredients,
  );
}