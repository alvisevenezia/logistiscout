import 'package:flutter/foundation.dart';
import 'recipe.dart';
import 'ingredient.dart';

enum MealType { petitDej, dejeuner, diner }

@immutable
class MenuItem {
  final Recipe recipe;
  final List<IngredientTotal> baseIngredients; // pour 1 portion

  const MenuItem({
    required this.recipe,
    this.baseIngredients = const [],
  });

  List<IngredientTotal> forPortions(int portions) =>
      baseIngredients.map((i) => i.scale(portions.toDouble())).toList();
}

@immutable
class MealPlan {
  final DateTime date;
  final MealType meal;
  final int portions;
  final List<MenuItem> items;

  const MealPlan({
    required this.date,
    required this.meal,
    required this.portions,
    required this.items,
  });

  factory MealPlan.empty() {
    return MealPlan(
      date: DateTime.now(),
      meal: MealType.dejeuner,
      portions: 1,
      items: const [],
    );
  }

  MealPlan copyWith({
    DateTime? date,
    MealType? meal,
    int? portions,
    List<MenuItem>? items,
  }) {
    return MealPlan(
      date: date ?? this.date,
      meal: meal ?? this.meal,
      portions: portions ?? this.portions,
      items: items ?? this.items,
    );
  }

  List<IngredientTotal> totals() {
    final Map<String, IngredientTotal> agg = {};
    for (final item in items) {
      for (final ing in item.forPortions(portions)) {
        final key = '${ing.name}:${ing.unit}';
        if (!agg.containsKey(key)) {
          agg[key] = ing;
        } else {
          final cur = agg[key]!;
          agg[key] = IngredientTotal(
            name: cur.name,
            unit: cur.unit,
            quantity: cur.quantity + ing.quantity,
          );
        }
      }
    }
    return agg.values.toList();
  }
}
