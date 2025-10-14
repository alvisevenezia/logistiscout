class EventDto {
  final int id;
  final String nom;
  final String date;    // keep as String because API sends ISO string
  final String dateFin; // same
  final String type;
  final List<int> tentesAssociees;
  final List<int> unites;
  final String groupeId;

  EventDto({
    required this.id,
    required this.nom,
    required this.date,
    required this.dateFin,
    required this.type,
    required this.tentesAssociees,
    required this.unites,
    required this.groupeId,
  });

  factory EventDto.fromJson(Map<String, dynamic> json) {
    return EventDto(
      id: json['id'] as int,
      nom: json['nom'] as String,
      date: json['date'] as String,
      dateFin: json['dateFin'] as String,
      type: json['type'] as String,
      tentesAssociees: List<int>.from(json['tentesAssociees'] ?? []),
      unites: List<int>.from(json['unites'] ?? []),
      groupeId: json['groupeId'].toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nom': nom,
    'date': date,
    'dateFin': dateFin,
    'type': type,
    'tentesAssociees': tentesAssociees,
    'unites': unites,
    'groupeId': groupeId,
  };
}
