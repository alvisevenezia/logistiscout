import 'package:logistiscout/domain/entities/controle.dart';
import 'package:logistiscout/data/models/controle_dto.dart';
import 'package:logistiscout/data/mappers/controle_mapper.dart';
import 'package:logistiscout/services/api_service.dart';

class ControlRepository {
  final ApiService api;

  ControlRepository({ApiService? api}) : api = api ?? ApiService();

  Future<List<Control>> getControlList(int tentId) async {
    final data = await api.getControlList(tentId);
    final dtos = data.map((e) => ControlDto.fromJson(e)).toList();
    return dtos.map(mapControlDtoToDomain).toList();
  }

  Future<void> addControl(Control control) async {
    final dto = mapControlDomainToDto(control);
    await api.addControl(dto.toJson());
  }

  Future<void> updateControl(Control control) async {
    if (control.id == null) {
      throw Exception('Cannot update a controle without an ID');
    }
    final dto = mapControlDomainToDto(control);
    await api.updateControl(control.id!, dto.toJson());
  }

  Future<void> deleteControl(int id) async {
    await api.deleteControl(id);
  }
}
