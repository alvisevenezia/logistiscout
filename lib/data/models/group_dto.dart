import 'package:logistiscout/domain/entities/group_unit.dart';
import 'package:logistiscout/domain/entities/unit.dart';

import 'dart:developer' as developer;

class GroupDto {
  final String id;
  final String name;
  final String email;
  final String members;
  final String login;
  final String type; // 'scout' ou 'marin'
  final List<GroupUnit> units;

  GroupDto({
    required this.id,
    required this.name,
    required this.members,
    required this.email,
    required this.login,
    required this.type,
    required this.units,
  });

  factory GroupDto.fromJson(Map<String, dynamic> json) {
    return GroupDto(
      id: json['id'].toString(),
      name: json['nom'],
      members: json['membres'].toString(),
      email: json['email'],
      login: json['login'] ?? '',
      type: json['type'] ?? 'scout',
      units: (json['unites'] as List<dynamic>? ?? [])
          .map((u) => GroupUnit(
                id: u['id'].toString(),
                name: u['nom'],
                type: u['type'] ?? 'scout',
                color: u['color'] ?? '#000000',
              ))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nom': name,
    'membres': members,
    'email': email,
  };
}
