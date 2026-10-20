/// Mode de suivi d'un type de matériel.
enum ItemTracking {
  piece('piece'),
  quantity('quantity'),
  consumable('consumable');

  const ItemTracking(this.jsonValue);

  final String jsonValue;

  static ItemTracking fromJson(Object? value) {
    return ItemTracking.values.firstWhere(
      (t) => t.jsonValue == value,
      orElse: () => ItemTracking.piece,
    );
  }
}

/// Champ propre à un type (volume d'un jerrican, nombre de feux…).
class ItemTypeField {
  final String key;
  final String label;
  final bool isNumber;

  const ItemTypeField({
    required this.key,
    required this.label,
    this.isNumber = false,
  });

  factory ItemTypeField.fromJson(Map<String, dynamic> json) {
    return ItemTypeField(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      isNumber: json['kind'] == 'number',
    );
  }
}

/// Type du catalogue de base (Jerrican, Vaisselle, Cartouches de gaz…).
class ItemType {
  final String key;
  final String name;
  final String family;
  final ItemTracking tracking;
  final String icon;
  final List<ItemTypeField> fields;

  const ItemType({
    required this.key,
    required this.name,
    required this.family,
    required this.tracking,
    required this.icon,
    this.fields = const [],
  });

  factory ItemType.fromJson(Map<String, dynamic> json) {
    return ItemType(
      key: json['key']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      family: json['family']?.toString() ?? '',
      tracking: ItemTracking.fromJson(json['tracking']),
      icon: json['icon']?.toString() ?? '',
      fields: (json['fields'] as List<dynamic>? ?? const [])
          .map((f) => ItemTypeField.fromJson(f as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// État d'usage, déduit des signalements ouverts (jamais saisi).
enum ItemUsage {
  ok('ok'),
  repair('repair'),
  out('out');

  const ItemUsage(this.jsonValue);

  final String jsonValue;

  static ItemUsage fromJson(Object? value) {
    return ItemUsage.values.firstWhere(
      (u) => u.jsonValue == value,
      orElse: () => ItemUsage.ok,
    );
  }
}

/// Matériel hors tentes : une pièce suivie (quantité 1) ou un lot.
class Item {
  final int id;
  final String typeKey;
  final String nom;
  final int quantity;
  final int? statusId;
  final int? uniteId;
  final String localisation;
  final String equipe;
  final bool isConsumable;
  final int? threshold;
  final List<String> colors;
  final String remarques;
  final Map<String, dynamic> fields;

  final ItemUsage usage;
  final int usableQuantity;
  final int openIssues;

  const Item({
    required this.id,
    required this.typeKey,
    required this.nom,
    this.quantity = 1,
    this.statusId,
    this.uniteId,
    this.localisation = '',
    this.equipe = '',
    this.isConsumable = false,
    this.threshold,
    this.colors = const [],
    this.remarques = '',
    this.fields = const {},
    this.usage = ItemUsage.ok,
    this.usableQuantity = 1,
    this.openIssues = 0,
  });

  /// Consommable passé sous son seuil.
  bool get needsRestock =>
      isConsumable && threshold != null && quantity <= threshold!;

  factory Item.fromJson(Map<String, dynamic> json) {
    final quantity = (json['quantity'] as num?)?.toInt() ?? 1;
    return Item(
      id: (json['id'] as num?)?.toInt() ?? 0,
      typeKey: json['typeKey']?.toString() ?? 'autre',
      nom: json['nom']?.toString() ?? '',
      quantity: quantity,
      statusId: (json['statusId'] as num?)?.toInt(),
      uniteId: (json['uniteId'] as num?)?.toInt(),
      localisation: json['localisation']?.toString() ?? '',
      equipe: json['equipe']?.toString() ?? '',
      isConsumable: json['isConsumable'] == true,
      threshold: (json['threshold'] as num?)?.toInt(),
      colors: (json['couleurs'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      remarques: json['remarques']?.toString() ?? '',
      fields: Map<String, dynamic>.from(
        json['fields'] as Map<dynamic, dynamic>? ?? const {},
      ),
      usage: ItemUsage.fromJson(json['usage']),
      usableQuantity: (json['usableQuantity'] as num?)?.toInt() ?? quantity,
      openIssues: (json['openIssues'] as num?)?.toInt() ?? 0,
    );
  }

  /// Champs modifiables envoyés à l'API (création et mise à jour).
  Map<String, dynamic> toJson() {
    return {
      'typeKey': typeKey,
      'nom': nom,
      'quantity': quantity,
      'statusId': statusId,
      'uniteId': uniteId,
      'localisation': localisation,
      'equipe': equipe,
      'isConsumable': isConsumable,
      'threshold': threshold,
      'couleurs': colors,
      'remarques': remarques,
      'fields': fields,
    };
  }

  /// Les champs nullables se passent par fonction pour pouvoir les vider.
  Item copyWith({
    String? typeKey,
    String? nom,
    int? quantity,
    int? Function()? statusId,
    int? Function()? uniteId,
    String? localisation,
    String? equipe,
    bool? isConsumable,
    int? Function()? threshold,
    List<String>? colors,
    String? remarques,
    Map<String, dynamic>? fields,
  }) {
    return Item(
      id: id,
      typeKey: typeKey ?? this.typeKey,
      nom: nom ?? this.nom,
      quantity: quantity ?? this.quantity,
      statusId: statusId != null ? statusId() : this.statusId,
      uniteId: uniteId != null ? uniteId() : this.uniteId,
      localisation: localisation ?? this.localisation,
      equipe: equipe ?? this.equipe,
      isConsumable: isConsumable ?? this.isConsumable,
      threshold: threshold != null ? threshold() : this.threshold,
      colors: colors ?? this.colors,
      remarques: remarques ?? this.remarques,
      fields: fields ?? this.fields,
      usage: usage,
      usableQuantity: usableQuantity,
      openIssues: openIssues,
    );
  }
}
