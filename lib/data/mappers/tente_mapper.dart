import 'package:logistiscout/data/controle.dart';
import 'package:logistiscout/data/models/tente_dto.dart';
import 'package:logistiscout/data/reservation.dart';
import 'package:logistiscout/domain/entities/tente.dart';

Tente mapTenteDtoToDomain(TenteDto dto) {
  return Tente(
    id: dto.id,
    nom: dto.nom,
    uniteId: dto.uniteId,
    etat: etatTenteFromString(dto.etat), // could map to enum
    remarques: dto.remarques,
    tapisSolIntegre: dto.estIntegree,
    nbPlaces: dto.nbPlaces,
    typeTente: dto.typeTente,
    unitePreferee: dto.unitePreferee,
    agenda: dto.agenda.map((r) => Reservation.fromJson(r)).toList(),
    historiqueControles:
    dto.historiqueControles.map((c) => Controle.fromJson(c)).toList(),
    couleurs: dto.couleurs,
    groupeId: dto.groupeId,
  );
}

TenteDto mapTenteDomainToDto(Tente entity) {
  return TenteDto(
    id: entity.id,
    nom: entity.nom,
    uniteId: entity.uniteId,
    etat: etatTenteToString(entity.etat), // ✅ converts enum → String
    remarques: entity.remarques,
    estIntegree: entity.tapisSolIntegre,
    nbPlaces: entity.nbPlaces,
    typeTente: entity.typeTente,
    unitePreferee: entity.unitePreferee,
    agenda: entity.agenda.map((r) => r.toJson()).toList(),
    historiqueControles:
    entity.historiqueControles.map((c) => c.toJson()).toList(),
    couleurs: entity.couleurs,
    groupeId: entity.groupeId,
  );
}