import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logistiscout/ui/controllers/evenement_detail_controller.dart';
import 'recette_card.dart';

class RecipeList extends ConsumerWidget {
  final int eventId;
  const RecipeList({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(evenementDetailProvider(eventId));
    final plan = controller.currentPlan;

    if (plan == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (plan.items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('Aucune recette pour ce repas 🍽️'),
        ),
      );
    }

    return Column(
      children: [
        ...plan.items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return RecetteCard(
            item: item,
            onDelete: () => controller.removeRecipeAt(index),
          );
        }),
      ],
    );
  }
}
