class TentStatusRef {
  final int id;
  final String name;
  final int color;
  final int order;
  final bool isDefault;
  final bool isArchived;

  const TentStatusRef({
    required this.id,
    required this.name,
    required this.color,
    required this.order,
    required this.isDefault,
    required this.isArchived,
  });

  TentStatusRef copyWith({
    int? id,
    String? name,
    int? color,
    int? order,
    bool? isDefault,
    bool? isArchived,
  }) {
    return TentStatusRef(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      order: order ?? this.order,
      isDefault: isDefault ?? this.isDefault,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  factory TentStatusRef.fromJson(Map<String, dynamic> json) {
    return TentStatusRef(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      color: (json['color'] as num?)?.toInt() ?? 0xFF9E9E9E,
      order: (json['order'] as num?)?.toInt() ?? 0,
      isDefault: json['isDefault'] == true,
      isArchived: json['isArchived'] == true,
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
    };
  }
}
