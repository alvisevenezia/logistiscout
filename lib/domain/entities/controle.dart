// lib/domain/entities/controle.dart

class Controle {
  final int? id;
  final int tenteId;
  final int userId;
  final DateTime date;
  final Map<String, dynamic> checklist;
  final String remarques;

  const Controle({
    this.id,
    required this.tenteId,
    required this.userId,
    required this.date,
    required this.checklist,
    required this.remarques,
  });

  Controle copyWith({
    int? id,
    int? tenteId,
    int? userId,
    DateTime? date,
    Map<String, dynamic>? checklist,
    String? remarques,
  }) {
    return Controle(
      id: id ?? this.id,
      tenteId: tenteId ?? this.tenteId,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      checklist: checklist ?? this.checklist,
      remarques: remarques ?? this.remarques,
    );
  }

  @override
  String toString() {
    return 'Controle(id: $id, tenteId: $tenteId, userId: $userId, date: $date, remarques: $remarques)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Controle &&
        other.id == id &&
        other.tenteId == tenteId &&
        other.userId == userId &&
        other.date == date &&
        other.remarques == remarques;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      tenteId.hashCode ^
      userId.hashCode ^
      date.hashCode ^
      remarques.hashCode;
}
