// data/modals/tente_dto.dart
class TentDto {
  final int id;
  final String nom;
  final int? uniteId;
  final String state;
  final String comments;
  final bool isFloorEmbedded;
  final int nbPlaces;
  final String tentType;
  final String assignedUnit;
  final List<Map<String, dynamic>> agenda; // raw reservations JSON
  final List<Map<String, dynamic>> controlHistory; // raw controles JSON
  final List<String> colors;
  final String groupId;
  final String team;
  final String location;

  TentDto({
    required this.id,
    required this.nom,
    required this.uniteId,
    required this.state,
    required this.comments,
    required this.isFloorEmbedded,
    required this.nbPlaces,
    required this.tentType,
    required this.assignedUnit,
    required this.agenda,
    required this.controlHistory,
    required this.colors,
    required this.groupId,
    required this.team,
    required this.location,
  });

  factory TentDto.fromJson(Map<String, dynamic> json) => TentDto(
    id: json['id'] as int,
    nom: json['nom'] ?? '',
    uniteId: json['uniteId'] == null ? null : int.tryParse(json['uniteId'].toString()),
    state: json['etat'] ?? '',
    comments: json['remarques'] ?? '',
    isFloorEmbedded: json['estIntegree'] == true,
    nbPlaces: json['nbPlaces'] is int ? json['nbPlaces'] : int.tryParse('${json['nbPlaces']}') ?? 0,
    tentType: json['typeTente'] ?? '',
    assignedUnit: json['unitePreferee'] ?? '',
    agenda: List<Map<String, dynamic>>.from(json['agenda'] ?? const []),
    controlHistory: List<Map<String, dynamic>>.from(json['controlHistory'] ?? const []),
    colors: (json['couleurs'] as List<dynamic>? ?? []).map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList(),
    groupId: json['groupeId']?.toString() ?? '',
    team: json['equipe']?.toString() ?? '',
    location: json['localisation']?.toString() ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'nom': nom,
    'uniteId': uniteId,
    'etat': state,
    'remarques': comments,
    'estIntegree': isFloorEmbedded,
    'nbPlaces': nbPlaces,
    'typeTente': tentType,
    'unitePreferee': assignedUnit,
    'agenda': agenda,
    'couleurs': colors,
    'groupeId': groupId,
    'equipe' : team,
    'localisation': location,
  };
}
