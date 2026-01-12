import 'package:flutter/foundation.dart';

enum MealType { petitDej, dejeuner, diner }

/// Represents a menu item associated with an event.
@immutable
class MenuItem {
  final int id;
  final int eventId;
  final int recipeId;
  final int dayNumber;
  final MealType mealType;
  final int portions;

  const MenuItem({
    required this.id,
    required this.eventId,
    required this.recipeId,
    required this.dayNumber,
    required this.mealType,
    required this.portions,
  });

  MenuItem copyWith({
    int? id,
    int? eventMenuId,
    int? menuId,
    int? dayNumber,
    MealType? mealType,
    int? portions,
  }) {
    return MenuItem(
      id: id ?? this.id,
      eventId: eventMenuId ?? eventId,
      recipeId: menuId ?? recipeId,
      dayNumber: dayNumber ?? this.dayNumber,
      mealType: mealType ?? this.mealType,
      portions: portions ?? this.portions,
    );
  }
}


@immutable
/// Represents a meal plan for a specific date and meal type.
///
/// EN db en on stocke les menus dans une table avec la forme menu_item_dto, ici on veut les assembler en un plan de repas constituer des info du repas et des menus associés (un pour entrée, un pour plat, etc)
class MealPlan {
  /// The ID of the event this meal plan is associated with.
  final int eventId;
  /// The day number within the event.
  final int dayNumber;
  /// The type of meal (e.g., breakfast, lunch, dinner).
  final MealType mealType;
  /// The number of portions for this meal plan.
  final int portions;
  /// The list of menu items included in this meal plan.
  final List<MenuItem> items;

  const MealPlan({
    required this.eventId,
    required this.dayNumber,
    required this.mealType,
    required this.portions,
    required this.items,
  });

  factory MealPlan.empty() {
    return MealPlan(
      eventId: -1,
      dayNumber: -1,
      mealType: MealType.dejeuner,
      portions: 1,
      items: const [],
    );
  }

  MealPlan copyWith({
    int? eventId,
    int? dayNumber,
    MealType? meal,
    int? portions,
    List<MenuItem>? items,
  }) {
    return MealPlan(
      eventId: eventId ?? this.eventId,
      dayNumber: dayNumber ?? this.dayNumber,
      mealType: meal ?? mealType,
      portions: portions ?? this.portions,
      items: items ?? this.items,
    );
  }
}
