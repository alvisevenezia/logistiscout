import 'package:flutter/foundation.dart';
import 'ingredient.dart'; // ✅ make sure this defines IngredientTotal or similar

enum RecipeCategory { entree, plat, dessert, boisson }
enum Allergen { gluten, lactose, arachide, soja, oeuf, poisson }
enum Tag { vege, sansPorc }

@immutable
class Recipe {
  final String id;
  final String title;
  final String description;        // 🆕 short text
  final String instructions;       // 🆕 full preparation text
  final RecipeCategory category;
  final List<IngredientTotal> ingredients; // 🆕 list of ingredients with qty/unit
  final Set<Allergen> allergens;
  final Set<Tag> tags;

  const Recipe({
    required this.id,
    required this.title,
    required this.category,
    this.description = '',
    this.instructions = '',
    this.ingredients = const [],
    this.allergens = const {},
    this.tags = const {},
  });

  // 🧭 Helpers
  Recipe copyWith({
    String? id,
    String? title,
    String? description,
    String? instructions,
    RecipeCategory? category,
    List<IngredientTotal>? ingredients,
    Set<Allergen>? allergens,
    Set<Tag>? tags,
  }) {
    return Recipe(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      instructions: instructions ?? this.instructions,
      category: category ?? this.category,
      ingredients: ingredients ?? this.ingredients,
      allergens: allergens ?? this.allergens,
      tags: tags ?? this.tags,
    );
  }

  // 🧱 Serialization (optional — useful for saving locally or via API)
  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      instructions: json['instructions'] ?? '',
      category: RecipeCategory.values.firstWhere(
            (e) => e.name == (json['category'] ?? 'plat'),
        orElse: () => RecipeCategory.plat,
      ),
      ingredients: (json['ingredients'] as List<dynamic>?)
          ?.map((i) => IngredientTotal.fromJson(i))
          .toList() ??
          const [],
      allergens: (json['allergens'] as List<dynamic>?)
          ?.map((a) => Allergen.values.firstWhere(
            (e) => e.name == a,
        orElse: () => Allergen.gluten,
      ))
          .toSet() ??
          const {},
      tags: (json['tags'] as List<dynamic>?)
          ?.map((t) => Tag.values.firstWhere(
            (e) => e.name == t,
        orElse: () => Tag.vege,
      ))
          .toSet() ??
          const {},
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'instructions': instructions,
    'category': category.name,
    'ingredients': ingredients.map((i) => i.toJson()).toList(),
    'allergens': allergens.map((a) => a.name).toList(),
    'tags': tags.map((t) => t.name).toList(),
  };
}
