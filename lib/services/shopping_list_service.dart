import 'package:logistiscout/domain/entities/ingredient.dart';
import 'package:logistiscout/domain/entities/menu.dart';

/// Utility to generate aggregated ingredient totals for a meal plan.
class ShoppingListService {
  /// Returns the list of total ingredients for a single [MealPlan].
  List<IngredientTotal> generateFor(MealPlan plan) {
    final totals = <String, IngredientTotal>{};

    for (final item in plan.items) {
      for (final ing in item.forPortions(plan.portions)) {
        if (totals.containsKey(ing.name)) {
          final existing = totals[ing.name]!;
          totals[ing.name] = IngredientTotal(
            name: ing.name,
            quantity: existing.quantity + ing.quantity,
            unit: ing.unit,
          );
        } else {
          totals[ing.name] = ing;
        }
      }
    }

    return totals.values.toList();
  }
}
