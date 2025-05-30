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
  });
}

class Unite {
  final int id;
  final String nom;
  final List<int> tentesIds;

  Unite({required this.id, required this.nom, required this.tentesIds});
}

class Evenement {
  final int id;
  final String nom;
  final DateTime date;
  final DateTime dateFin;
  final String type;
  final List<int> tentesAssociees;

  Evenement({
    required this.id,
    required this.nom,
    required this.date,
    required this.dateFin,
    required this.type,
    required this.tentesAssociees,
  });
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
}

class Controle {
  final int id;
  final int tenteId;
  final int userId;
  final DateTime date;
  final Map<String, dynamic> checklist;
  final String remarques;

  Controle({
    required this.id,
    required this.tenteId,
    required this.userId,
    required this.date,
    required this.checklist,
    required this.remarques,
  });
}
