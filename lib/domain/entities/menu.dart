import 'package:flutter/foundation.dart';
import 'recipe.dart';
import 'ingredient.dart';

enum MealType { petitDej, dejeuner, diner }

@immutable
class MenuItem {
  final int? eventMenuId;
  final int? menuId;
  final Recipe recipe;
  final List<IngredientTotal> baseIngredients;

  const MenuItem({
    this.eventMenuId,
    this.menuId,
    required this.recipe,
    required this.baseIngredients,
  });

  MenuItem copyWith({
    int? eventMenuId,
    int? menuId,
    Recipe? recipe,
    List<IngredientTotal>? baseIngredients,
  }) {
    return MenuItem(
      eventMenuId: eventMenuId ?? this.eventMenuId,
      menuId: menuId ?? this.menuId,
      recipe: recipe ?? this.recipe,
      baseIngredients: baseIngredients ?? this.baseIngredients,
    );
  }

  @override
  String toString() =>
      'MenuItem(eventMenuId: $eventMenuId, menuId: $menuId, recipe: ${recipe.title})';

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      eventMenuId: json['id'] as int?,
      recipe: Recipe.fromJson(json['menu'] ?? {}),
      menuId: json['menu_id'] as int?,
      baseIngredients: (json['menu']?['ingredients'] as List?)
          ?.map((i) => IngredientTotal.fromJson(i))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': eventMenuId,
    'menu_id': menuId,
    'menu': recipe.toJson(),
    'ingredients': baseIngredients.map((i) => i.toJson()).toList(),
  };

  List<IngredientTotal> forPortions(int portions) {
    return baseIngredients
        .map((i) => i.copyWith(quantity: i.quantity * portions))
        .toList();
  }
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
