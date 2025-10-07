import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logistiscout/data/models/tente_dto.dart';
import 'package:logistiscout/domain/entities/tente.dart';
import 'package:logistiscout/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/mappers/tente_mapper.dart';

class TentesController extends AsyncNotifier<List<Tente>> {
  final ApiService api = ApiService();

  @override
  Future<List<Tente>> build() async {
    return _loadTentes();
  }

  Future<String> _requireGroupeId() async {
    final prefs = await SharedPreferences.getInstance();
    final groupeId = prefs.getString('groupeId');
    if (groupeId == null || groupeId.isEmpty) {
      throw Exception("Aucun groupe n’est sélectionné. Impossible de continuer.");
    }
    return groupeId;
  }

  Future<List<Tente>> _loadTentes() async {
    final groupeId = await _requireGroupeId();

    final data = await api.getTentes(groupeId);

    final dtos = data.map((e) => TenteDto.fromJson(e)).toList();
    final tentes = dtos.map(mapTenteDtoToDomain).toList()
      ..sort((a, b) => a.nom.compareTo(b.nom));

    return tentes;
  }

  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async => _loadTentes());
  }

  Future<void> deleteTente(int id) async {
    final groupeId = await _requireGroupeId();
    await api.deleteTente(id, groupeId: groupeId);
    await reload();
  }

  Future<void> createTente(Tente tente) async {
    final groupeId = await _requireGroupeId();
    final dto = mapTenteDomainToDto(tente);
    final json = dto.toJson()..['groupeId'] = groupeId;

    await api.createTente(json);
    await reload();
  }

  Future<void> updateTente(Tente tente) async {
    final groupeId = await _requireGroupeId();
    final dto = mapTenteDomainToDto(tente);
    final json = dto.toJson()..['groupeId'] = groupeId;

    await api.updateTente(tente.id, json);
    await reload();
  }
}

final tentesProvider =
AsyncNotifierProvider<TentesController, List<Tente>>(TentesController.new);
