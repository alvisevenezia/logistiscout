import 'package:logistiscout/data/mappers/group_mapper.dart';
import 'package:logistiscout/data/models/group_dto.dart';
import 'package:logistiscout/domain/entities/group.dart';
import 'package:logistiscout/services/api_service.dart';

class GroupRepository {
  final ApiService api;

  GroupRepository({ApiService? api}) : api = api ?? ApiService();

  Future<Group> getGroupInfo() async {
    final data = await api.getGroupInfo();
    return mapGroupDtoToDomain(GroupDto.fromJson(data));
  }
}
