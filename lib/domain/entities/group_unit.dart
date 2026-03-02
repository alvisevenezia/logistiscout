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

  GroupUnit copyWith({
    String? id,
    String? name,
    int? color,
    Unit? type,
  }) {
    return GroupUnit(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      type: type ?? this.type,
    );
  }

  // Si tu stockes en JSON :
  factory GroupUnit.fromJson(Map<String, dynamic> json) {
    return GroupUnit(
      id: json['id'],
      name: json['name'],
      color: json['color'],
      type: Unit.fromInt(json['type']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'type': Unit.toInt(type),
    };
  }
}