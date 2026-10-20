import 'package:flutter/material.dart';
import 'package:logistiscout/domain/entities/home_tile.dart';

class HomeStatCardData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;

  const HomeStatCardData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.colors,
  });
}

/// Couleurs proposées pour les vignettes perso : (début, fin) du dégradé.
const homeTilePalette = <int, int>{
  0xFF1D4ED8: 0xFF60A5FA,
  0xFF047857: 0xFF34D399,
  0xFFB45309: 0xFFF59E0B,
  0xFF0E7490: 0xFF22D3EE,
  0xFF7C3AED: 0xFFA78BFA,
  0xFF9F1239: 0xFFFB7185,
};

const homeTileIcons = <String, IconData>{
  'water': Icons.water_drop,
  'tent': Icons.cabin,
  'repair': Icons.build_circle,
  'check': Icons.check_circle,
  'block': Icons.block,
  'event': Icons.event_available,
};

const defaultCustomTileColor = 0xFF0E7490;
const defaultCustomTileIcon = 'water';

List<Color> homeTileGradient(int color) {
  final end = homeTilePalette[color];
  return [
    Color(color),
    end != null
        ? Color(end)
        : Color.lerp(Color(color), Colors.white, 0.35)!,
  ];
}

/// Libellé, icône et couleurs d'une vignette telle qu'affichée sur l'accueil.
HomeStatCardData homeStatCardFor(HomeTile tile, HomeOverviewData data) {
  final value = homeTileCount(tile, data).toString();
  switch (tile.kind) {
    case HomeTileKind.tents:
      return HomeStatCardData(
        title: 'Tentes',
        value: value,
        subtitle: 'au total',
        icon: Icons.cabin,
        colors: const [Color(0xFF1D4ED8), Color(0xFF60A5FA)],
      );
    case HomeTileKind.operational:
      return HomeStatCardData(
        title: 'Opérationnelles',
        value: value,
        subtitle: 'prêtes à partir',
        icon: Icons.check_circle,
        colors: const [Color(0xFF047857), Color(0xFF34D399)],
      );
    case HomeTileKind.repair:
      return HomeStatCardData(
        title: 'À réparer',
        value: value,
        subtitle: 'à surveiller',
        icon: Icons.build_circle,
        colors: const [Color(0xFFB45309), Color(0xFFF59E0B)],
      );
    case HomeTileKind.outings:
      return HomeStatCardData(
        title: 'Sorties',
        value: value,
        subtitle: '${data.usedTentsCount} tentes utilisées',
        icon: Icons.event_available,
        colors: const [Color(0xFF7C3AED), Color(0xFFA78BFA)],
      );
    case HomeTileKind.usedTents:
      return HomeStatCardData(
        title: 'Tentes utilisées',
        value: value,
        subtitle: 'prochaines sorties',
        icon: Icons.cabin,
        colors: const [Color(0xFF0369A1), Color(0xFF38BDF8)],
      );
    case HomeTileKind.items:
      return HomeStatCardData(
        title: 'Matériel',
        value: value,
        subtitle: '${data.itemsToRepairCount} à réparer',
        icon: Icons.backpack,
        colors: const [Color(0xFF0E7490), Color(0xFF22D3EE)],
      );
    case HomeTileKind.issues:
      return HomeStatCardData(
        title: 'Signalements',
        value: value,
        subtitle: 'ouverts',
        icon: Icons.report_problem,
        colors: const [Color(0xFF9F1239), Color(0xFFFB7185)],
      );
    case HomeTileKind.custom:
      return HomeStatCardData(
        title: tile.title ?? '',
        value: value,
        subtitle: tile.subtitle ?? '',
        icon: homeTileIcons[tile.icon] ?? Icons.cabin,
        colors: homeTileGradient(tile.color ?? defaultCustomTileColor),
      );
  }
}

class HomeStatCard extends StatelessWidget {
  final HomeStatCardData data;

  const HomeStatCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: data.colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(data.icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  data.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  data.value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  data.subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
