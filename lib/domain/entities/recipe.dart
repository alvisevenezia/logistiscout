import 'package:flutter/foundation.dart';
import 'package:logistiscout/domain/entities/menu_type.dart';
import 'ingredient.dart';

enum Allergen { gluten, lactose, arachide, soja, oeuf, poisson }
enum Tag {
  vegetarian,
  noPork
}

@immutable
class Recipe {
  final int id;
  final String title;
  final String description;
  final String instructions;
  final MenuType menuType;
  final List<IngredientTotal> ingredients;
  final Set<Allergen> allergens;
  final Set<Tag> tags;

  const Recipe({
    required this.id,
    required this.title,
    required this.menuType,
    this.description = '',
    this.instructions = '',
    this.ingredients = const [],
    this.allergens = const {},
    this.tags = const {},
  });

  // 🧭 Helpers
  Recipe copyWith({
    int? id,
    String? title,
    String? description,
    String? instructions,
    List<IngredientTotal>? ingredients,
    Set<Allergen>? allergens,
    Set<Tag>? tags,
  }) {
    return Recipe(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      menuType: menuType,
      instructions: instructions ?? this.instructions,
      ingredients: ingredients ?? this.ingredients,
      allergens: allergens ?? this.allergens,
      tags: tags ?? this.tags,
    );
  }
}
