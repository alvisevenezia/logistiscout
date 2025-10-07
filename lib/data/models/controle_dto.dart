// lib/data/models/controle_dto.dart
class ControleDto {
  final int? id;
  final int tenteId;
  final int userId;
  final String date; // stored as ISO 8601 string
  final Map<String, dynamic> checklist;
  final String remarques;

  ControleDto({
    this.id,
    required this.tenteId,
    required this.userId,
    required this.date,
    required this.checklist,
    required this.remarques,
  });

  factory ControleDto.fromJson(Map<String, dynamic> json) => ControleDto(
    id: json['id'],
    tenteId: json['tenteId'],
    userId: json['userId'],
    date: json['date'],
    checklist: Map<String, dynamic>.from(json['checklist'] ?? {}),
    remarques: json['remarques'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'tenteId': tenteId,
    'userId': userId,
    'date': date,
    'checklist': checklist,
    'remarques': remarques,
  };
}
