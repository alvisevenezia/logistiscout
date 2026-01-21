import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logistiscout/ui/controllers/evenement_detail_controller.dart';
import 'package:logistiscout/ui/pages/event/evenement_detail_page.dart';
import 'package:logistiscout/ui/pages/event/widgets/add_recipe_button.dart';
import 'package:logistiscout/ui/pages/event/widgets/recipe_list.dart';
import 'package:logistiscout/ui/widgets/common/date_chips.dart';
import 'package:logistiscout/ui/widgets/common/segmented_meal.dart';
import 'package:logistiscout/ui/widgets/menus/portion_stepper.dart';

class MenusTab extends ConsumerWidget {
  final List<DateTime> eventDays;
  const MenusTab({super.key, required this.eventDays});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = context.findAncestorWidgetOfExactType<EventDetailPage>()!;
    final controller = ref.watch(evenementDetailProvider(page.eventId));

    if (controller.loading || controller.currentPlan == null || controller.event == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final plan = controller.currentPlan!;
    final selectedDate = controller.dayOffset;
    final selectedMeal = controller.selectedMeal;

    return RefreshIndicator(
      onRefresh: () async { 
          await controller.changeOffset(selectedDate);
        },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DateChips(
                days: eventDays,
                selected: selectedDate,
                onSelected: controller.changeOffset,
              ),
              const SizedBox(height: 8),
              SegmentedMeal(value: selectedMeal, onChanged: controller.changeMeal),
              PortionStepper(
                value: plan.portions,
                tooltip: 'Les quantités d’ingrédients sont recalculées automatiquement.',
                onChanged: controller.setPortions,
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              RecipeList(eventId: page.eventId),
              const SizedBox(height: 24),
              AddRecipeButton(eventId: page.eventId),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
