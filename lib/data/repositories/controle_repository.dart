import 'package:logistiscout/domain/entities/controle.dart';
import 'package:logistiscout/data/models/controle_dto.dart';
import 'package:logistiscout/data/mappers/controle_mapper.dart';
import 'package:logistiscout/services/api_service.dart';
import 'dart:typed_data';

class ControlRepository {
  final ApiService api;

  ControlRepository({ApiService? api}) : api = api ?? ApiService();

  Future<List<Control>> getControlList(int tentId) async {
    final data = await api.getControlList(tentId);
    final dtos = data.map((e) => ControlDto.fromJson(e)).toList();
    return dtos.map(mapControlDtoToDomain).toList();
  }

  Future<Control> addControl(Control control) async {
    final dto = mapControlDomainToDto(control);
    final response = await api.addControl(dto.toJson());
    return mapControlDtoToDomain(ControlDto.fromJson(response));
  }

  Future<Control> updateControl(Control control) async {
    if (control.id == null) {
      throw Exception('Cannot update a controle without an ID');
    }
    final dto = mapControlDomainToDto(control);
    await api.updateControl(control.id!, dto.toJson());
    return control;
  }

  Future<Control> uploadControlPicture({
    required int controlId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final response = await api.uploadControlPicture(
      controlId: controlId,
      bytes: bytes,
      fileName: fileName,
    );
    return mapControlDtoToDomain(ControlDto.fromJson(response));
  }

  Future<void> deleteControl(int id) async {
    await api.deleteControl(id);
  }
}
