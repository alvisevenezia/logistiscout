import 'package:logistiscout/services/api_service.dart';
import 'package:logistiscout/data/mappers/tente_mapper.dart';
import 'package:logistiscout/data/models/tente_dto.dart';
import 'package:logistiscout/domain/entities/tente.dart';
import 'package:logistiscout/domain/repositories/tente_repository.dart';
import 'package:logistiscout/services/local_storage_service.dart';

class TenteRepositoryImpl implements TenteRepository {
  final ApiService api;

  TenteRepositoryImpl(this.api);

  @override
  Future<Tente> getTente(int id) async {
    final json = await api.getTente(id); // <- implement this in ApiService
    final dto = TenteDto.fromJson(json);
    return mapTenteDtoToDomain(dto);
  }

  @override
  Future<List<Tente>> getAllTentes() async {
    final groupId = await LocalStorageService.instance.getGroupId();
    if (groupId == null) {
      throw Exception('GroupId is null');
    }
    final jsonList = await api.getTentes(groupId); // returns List<Map<String, dynamic>>
    final dtos = jsonList.map((j) => TenteDto.fromJson(j)).toList();
    return dtos.map(mapTenteDtoToDomain).toList();
  }

  @override
  Future<Tente> createTente(Map<String, dynamic> json) async {
    final dto = TenteDto.fromJson(json);
    return mapTenteDtoToDomain(dto);
  }

  @override
  Future<void> deleteTente(int id) async {
    final groupId = await LocalStorageService.instance.getGroupId();
    if (groupId == null) {
      throw Exception('GroupId is null');
    }
    await api.deleteTente(id,groupeId: groupId);
  }
}