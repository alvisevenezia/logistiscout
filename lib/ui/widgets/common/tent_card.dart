import 'package:flutter/material.dart';
import 'package:logistiscout/domain/entities/tente.dart';
import 'package:logistiscout/domain/entities/unit.dart';

class TentCard extends StatelessWidget {
  final Tent tent;
  final VoidCallback onOpen;
  final detail;

  const TentCard({
    required this.tent,
    required this.onOpen,
    this.detail = true,
  });

  @override
  Widget build(BuildContext context) {
    final bg = Color(tent.state.bg_color);
    final chipColor = Color(tent.state.chip_color);

    return Card(
      elevation: 2,
      color: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onOpen,
        child: Padding(
          padding:  detail ? const EdgeInsets.fromLTRB(16, 24, 16, 24) : const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Color(
                  Unit.fromString(tent.assignedUnit).color,
                ),
                child: const Icon(Icons.cabin, color: Colors.white),
              ),
              const SizedBox(width: 12),
              // Infos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre + état chip
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            tent.nom,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: chipColor.withAlpha(30),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: chipColor.withAlpha(80)),
                          ),
                          child: Text(
                            tentStateToString(tent.state),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: chipColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      detail
                          ? '${tent.assignedUnit} • ${tent.tentType} • ${tent.nbPlaces} places'
                          : tent.assignedUnit,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),

                    if(detail)...[
                      const SizedBox(height: 6),
                      // Bandeau de petites pastilles couleur scotch
                      if (tent.colors.isNotEmpty)
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
                    ]


                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black45),
            ],
          ),
        ),
      ),
    );
  }

  Color _parseColor(String s) {
    try {
      if (s.startsWith('#')) {
        return Color(int.parse(s.substring(1), radix: 16) + 0xFF000000);
      }
      return Colors.grey.shade400;
    } catch (_) {
      return Colors.grey.shade400;
    }
  }
}
