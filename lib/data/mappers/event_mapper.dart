import 'package:logistiscout/data/models/event_dto.dart';
import 'package:logistiscout/domain/entities/event.dart';

class EventMapper {
  /// Convert DTO → Domain
  static Event toDomain(EventDto dto) {
    DateTime safeParse(String? value) {
      if (value == null || value.isEmpty) return DateTime.now();
      try {
        return DateTime.parse(value);
      } catch (_) {
        return DateTime.now();
      }
    }

    return Event(
      id: dto.id,
      nom: dto.nom,
      date: safeParse(dto.date),
      dateFin: safeParse(dto.dateFin),
      type: dto.type,
      tentesAssociees: dto.tentesAssociees,
      unites: dto.unites,
      groupeId: dto.groupeId,
    );
  }

  /// Convert Domain → DTO
  static EventDto toDto(Event entity) {
    return EventDto(
      id: entity.id,
      nom: entity.nom,
      date: entity.date.toIso8601String(),
      dateFin: entity.dateFin.toIso8601String(),
      type: entity.type,
      tentesAssociees: entity.tentesAssociees,
      unites: entity.unites,
      groupeId: entity.groupeId,
    );
  }

  static EventDto fromJson(Map<String, dynamic> json) {
    return EventDto.fromJson(json);
  }

  static Event fromJsonToDomain(Map<String, dynamic> json) {
    return toDomain(EventDto.fromJson(json));
  }

  static List<Event> toDomainList(List<EventDto> dtos) =>
      dtos.map(toDomain).toList();

  static List<EventDto> toDtoList(List<Event> entities) =>
      entities.map(toDto).toList();
}
