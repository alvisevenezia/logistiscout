// data/modals/tente_dto.dart
class TenteDto {
  final int id;
  final String nom;
  final int? uniteId;
  final String etat;
  final String remarques;
  final bool estIntegree;
  final int nbPlaces;
  final String typeTente;
  final String unitePreferee;
  final List<Map<String, dynamic>> agenda; // raw reservations JSON
  final List<Map<String, dynamic>> historiqueControles; // raw controles JSON
  final List<String> couleurs;
  final String groupeId;

  TenteDto({
    required this.id,
    required this.nom,
    required this.uniteId,
    required this.etat,
    required this.remarques,
    required this.estIntegree,
    required this.nbPlaces,
    required this.typeTente,
    required this.unitePreferee,
    required this.agenda,
    required this.historiqueControles,
    required this.couleurs,
    required this.groupeId,
  });

  factory TenteDto.fromJson(Map<String, dynamic> json) => TenteDto(
    id: json['id'] as int,
    nom: json['nom'] ?? '',
    uniteId: json['uniteId'] == null ? null : int.tryParse(json['uniteId'].toString()),
    etat: json['etat'] ?? '',
    remarques: json['remarques'] ?? '',
    estIntegree: (json['estIntegree'] ?? json['tapisSolIntegre']) == true,
    nbPlaces: json['nbPlaces'] is int ? json['nbPlaces'] : int.tryParse('${json['nbPlaces']}') ?? 0,
    typeTente: json['typeTente'] ?? '',
    unitePreferee: json['unitePreferee'] ?? '',
    agenda: List<Map<String, dynamic>>.from(json['agenda'] ?? const []),
    historiqueControles: List<Map<String, dynamic>>.from(json['historiqueControles'] ?? const []),
    couleurs: (json['couleurs'] as List<dynamic>? ?? []).map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList(),
    groupeId: json['groupeId']?.toString() ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'nom': nom,
    'uniteId': uniteId,
      'etat': etat,
    'remarques': remarques,
    'estIntegree': estIntegree,
    'nbPlaces': nbPlaces,
    'typeTente': typeTente,
    'unitePreferee': unitePreferee,
    'agenda': agenda,
    'historiqueControles': historiqueControles,
    'couleurs': couleurs,
    'groupeId': groupeId,
  };
}
