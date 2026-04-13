class EventDto {
  final int id;
  final String nom;
  final String date; // keep as String because API sends ISO string
  final String dateFin; // same
  final String type;
  final List<int> associatedTents;
  final List<int> unites;
  final String groupId;

  EventDto({
    required this.id,
    required this.nom,
    required this.date,
    required this.dateFin,
    required this.type,
    required this.associatedTents,
    required this.unites,
    required this.groupId,
  });

  factory EventDto.fromJson(Map<String, dynamic> json) {
    final rawGroupId = json['groupId'] ?? json['groupeId'];
    return EventDto(
      id: json['id'] as int,
      nom: json['nom'] as String,
      date: json['date'] as String,
      dateFin: json['dateFin'] as String,
      type: json['type'] as String,
      associatedTents: List<int>.from(json['tentesAssociees'] ?? []),
      unites: List<int>.from(json['unites'] ?? []),
      groupId: rawGroupId?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nom': nom,
    'date': date,
    'dateFin': dateFin,
    'type': type,
    'tentesAssociees': associatedTents,
    'unites': unites,
    'groupeId': groupId,
  };
}
