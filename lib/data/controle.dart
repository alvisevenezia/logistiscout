class Controle {
  final int? id;
  final int tenteId;
  final int userId;
  final DateTime date; // ISO 8601, ex : "2025-06-06T12:00:00"
  final Map<String, dynamic> checklist; // peut être un Map ou List selon usage
  final String remarques;

  Controle({
    this.id,
    required this.tenteId,
    required this.userId,
    required this.date,
    required this.checklist,
    required this.remarques,
  });

  Map<String, dynamic> toJson() {
    return {
      'tenteId': tenteId,
      'userId': userId,
      'date': date.toString(),
      'checklist': checklist,
      'remarques': remarques,
    };
  }

  factory Controle.fromJson(Map<String, dynamic> json) {
    return Controle(
      id: json['id'],
      tenteId: json['tenteId'],
      userId: json['userId'],
      date: DateTime.parse(json['date']),
      checklist: json['checklist'],
      remarques: json['remarques'] ?? '',
    );
  }
}
