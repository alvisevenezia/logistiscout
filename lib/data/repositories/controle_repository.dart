// lib/data/repositories/controle_repository.dart
import 'package:logistiscout/domain/entities/controle.dart';
import 'package:logistiscout/data/models/controle_dto.dart';
import 'package:logistiscout/data/mappers/controle_mapper.dart';
import 'package:logistiscout/services/api_service.dart';

class ControleRepository {
  final ApiService api;

  ControleRepository({ApiService? api}) : api = api ?? ApiService();

  Future<List<Controle>> getControles(int tenteId) async {
    final data = await api.getControles(tenteId);
    final dtos = data.map((e) => ControleDto.fromJson(e)).toList();
    return dtos.map(mapControleDtoToDomain).toList();
  }

  Future<void> addControle(Controle controle) async {
    final dto = mapControleDomainToDto(controle);
    await api.addControle(dto.toJson());
  }

  Future<void> updateControle(Controle controle) async {
    if (controle.id == null) {
      throw Exception('Cannot update a controle without an ID');
    }
    final dto = mapControleDomainToDto(controle);
    await api.updateControle(controle.id!, dto.toJson());
  }

  Future<void> deleteControle(int id) async {
    await api.deleteControle(id);
  }
}
