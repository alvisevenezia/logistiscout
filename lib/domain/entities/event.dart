// domain/entities/evenement.dart
class Event {
  final int id;
  final String nom;
  final DateTime date;
  final DateTime dateFin;
  final String type;
  final List<int> tentesAssociees;
  final List<int> unites;

  const Event({
    required this.id,
    required this.nom,
    required this.date,
    required this.dateFin,
    required this.type,
    required this.tentesAssociees,
    required this.unites,
    required String? groupeId,
  });

  bool isUpcoming(DateTime now) => date.isAfter(now);

  Event copyWith({
    int? id,
    String? nom,
    DateTime? date,
    DateTime? dateFin,
    String? type,
    List<int>? tentesAssociees,
    List<int>? unites,
    String? groupeId,
  }) {
    return Event(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      date: date ?? this.date,
      dateFin: dateFin ?? this.dateFin,
      type: type ?? this.type,
      tentesAssociees: tentesAssociees ?? this.tentesAssociees,
      unites: unites ?? this.unites,
      groupeId: groupeId,
    );
  }
}
