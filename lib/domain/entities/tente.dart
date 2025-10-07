// domain/entities/tente.dart
import 'package:logistiscout/data/controle.dart';
import 'package:logistiscout/data/reservation.dart';

class Tente {
  final int id;
  final String nom;
  final int? uniteId;
  final EtatTente etat; // enum in domain if you want
  final String remarques;
  final bool tapisSolIntegre;
  final int nbPlaces;
  final String typeTente;
  final String unitePreferee;
  final List<Reservation> agenda;
  final List<Controle> historiqueControles;
  final List<String> couleurs;
  final String groupeId;

  const Tente({
    required this.id,
    required this.nom,
    required this.uniteId,
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

  Tente copyWith({
    int? id,
    String? nom,
    int? uniteId,
    EtatTente? etat,
    String? remarques,
    bool? tapisSolIntegre,
    int? nbPlaces,
    String? typeTente,
    String? unitePreferee,
    List<Reservation>? agenda,
    List<Controle>? historiqueControles,
    List<String>? couleurs,
    String? groupeId,
  }) {
    return Tente(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      uniteId: uniteId ?? this.uniteId,
      etat: etat ?? this.etat,
      remarques: remarques ?? this.remarques,
      tapisSolIntegre: tapisSolIntegre ?? this.tapisSolIntegre,
      nbPlaces: nbPlaces ?? this.nbPlaces,
      typeTente: typeTente ?? this.typeTente,
      unitePreferee: unitePreferee ?? this.unitePreferee,
      agenda: agenda ?? this.agenda,
      historiqueControles: historiqueControles ?? this.historiqueControles,
      couleurs: couleurs ?? this.couleurs,
      groupeId: groupeId ?? this.groupeId,
    );
  }
}

enum EtatTente { ok, maintenance, casse, inconnu }

/// Converts API string (or display label) to enum
EtatTente etatTenteFromString(String etat) {
  final normalized = etat.trim().toLowerCase();

  switch (normalized) {
    case 'ok':
    case 'bon':
      return EtatTente.ok;

    case 'maintenance':
    case 'a réparer':
    case 'à réparer':
      return EtatTente.maintenance;

    case 'hs':
    case 'cassé':
    case 'casse':
      return EtatTente.casse;

    case 'inconnu':
    case 'perdue':
      return EtatTente.inconnu;

    default:
      return EtatTente.casse; // valeur par défaut
  }
}

/// Converts enum to a readable French label
String etatTenteToString(EtatTente e) {
  switch (e) {
    case EtatTente.ok:
      return 'Bon';
    case EtatTente.maintenance:
      return 'À réparer';
    case EtatTente.casse:
      return 'HS';
    case EtatTente.inconnu:
      return 'Perdue';
  }
}
