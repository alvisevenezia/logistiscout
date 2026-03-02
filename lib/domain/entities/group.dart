import 'package:logistiscout/domain/entities/group_unit.dart';

class Group {
  final String id;
  final String name;
  final String email;
  final String members;
  final String login;
  final String type; // 'scout' ou 'marin'
  final List<GroupUnit> units;

  Group({
    required this.id,
    required this.name,
    required this.email,
    required this.members,
    required this.login,
    required this.type,
    required this.units,
  });

  Group copyWith({
    String? id,
    String? name,
    String? email,
    String? members,
    String? login,
    String? type,
    List<GroupUnit>? units,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      members: members ?? this.members,
      login: login ?? this.login,
      type: type ?? this.type,
      units: units ?? this.units,
    );
  }

  // JSON si tu utilises une API
  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      members: json['members'],
      login: json['login'],
      type: json['type'],
      units: (json['units'] as List<dynamic>)
          .map((e) => GroupUnit.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'members': members,
      'login': login,
      'type': type,
      'units': units.map((u) => u.toJson()).toList(),
    };
  }
}