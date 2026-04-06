import 'package:logistiscout/data/mappers/group_mapper.dart';
import 'package:logistiscout/data/models/group_dto.dart';
import 'package:logistiscout/domain/entities/group.dart';
import 'package:logistiscout/domain/entities/group_unit.dart';
import 'package:logistiscout/services/api_service.dart';

class GroupRepository {
  final ApiService api;

  GroupRepository({ApiService? api}) : api = api ?? ApiService();

  Future<Group> getGroupInfo() async {
    final data = await api.getGroupInfo();
    return mapGroupDtoToDomain(GroupDto.fromJson(data));
  }

  Future<void> changePassword(String password) async {}

  Future<void> updateGroup(Group newGroup) async {
    return updateGroupProfileFields(
      name: newGroup.name,
      email: newGroup.email,
      login: newGroup.login,
      members: newGroup.members,
      type: newGroup.type,
    );
  }

  Future<void> updateGroupProfileFields({
    String? name,
    String? email,
    String? login,
    String? members,
    String? type,
  }) async {
    final payload = <String, dynamic>{};
    if (name != null) payload['name'] = name;
    if (email != null) payload['email'] = email;
    if (login != null) payload['login'] = login;
    if (members != null) payload['members'] = members;
    if (type != null) payload['type'] = type;

    await api.updateGroupProfileFields(payload);
  }

  Future<GroupUnit> createUnit({
    required String name,
    required int color,
    String type = 'custom',
  }) async {
    final json = await api.createGroupUnit({
      'name': name,
      'color': color,
      'type': type,
    });
    return GroupUnit.fromJson(json);
  }

  Future<GroupUnit> updateUnit({
    required int unitId,
    String? name,
    int? color,
  }) async {
    final payload = <String, dynamic>{};
    if (name != null) payload['name'] = name;
    if (color != null) payload['color'] = color;

    final json = await api.updateGroupUnit(unitId, payload);
    return GroupUnit.fromJson(json);
  }

  Future<void> deleteUnit(int unitId, {bool forceReplace = false}) async {
    await api.deleteGroupUnit(unitId, forceReplace: forceReplace);
  }
}
