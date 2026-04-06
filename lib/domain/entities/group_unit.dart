import 'package:logistiscout/domain/entities/unit.dart';

class GroupUnit {
  final String id;
  final String name;
  final int color;
  final Unit type;

  GroupUnit({
    required this.id,
    required this.name,
    required this.color,
    required this.type,
  });

  GroupUnit copyWith({String? id, String? name, int? color, Unit? type}) {
    return GroupUnit(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'color': color, 'type': type.name};
  }

  factory GroupUnit.fromJson(Map<String, dynamic> json) {
    final rawType = json['type']?.toString() ?? '';
    final rawName = json['name']?.toString() ?? '';
    final semanticType = Unit.fromString(rawName);
    final parsedType = Unit.fromString(rawType);

    return GroupUnit(
      id: json['id'].toString(),
      name: rawName,
      color: (json['color'] as num?)?.toInt() ?? Unit.fromString(rawName).color,
      type: (rawType == 'base' || rawType == 'custom')
          ? semanticType
          : parsedType,
    );
  }
}
