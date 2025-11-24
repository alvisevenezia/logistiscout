// lib/data/modals/controle_dto.dart
class ControlDto {
  final int? id;
  final int tentId;
  final int userId;
  final String date; // stored as ISO 8601 string
  final Map<String, dynamic> checklist;
  final String comments;

  ControlDto({
    this.id,
    required this.tentId,
    required this.userId,
    required this.date,
    required this.checklist,
    required this.comments,
  });

  factory ControlDto.fromJson(Map<String, dynamic> json) => ControlDto(
    id: json['id'],
    tentId: json['tenteId'],
    userId: json['userId'],
    date: json['date'],
    checklist: Map<String, dynamic>.from(json['checklist'] ?? {}),
    comments: json['remarques'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'tenteId': tentId,
    'userId': userId,
    'date': date,
    'checklist': checklist,
    'remarques': comments,
  };
}
