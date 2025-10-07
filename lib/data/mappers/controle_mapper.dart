// lib/data/mappers/controle_mapper.dart
import 'package:logistiscout/data/models/controle_dto.dart';
import 'package:logistiscout/domain/entities/controle.dart';

Controle mapControleDtoToDomain(ControleDto dto) {
  return Controle(
    id: dto.id,
    tenteId: dto.tenteId,
    userId: dto.userId,
    date: DateTime.parse(dto.date),
    checklist: dto.checklist,
    remarques: dto.remarques,
  );
}

ControleDto mapControleDomainToDto(Controle controle) {
  return ControleDto(
    id: controle.id,
    tenteId: controle.tenteId,
    userId: controle.userId,
    date: controle.date.toIso8601String(),
    checklist: controle.checklist,
    remarques: controle.remarques,
  );
}
