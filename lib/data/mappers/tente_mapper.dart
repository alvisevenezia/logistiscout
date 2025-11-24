import 'package:logistiscout/data/models/tente_dto.dart';
import 'package:logistiscout/domain/entities/reservation.dart';
import 'package:logistiscout/domain/entities/controle.dart';
import 'package:logistiscout/domain/entities/tente.dart';

Tent mapTentDtoToDomain(TentDto dto) {
  return Tent(
    id: dto.id,
    nom: dto.nom,
    uniteId: dto.uniteId,
    state: tentStateFromString(dto.state), // could map to enum
    comments: dto.comments,
    isFloorEmbedded: dto.isFloorEmbedded,
    nbPlaces: dto.nbPlaces,
    tentType: dto.tentType,
    assignedUnit: dto.assignedUnit,
    agenda: dto.agenda.map((r) => Reservation.fromJson(r)).toList(),
    controlHistory:
    dto.controlHistory.map((c) => Control.fromJson(c)).toList(),
    colors: dto.colors,
    groupId: dto.groupId,
  );
}

TentDto mapTentDomainToDto(Tent entity) {
  return TentDto(
    id: entity.id,
    nom: entity.nom,
    uniteId: entity.uniteId,
    state: tentStateToString(entity.state),
    comments: entity.comments,
    isFloorEmbedded: entity.isFloorEmbedded,
    nbPlaces: entity.nbPlaces,
    tentType: entity.tentType,
    assignedUnit: entity.assignedUnit,
    agenda: entity.agenda.map((r) => r.toJson()).toList(),
    controlHistory:
    entity.controlHistory.map((c) => c.toJson()).toList(),
    colors: entity.colors,
    groupId: entity.groupId,
  );
}