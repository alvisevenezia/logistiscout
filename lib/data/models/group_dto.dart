import 'package:logistiscout/domain/entities/group_unit.dart';
import 'package:logistiscout/domain/entities/tent_status.dart';
import 'package:logistiscout/domain/entities/unit.dart';

class GroupDto {
  final String id;
  final String name;
  final String email;
  final String members;
  final String login;
  final String type; // 'scout' ou 'marin'
  final List<GroupUnit> units;
  final List<TentStatusRef> tentStatuses;
  final bool unitsMigrationPerformed;

  GroupDto({
    required this.id,
    required this.name,
    required this.members,
    required this.email,
    required this.login,
    required this.type,
    required this.units,
    required this.tentStatuses,
    this.unitsMigrationPerformed = false,
  });

  factory GroupDto.fromJson(Map<String, dynamic> json) {
    return GroupDto(
      id: json['id'].toString(),
      name: json['name'],
      members: json['members'].toString(),
      email: json['email']?.toString() ?? '',
      login: json['login'] ?? '',
      type: json['type'] ?? 'scout',
      unitsMigrationPerformed: json['unitsMigrationPerformed'] == true,
      units: (json['units'] as List<dynamic>? ?? [])
          .map(
            (u) => GroupUnit(
              id: u['id'].toString(),
              name: u['name'],
              type: Unit.fromString(
                u['name']?.toString() ?? u['type']?.toString() ?? '',
              ),
              color: parseColor(
                u['color'],
                fallbackName: u['name']?.toString(),
              ),
            ),
          )
          .toList(),
      tentStatuses: (json['tentStatuses'] as List<dynamic>? ?? [])
          .map((s) => TentStatusRef.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'members': members,
    'email': email,
    'login': login,
    'type': type,
    'unitsMigrationPerformed': unitsMigrationPerformed,
    'tentStatuses': tentStatuses.map((s) => s.toJson()).toList(),
    'units': units
        .map(
          (u) => {
            'id': u.id,
            'name': u.name,
            // Backend v2 expects "base" or "custom" only.
            'type': 'custom',
            'color': u.color,
          },
        )
        .toList(),
  };
}

int parseColor(dynamic color, {String? fallbackName}) {
  if (color is int) {
    if (color == 0xFF000000 && (fallbackName?.isNotEmpty ?? false)) {
      return Unit.fromString(fallbackName!).color;
    }
    return color;
  }
  if (color is String) {
    final raw = color.trim();
    final decimal = int.tryParse(raw);
    if (decimal != null) {
      if (decimal == 0xFF000000 && (fallbackName?.isNotEmpty ?? false)) {
        return Unit.fromString(fallbackName!).color;
      }
      return decimal;
    }

    final hex = raw
        .replaceAll('#', '')
        .replaceFirst(RegExp(r'^0x', caseSensitive: false), '');
    if (hex.isNotEmpty) {
      if (hex.length == 6) {
        return int.parse('FF$hex', radix: 16);
      }
      if (hex.length == 8) {
        final parsed = int.parse(hex, radix: 16);
        if (parsed == 0xFF000000 && (fallbackName?.isNotEmpty ?? false)) {
          return Unit.fromString(fallbackName!).color;
        }
        return parsed;
      }
    }
  }
  if (fallbackName != null && fallbackName.isNotEmpty) {
    return Unit.fromString(fallbackName).color;
  }
  return 0xFF000000;
}
