import 'package:logistiscout/data/models/controle_dto.dart';
import 'package:logistiscout/domain/entities/controle.dart';

Control mapControlDtoToDomain(ControlDto dto) {
  return Control(
    id: dto.id,
    tentId: dto.tentId,
    userId: dto.userId,
    date: DateTime.parse(dto.date),
    checklist: dto.checklist,
    comment: dto.comments,
  );
}

ControlDto mapControlDomainToDto(Control controle) {
  return ControlDto(
    id: controle.id,
    tentId: controle.tentId,
    userId: controle.userId,
    date: controle.date.toIso8601String(),
    checklist: controle.checklist,
    comments: controle.comment,
  );
}
