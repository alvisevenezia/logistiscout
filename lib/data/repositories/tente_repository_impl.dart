import 'package:logistiscout/data/mappers/event_mapper.dart';
import 'package:logistiscout/services/api_service.dart';
import 'package:logistiscout/data/mappers/tente_mapper.dart';
import 'package:logistiscout/data/models/tente_dto.dart';
import 'package:logistiscout/domain/entities/tente.dart';
import 'package:logistiscout/domain/repositories/tente_repository.dart';
import 'package:logistiscout/services/local_storage_service.dart';
import 'dart:developer' as developer;

class TenteRepositoryImpl implements TenteRepository {
  final ApiService api;

  TenteRepositoryImpl(this.api);

  /// Récupère une tente spécifique
  @override
  Future<Tente> getTente(int id) async {
    developer.log('[TenteRepository] getTente($id)');
    final json = await api.getTente(id);
    final dto = TenteDto.fromJson(json);
    return mapTenteDtoToDomain(dto);
  }

  /// Récupère toutes les tentes du groupe courant
  @override
  Future<List<Tente>> getAllTentes() async {
    final groupId = await LocalStorageService.instance.getGroupId();
    if (groupId == null) throw Exception('GroupId is null');

    developer.log('[TenteRepository] getAllTentes(groupId=$groupId)');
    final jsonList = await api.getTentes(groupId);
    final dtos = jsonList.map((j) => TenteDto.fromJson(j)).toList();
    return dtos.map(mapTenteDtoToDomain).toList();
  }

  /// Crée une nouvelle tente
  @override
  Future<void> createTente(String groupId, Tente tente) async {
    developer.log('[TenteRepository] createTente($groupId, ${tente.nom})');
    final dto = mapTenteDomainToDto(tente);
    final json = dto.toJson()..['groupeId'] = groupId;
    await api.createTente(json);
  }

  /// Met à jour une tente existante
  @override
  Future<void> updateTente(String groupId, Tente tente) async {
    developer.log('[TenteRepository] updateTente($groupId, ${tente.id})');
    final dto = mapTenteDomainToDto(tente);
    final json = dto.toJson()..['groupeId'] = groupId;
    await api.updateTente(tente.id, json);
  }

  /// Supprime une tente
  @override
  Future<void> deleteTente(int id, String groupId) async {
    developer.log('[TenteRepository] deleteTente($id, groupId=$groupId)');
    await api.deleteTente(id, groupeId: groupId);
  }

  @override
  Future<List<Tente>> getAvailableTentes(DateTime debut, DateTime fin) async {
    final groupId = await LocalStorageService.instance.getGroupId();
    if (groupId == null) throw Exception('GroupId is null');

    developer.log('[TenteRepository] 🔍 getAvailableTentes(groupId=$groupId, '
        'debut=$debut, fin=$fin)');

    final allJson = await api.getTentes(groupId);
    final allTentes = allJson.map((j) => mapTenteDtoToDomain(TenteDto.fromJson(j))).toList();

    final eventsJson = await api.getEvenements(groupId);

    final events = eventsJson
        .map((e) => EventMapper.fromJsonToDomain(e as Map<String, dynamic>))
        .toList();

    final takenTentIds = <int>{};
    for (final evt in events) {
      if (!fin.isBefore(evt.date) && !debut.isAfter(evt.dateFin)) {
        takenTentIds.addAll(evt.tentesAssociees);
      }
    }

    // 4️⃣ Filtre les tentes disponibles
    final available = allTentes
        .where((t) => !takenTentIds.contains(t.id))
        .toList()
      ..sort((a, b) => a.nom.toLowerCase().compareTo(b.nom.toLowerCase()));

    developer.log('[TenteRepository] ✅ ${available.length} tentes disponibles trouvées');
    return available;
  }


}
