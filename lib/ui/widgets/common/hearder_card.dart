import 'package:flutter/material.dart';
import 'package:logistiscout/domain/entities/tente.dart';
import 'package:logistiscout/domain/entities/unit.dart';

class HeaderCard extends StatelessWidget {
  final Tent tent;
  const HeaderCard({super.key, required this.tent});

  @override
  Widget build(BuildContext context) {
    final chipColor = _chipColor(tent.state);

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Color(Unit.fromString(tent.assignedUnit).color),
              child: const Icon(Icons.cabin, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          tent.nom,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: chipColor.withAlpha(30),
                          border: Border.all(color: chipColor.withAlpha(80)),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          tentStateToString(tent.state),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: chipColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${tent.tentType} • ${tent.nbPlaces} places'
                        '${tent.assignedUnit.isNotEmpty ? ' • ${tent.assignedUnit}' : ''}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (tent.colors.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      children: tent.colors.take(6).map((c) {
                        return Container(
                          width: 16,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _parseColor(c),
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Color _chipColor(TentState e) {
    switch (e) {
      case TentState.good :
        return Colors.green.shade700;
      case TentState.broken:
        return Colors.orange.shade700;
      default:
        return Colors.red.shade700;
    }
  }

  static Color _parseColor(String s) {
    try {
      if (s.startsWith('#')) {
        return Color(int.parse(s.substring(1), radix: 16) + 0xFF000000);
      }
    } catch (_) {}
    return Colors.grey.shade400;
  }
}