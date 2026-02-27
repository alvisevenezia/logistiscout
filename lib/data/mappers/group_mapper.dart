import 'package:logistiscout/data/models/controle_dto.dart';
import 'package:logistiscout/data/models/group_dto.dart';
import 'package:logistiscout/domain/entities/controle.dart';
import 'package:logistiscout/domain/entities/group.dart';

Group mapGroupDtoToDomain(GroupDto dto) {
  return Group(
    id: dto.id,
    name: dto.name,
    members: dto.members,
    email: dto.email,
  );
}

GroupDto mapGroupDomainToDto(Group control) {
  return GroupDto(
    id: control.id,
    name: control.name,
    members: control.members,
    email: control.email,
  );
}
