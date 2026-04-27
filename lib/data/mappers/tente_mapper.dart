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
    tentStatusId: dto.tentStatusId,
    tentStatusLabel: dto.tentStatusLabel,
    tentStatusColor: dto.tentStatusColor,
    comment: dto.comments,
    isFloorEmbedded: dto.isFloorEmbedded,
    nbPlaces: dto.nbPlaces,
    tentType: dto.tentType,
    assignedUnit: dto.assignedUnit,
    agenda: dto.agenda.map((r) => Reservation.fromJson(r)).toList(),
    controlHistory:
    dto.controlHistory.map((c) => Control.fromJson(c)).toList(),
    colors: dto.colors,
    groupId: dto.groupId,
    team: dto.team,
    location: dto.location, // Not present in domain entity
  );
}

TentDto mapTentDomainToDto(Tent entity) {
  final effectiveStatusLabel =
      (entity.tentStatusLabel != null && entity.tentStatusLabel!.trim().isNotEmpty)
      ? entity.tentStatusLabel!.trim()
      : tentStateToString(entity.state);

  return TentDto(
    id: entity.id,
    nom: entity.nom,
    uniteId: entity.uniteId,
    state: effectiveStatusLabel,
    tentStatusId: entity.tentStatusId,
    tentStatusLabel: effectiveStatusLabel,
    tentStatusColor: entity.tentStatusColor ?? entity.state.chipColor,
    comments: entity.comment,
    isFloorEmbedded: entity.isFloorEmbedded,
    nbPlaces: entity.nbPlaces,
    tentType: entity.tentType,
    assignedUnit: entity.assignedUnit,
    agenda: entity.agenda.map((r) => r.toJson()).toList(),
    controlHistory:
    entity.controlHistory.map((c) => c.toJson()).toList(),
    colors: entity.colors,
    groupId: entity.groupId,
    team: entity.team,
    location: entity.location,
  );
}