import 'package:logistiscout/data/mappers/event_mapper.dart';
import 'package:logistiscout/services/api_service.dart';
import 'package:logistiscout/data/mappers/tente_mapper.dart';
import 'package:logistiscout/data/models/tente_dto.dart';
import 'package:logistiscout/domain/entities/tente.dart';
import 'package:logistiscout/domain/repositories/tente_repository.dart';
import 'package:logistiscout/services/local_storage_service.dart';
import 'dart:developer' as developer;

class TentRepositoryImpl implements TentRepository {
  final ApiService api;

  TentRepositoryImpl(this.api);

  @override
  Future<List<Tent>> getTentList() async {
    final groupId = await LocalStorageService.instance.getGroupId();
    if (groupId == null) throw Exception('GroupId is null');

    developer.log('[TenteRepository] getAllTentes(groupId=$groupId)');
    final jsonList = await api.getTentList(groupId);
    final dtos = jsonList.map((j) => TentDto.fromJson(j)).toList();
    return dtos.map(mapTentDtoToDomain).toList();
  }

  @override
  Future<void> createTent(String groupId, Tent tent) async {
    developer.log('[TenteRepository] createTente($groupId, ${tent.nom})');
    final dto = mapTentDomainToDto(tent);
    final json = dto.toJson()..['groupeId'] = groupId;
    await api.createTent(json);
  }

  @override
  Future<void> updateTent(String groupId, Tent tent) async {
    developer.log('[TenteRepository] updateTente($groupId, ${tent.id})');
    final dto = mapTentDomainToDto(tent);
    final json = dto.toJson()..['groupeId'] = groupId;
    await api.updateTent(tent.id, json);
  }

  @override
  Future<void> deleteTent(int id, String groupId) async {
    developer.log('[TenteRepository] deleteTente($id, groupId=$groupId)');
    await api.deleteTent(id, groupId: groupId);
  }

  @override
  Future<List<Tent>> getAvailableTent(DateTime debut, DateTime fin) async {
    final groupId = await LocalStorageService.instance.getGroupId();
    if (groupId == null) throw Exception('GroupId is null');

    developer.log('[TenteRepository] 🔍 getAvailableTentes(groupId=$groupId, '
        'debut=$debut, fin=$fin)');

    final allJson = await api.getTentList(groupId);
    final allTentes = allJson.map((j) => mapTentDtoToDomain(TentDto.fromJson(j))).toList();

    final eventsJson = await api.getEventList();

    final events = eventsJson
        .map((e) => EventMapper.fromJsonToDomain(e as Map<String, dynamic>))
        .toList();

    final takenTentIds = <int>{};
    for (final evt in events) {
      if (!fin.isBefore(evt.date) && !debut.isAfter(evt.dateFin)) {
        takenTentIds.addAll(evt.associatedTents);
      }
    }

    final available = allTentes
        .where((t) => !takenTentIds.contains(t.id))
        .toList()
      ..sort((a, b) => a.nom.toLowerCase().compareTo(b.nom.toLowerCase()));

    developer.log('[TenteRepository] ✅ ${available.length} tentes disponibles trouvées');
    return available;
  }


}
