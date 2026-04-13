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
    login: dto.login,
    type: dto.type,
    units: dto.units,
    tentStatuses: dto.tentStatuses,
    unitsMigrationPerformed: dto.unitsMigrationPerformed,
  );
}

GroupDto mapGroupDomainToDto(Group group) {
  return GroupDto(
    id: group.id,
    name: group.name,
    members: group.members,
    email: group.email,
    login: group.login,
    type: group.type,
    units: group.units,
    tentStatuses: group.tentStatuses,
    unitsMigrationPerformed: group.unitsMigrationPerformed,
  );
}
