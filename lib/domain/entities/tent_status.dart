import 'package:logistiscout/domain/entities/tente.dart';

class TentStatusRef {
  final int id;
  final String name;
  final int color;
  final int order;
  final bool isDefault;
  final bool isArchived;

  /// Les tentes ayant ce statut apparaissent dans « Tentes à réparer ».
  final bool needsRepair;

  const TentStatusRef({
    required this.id,
    required this.name,
    required this.color,
    required this.order,
    required this.isDefault,
    required this.isArchived,
    this.needsRepair = false,
  });

  TentStatusRef copyWith({
    int? id,
    String? name,
    int? color,
    int? order,
    bool? isDefault,
    bool? isArchived,
    bool? needsRepair,
  }) {
    return TentStatusRef(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      order: order ?? this.order,
      isDefault: isDefault ?? this.isDefault,
      isArchived: isArchived ?? this.isArchived,
      needsRepair: needsRepair ?? this.needsRepair,
    );
  }

  factory TentStatusRef.fromJson(Map<String, dynamic> json) {
    final name = json['name']?.toString() ?? '';
    final needsRepair = json['needsRepair'];
    return TentStatusRef(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: name,
      color: (json['color'] as num?)?.toInt() ?? 0xFF9E9E9E,
      order: (json['order'] as num?)?.toInt() ?? 0,
      isDefault: json['isDefault'] == true,
      isArchived: json['isArchived'] == true,
      needsRepair: needsRepair is bool
          ? needsRepair
          : legacyNeedsRepairFromLabel(name),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'order': order,
      'isDefault': isDefault,
      'isArchived': isArchived,
      'needsRepair': needsRepair,
    };
  }
}

/// Déduction à partir du libellé, pour les données qui ne portent pas encore
/// `needsRepair` (cache local ou API antérieurs).
bool legacyNeedsRepairFromLabel(String label) {
  final normalized = label.trim().toLowerCase();
  return normalized.isNotEmpty &&
      !const {'bon', 'ok', 'good', 'perdue', 'lost'}.contains(normalized);
}

List<Tent> tentsNeedingRepair(
  List<Tent> tents,
  List<TentStatusRef> statuses,
) {
  final byId = {for (final s in statuses) s.id: s};
  return tents.where((tent) {
    final status = byId[tent.tentStatusId];
    if (status != null) return status.needsRepair;
    return legacyNeedsRepairFromLabel(tent.displayStatusLabel);
  }).toList();
}
