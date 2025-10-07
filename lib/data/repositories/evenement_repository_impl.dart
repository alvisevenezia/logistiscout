// lib/data/repositories/evenement_repository.dart
import 'package:logistiscout/data/models/event_dto.dart';
import 'package:logistiscout/data/mappers/event_mapper.dart';
import 'package:logistiscout/domain/entities/event.dart';
import 'package:logistiscout/services/api_service.dart';

class EvenementRepository {
  final ApiService api;
  EvenementRepository({ApiService? api}) : api = api ?? ApiService();

  Future<List<Event>> getEvenements(String groupeId) async {
    final jsonList = await api.getEvenements(groupeId);

    // Convert JSON → DTO → Domain
    final dtos = jsonList.map((e) => EventDto.fromJson(e)).toList();
    final events = EventMapper.toDomainList(dtos);

    return events;
  }

  Future<void> addEvenement(Event event) async {
    final dto = EventMapper.toDto(event);
    await api.addEvenement(dto.toJson());
  }

  Future<void> updateEvenement(Event event) async {
    final dto = EventMapper.toDto(event);
    await api.updateEvenement(dto.id, dto.toJson());
  }

  Future<void> deleteEvenement(int id, String groupeId) async {
    await api.deleteEvenement(id, groupeId: groupeId);
  }
}
