import 'dart:convert';

import 'package:logistiscout/domain/entities/menu_type.dart';

class RecipeDto{

  final String id;
  final String title;
  final String description;
  final String instructions;
  final String mealType;
  /// Stored as a json string
  final String ingredients;
  /// Stored as array of strings
  final String allergens;
  /// Stored as array of strings
  final String tags;


  RecipeDto({
    required this.id,
    required this.title,
    required this.description,
    required this.instructions,
    required this.mealType,
    required this.ingredients,
    required this.allergens,
    required this.tags,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'instructions': instructions,
      'category': mealType,
      'ingredients': ingredients,
      'allergens': allergens,
      'tags': tags,
    };
  }

  factory RecipeDto.fromJson(Map<String, dynamic> json) {
    return RecipeDto(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      instructions: json['instructions'] ?? '',
      mealType: MenuType.plat.name,
      ingredients: jsonEncode(json['ingredients'] ?? []),
      allergens: jsonEncode(json['allergens'] ?? []),
      tags: jsonEncode(json['tags'] ?? []),
    );
  }

}