import 'package:flutter/material.dart';

class PortionStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final String tooltip;

  const PortionStepper({
    super.key,
    required this.value,
    required this.onChanged,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          const Text('Couverts :'),
          const SizedBox(width: 8),
          Tooltip(
            message: tooltip,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: value > 1 ? () => onChanged(value - 1) : null,
                ),
                SizedBox(
                  width: 48,
                  child: Text(
                    '$value',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => onChanged(value + 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
