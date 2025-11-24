class Control {
  final int? id;
  final int tentId;
  final int userId;
  final DateTime date;
  final Map<String, dynamic> checklist;
  final String comment;

  const Control({
    this.id,
    required this.tentId,
    required this.userId,
    required this.date,
    required this.checklist,
    required this.comment,
  });

  Control copyWith({
    int? id,
    int? tentId,
    int? userId,
    DateTime? date,
    Map<String, dynamic>? checklist,
    String? comment,
  }) {
    return Control(
      id: id ?? this.id,
      tentId: tentId ?? this.tentId,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      checklist: checklist ?? this.checklist,
      comment: comment ?? this.comment,
    );
  }

  @override
  String toString() {
    return 'Controle(id: $id, tenteId: $tentId, userId: $userId, date: $date, remarques: $comment)';
  }

  Map<String, dynamic> toJson() {
    return {
      'tentId': tentId,
      'userId': userId,
      'date': date.toString(),
      'checklist': checklist,
      'comment': comment,
    };
  }

  factory Control.fromJson(Map<String, dynamic> json) {
    return Control(
      id: json['id'],
      tentId: json['tentId'],
      userId: json['userId'],
      date: DateTime.parse(json['date']),
      checklist: json['checklist'],
      comment: json['comment'] ?? '',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Control &&
        other.id == id &&
        other.tentId == tentId &&
        other.userId == userId &&
        other.date == date &&
        other.comment == comment;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      tentId.hashCode ^
      userId.hashCode ^
      date.hashCode ^
      comment.hashCode;
}
