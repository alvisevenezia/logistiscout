// domain/entities/evenement.dart
class Event {
  final int id;
  final String nom;
  final DateTime date;
  final DateTime dateFin;
  final String type;
  final List<int> associatedTents;
  final List<int> unites;
  final String groupId;

  const Event({
    required this.id,
    required this.nom,
    required this.date,
    required this.dateFin,
    required this.type,
    required this.associatedTents,
    required this.unites,
    required this.groupId,
  });

  bool isUpcoming(DateTime now) => date.isAfter(now);

  List<DateTime> get dateRange {
    final List<DateTime> out = [];
    var d = DateTime(date.year, date.month, date.day);
    final end = DateTime(dateFin.year, dateFin.month, dateFin.day);
    while (!d.isAfter(end)) {
      out.add(d);
      d = d.add(const Duration(days: 1));
    }
    return out;
  }

  Event copyWith({
    int? id,
    String? nom,
    DateTime? date,
    DateTime? dateFin,
    String? type,
    List<int>? associatedTents,
    List<int>? unites,
    String? groupId,
  }) {
    return Event(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      date: date ?? this.date,
      dateFin: dateFin ?? this.dateFin,
      type: type ?? this.type,
      associatedTents: associatedTents ?? this.associatedTents,
      unites: unites ?? this.unites,
      groupId: groupId ?? this.groupId,
    );
  }
}
