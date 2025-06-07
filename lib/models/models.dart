import 'package:logistiscout/models/api_service.dart';

class Tente {
  final int id;
  final String nom;
  final int? uniteId;
  final String etat;
  final String remarques;
  final bool tapisSolIntegre;
  final int nbPlaces;
  final String typeTente;
  final String unitePreferee;
  final List<Reservation> agenda;
  final List<Controle> historiqueControles;
  final List<String> couleurs;
  final String groupeId;

  Tente({
    required this.id,
    required this.nom,
    this.uniteId,
    required this.etat,
    required this.remarques,
    required this.tapisSolIntegre,
    required this.nbPlaces,
    required this.typeTente,
    required this.unitePreferee,
    required this.agenda,
    required this.historiqueControles,
    required this.couleurs,
    required this.groupeId,
  });

  factory Tente.fromJson(Map<String, dynamic> json) {
    return Tente(
      id: json['id'],
      nom: json['nom'],
      uniteId: json['uniteId'],
      etat: json['etat'],
      remarques: json['remarques'] ?? '',
      tapisSolIntegre: json['estIntegree'] ?? false,
      nbPlaces: json['nbPlaces'] ?? 0,
      typeTente: json['typeTente'] ?? '',
      unitePreferee: json['unitePreferee'] ?? '',
      agenda: (json['agenda'] ?? []).map<Reservation>((r) => Reservation.fromJson(r)).toList(),
      historiqueControles: [], // sera rempli dynamiquement après récupération
      couleurs: (json['couleurs'] as List<dynamic>? ?? []).map((c) => c.toString()).toList(),
      groupeId: json['groupeId']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'uniteId': uniteId,
      'etat': etat,
      'remarques': remarques,
      'estIntegree': tapisSolIntegre,
      'nbPlaces': nbPlaces,
      'typeTente': typeTente,
      'unitePreferee': unitePreferee,
      'agenda': agenda.map((r) => r.toJson()).toList(),
      'historiqueControles': historiqueControles.map((c) => c.toJson()).toList(),
      'couleurs': couleurs,
      'groupeId': groupeId,
    };
  }

  // Charge automatiquement l'historique des contrôles lors de la création d'une Tente
  static Future<Tente> fromApiJson(Map<String, dynamic> json) async {
    final tente = Tente.fromJson(json);
    await tente.fetchAndSetControles();
    return tente;
  }

  // Méthode utilitaire pour remplir l'historique des contrôles depuis une liste json
  Future<void> fetchAndSetControles() async {
    final controlesJson = await ApiService.getControles(this.id);
    historiqueControles.clear();
    historiqueControles.addAll(controlesJson.map<Controle>((c) => Controle.fromJson(c)));
  }
}

class Evenement {
  final int id;
  final String nom;
  final DateTime date;
  final DateTime dateFin;
  final String type;
  final List<int> tentesAssociees;
  final List<int> unites;

  Evenement({
    required this.id,
    required this.nom,
    required this.date,
    required this.dateFin,
    required this.type,
    required this.tentesAssociees,
    required this.unites,
  });

  factory Evenement.fromJson(Map<String, dynamic> json) {
    return Evenement(
      id: json['id'],
      nom: json['nom'],
      date: DateTime.parse(json['date']),
      dateFin: DateTime.parse(json['dateFin']),
      type: json['type'],
      tentesAssociees: List<int>.from(json['tentesAssociees'] ?? []),
      unites: List<int>.from(json['unites'] ?? []),
    );
  }
}

class Reservation {
  final DateTime debut;
  final DateTime fin;
  final int evenementId;

  Reservation({
    required this.debut,
    required this.fin,
    required this.evenementId,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      debut: DateTime.parse(json['debut']),
      fin: DateTime.parse(json['fin']),
      evenementId: json['evenementId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'debut': debut.toIso8601String(),
      'fin': fin.toIso8601String(),
      'evenementId': evenementId,
    };
  }
}

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


