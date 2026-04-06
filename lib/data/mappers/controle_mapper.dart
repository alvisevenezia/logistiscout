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
    imageUrl: dto.imageUrl,
    imageUrls: dto.imageUrls,
  );
}

ControlDto mapControlDomainToDto(Control control) {
  return ControlDto(
    id: control.id,
    tentId: control.tentId,
    userId: control.userId,
    date: control.date.toIso8601String(),
    checklist: control.checklist,
    comments: control.comment,
    imageUrl: control.imageUrl,
    imageUrls: control.imageUrls,
  );
}
