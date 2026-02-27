import 'package:logistiscout/domain/entities/unit.dart';

import 'dart:developer' as developer;

class GroupDto {
  final String id;
  final String name;
  final String members;
  final String email;


  GroupDto({
    required this.id,
    required this.name,
    required this.members,
    required this.email,
  });

  factory GroupDto.fromJson(Map<String, dynamic> json) {
    return GroupDto(
      id: json['id'].toString(),
      name: json['nom'],
      members: json['membres'].toString(),
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nom': name,
    'membres': members,
    'email': email,
  };
}
