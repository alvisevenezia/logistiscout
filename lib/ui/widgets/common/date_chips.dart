import 'package:flutter/material.dart';

class DateChips extends StatelessWidget {
  final List<DateTime> days;
  final DateTime selected;
  final ValueChanged<DateTime> onSelected;

  const DateChips({
    super.key,
    required this.days,
    required this.selected,
    required this.onSelected,
  });

  String _format(DateTime d) {
    final weekday = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'][d.weekday - 1];
    return '$weekday ${d.day}/${d.month}';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: days.length,
        itemBuilder: (_, i) {
          final d = days[i];
          final isSelected = d == selected;
          return ChoiceChip(
            label: Text(_format(d)),
            selected: isSelected,
            onSelected: (_) => onSelected(d),
            selectedColor: Theme.of(context).colorScheme.primaryContainer,
            labelStyle: TextStyle(
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : null,
              fontWeight: isSelected ? FontWeight.bold : null,
            ),
          );
        },
      ),
    );
  }
}
