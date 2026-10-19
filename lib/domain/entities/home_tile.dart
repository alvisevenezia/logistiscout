import 'package:logistiscout/domain/entities/tent_status.dart';
import 'package:logistiscout/domain/entities/tente.dart';

enum HomeTileKind {
  tents('tents'),
  operational('operational'),
  repair('repair'),
  outings('outings'),
  usedTents('used_tents'),
  custom('custom');

  const HomeTileKind(this.jsonValue);

  final String jsonValue;

  static HomeTileKind fromJson(Object? value) {
    return HomeTileKind.values.firstWhere(
      (k) => k.jsonValue == value,
      orElse: () => HomeTileKind.custom,
    );
  }
}

/// Une vignette de l'aperçu de l'accueil.
///
/// Les vignettes d'origine (tout sauf [HomeTileKind.custom]) ont leur libellé,
/// couleur et icône fixés par l'app ; le groupe choisit seulement l'ordre, la
/// visibilité et, pour « Opérationnelles », les statuts comptés.
class HomeTile {
  final String id;
  final HomeTileKind kind;
  final bool visible;
  final String? title;
  final String? subtitle;
  final int? color;
  final String? icon;

  /// Statuts comptés. Vide : tous (vignette perso) ou la règle par défaut
  /// (« Opérationnelles » = total - à réparer).
  final List<int> statusIds;

  /// Types de matériel comptés (Canadienne, Tipi…). Vide : tous.
  final List<String> tentTypes;

  const HomeTile({
    required this.id,
    required this.kind,
    this.visible = true,
    this.title,
    this.subtitle,
    this.color,
    this.icon,
    this.statusIds = const [],
    this.tentTypes = const [],
  });

  bool get isCustom => kind == HomeTileKind.custom;

  static const defaults = [
    HomeTile(id: 'tents', kind: HomeTileKind.tents),
    HomeTile(id: 'operational', kind: HomeTileKind.operational),
    HomeTile(id: 'repair', kind: HomeTileKind.repair),
    HomeTile(id: 'outings', kind: HomeTileKind.outings),
    HomeTile(id: 'used_tents', kind: HomeTileKind.usedTents, visible: false),
  ];

  HomeTile copyWith({
    bool? visible,
    String? title,
    String? subtitle,
    int? color,
    String? icon,
    List<int>? statusIds,
    List<String>? tentTypes,
  }) {
    return HomeTile(
      id: id,
      kind: kind,
      visible: visible ?? this.visible,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      statusIds: statusIds ?? this.statusIds,
      tentTypes: tentTypes ?? this.tentTypes,
    );
  }

  factory HomeTile.fromJson(Map<String, dynamic> json) {
    return HomeTile(
      id: json['id']?.toString() ?? '',
      kind: HomeTileKind.fromJson(json['kind']),
      visible: json['visible'] != false,
      title: json['title'] as String?,
      subtitle: json['subtitle'] as String?,
      color: (json['color'] as num?)?.toInt(),
      icon: json['icon'] as String?,
      statusIds: (json['statusIds'] as List<dynamic>? ?? const [])
          .map((e) => (e as num).toInt())
          .toList(),
      tentTypes: (json['tentTypes'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kind': kind.jsonValue,
      'visible': visible,
      'title': title,
      'subtitle': subtitle,
      'color': color,
      'icon': icon,
      'statusIds': statusIds,
      'tentTypes': tentTypes,
    };
  }
}

/// Données de l'accueil nécessaires au calcul des vignettes.
class HomeOverviewData {
  final List<Tent> tents;
  final List<TentStatusRef> statuses;
  final int upcomingEventsCount;
  final int usedTentsCount;

  const HomeOverviewData({
    required this.tents,
    required this.statuses,
    required this.upcomingEventsCount,
    required this.usedTentsCount,
  });
}

int homeTileCount(HomeTile tile, HomeOverviewData data) {
  switch (tile.kind) {
    case HomeTileKind.tents:
      return data.tents.length;
    case HomeTileKind.repair:
      return tentsNeedingRepair(data.tents, data.statuses).length;
    case HomeTileKind.outings:
      return data.upcomingEventsCount;
    case HomeTileKind.usedTents:
      return data.usedTentsCount;
    case HomeTileKind.operational:
      if (tile.statusIds.isEmpty) {
        return data.tents.length -
            tentsNeedingRepair(data.tents, data.statuses).length;
      }
      return _countMatching(data.tents, tile);
    case HomeTileKind.custom:
      return _countMatching(data.tents, tile);
  }
}

int _countMatching(List<Tent> tents, HomeTile tile) {
  final statusIds = tile.statusIds.toSet();
  final types = tile.tentTypes.toSet();
  return tents.where((t) {
    if (statusIds.isNotEmpty && !statusIds.contains(t.tentStatusId)) {
      return false;
    }
    if (types.isNotEmpty && !types.contains(t.tentType)) return false;
    return true;
  }).length;
}
