import 'package:logistiscout/domain/entities/group_unit.dart';
import 'package:logistiscout/domain/entities/tent_status.dart';

class Group {
  final String id;
  final String name;
  final String email;
  final String members;
  final String login;
  final String type; // 'scout' ou 'marin'
  final List<GroupUnit> units;
  final List<TentStatusRef> tentStatuses;
  final bool unitsMigrationPerformed;

  Group({
    required this.id,
    required this.name,
    required this.email,
    required this.members,
    required this.login,
    required this.type,
    required this.units,
    required this.tentStatuses,
    this.unitsMigrationPerformed = false,
  });

  Group copyWith({
    String? id,
    String? name,
    String? email,
    String? members,
    String? login,
    String? type,
    List<GroupUnit>? units,
    List<TentStatusRef>? tentStatuses,
    bool? unitsMigrationPerformed,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      members: members ?? this.members,
      login: login ?? this.login,
      type: type ?? this.type,
      units: units != null
          ? List<GroupUnit>.from(units)
          : List<GroupUnit>.from(this.units),
      tentStatuses: tentStatuses != null
          ? List<TentStatusRef>.from(tentStatuses)
          : List<TentStatusRef>.from(this.tentStatuses),
      unitsMigrationPerformed:
          unitsMigrationPerformed ?? this.unitsMigrationPerformed,
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
      'tentStatuses': tentStatuses.map((s) => s.toJson()).toList(),
      'unitsMigrationPerformed': unitsMigrationPerformed,
    };
  }

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'],
      name: json['name'],
      email: json['email']?.toString() ?? '',
      members: json['members'],
      login: json['login'],
      type: json['type'],
      unitsMigrationPerformed: json['unitsMigrationPerformed'] == true,
      units: (json['units'] as List<dynamic>)
          .map((e) => GroupUnit.fromJson(e))
          .toList(),
      tentStatuses: (json['tentStatuses'] as List<dynamic>? ?? const [])
          .map((e) => TentStatusRef.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
