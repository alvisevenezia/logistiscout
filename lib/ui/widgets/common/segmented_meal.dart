import 'package:flutter/material.dart';
import 'package:logistiscout/domain/entities/menu.dart';

class SegmentedMeal extends StatelessWidget {
  final MealType value;
  final ValueChanged<MealType> onChanged;

  const SegmentedMeal({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SegmentedButton<MealType>(
        segments: const [
          ButtonSegment(value: MealType.petitDej, label: Text('Petit-déj')),
          ButtonSegment(value: MealType.dejeuner, label: Text('Déjeuner')),
          ButtonSegment(value: MealType.diner, label: Text('Dîner')),
        ],
        selected: {value},
        onSelectionChanged: (v) => onChanged(v.first),
        style: ButtonStyle(
          padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 12)),
        ),
      ),
    );
  }
}
