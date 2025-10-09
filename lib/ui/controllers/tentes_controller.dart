import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logistiscout/data/mappers/tente_mapper.dart';
import 'package:logistiscout/data/models/tente_dto.dart';
import 'package:logistiscout/data/repositories/tente_repository_impl.dart';
import 'package:logistiscout/domain/entities/tente.dart';
import 'package:logistiscout/domain/repositories/tente_repository.dart';
import 'package:logistiscout/services/api_service.dart';
import 'package:logistiscout/services/local_storage_service.dart';
import 'dart:developer' as developer;

class TentesController extends AsyncNotifier<List<Tente>> {
  late final TenteRepository _repo;

  @override
  Future<List<Tente>> build() async {
    _repo = TenteRepositoryImpl(ApiService());
    return _loadTentes();
  }

  Future<List<Tente>> _loadTentes() async {
    try {
      developer.log('[TentesController] Loading tents...');
      final groupId = await LocalStorageService.instance.getGroupId();
      if (groupId == null) {
        throw Exception('Aucun groupe sélectionné.');
      }

      final data = await _repo.getAllTentes();
      developer.log('[TentesController] Loaded ${data.length} tents');

      data.sort((a, b) => a.nom.toLowerCase().compareTo(b.nom.toLowerCase()));

      return data;
    } catch (e, st) {
      developer.log('[TentesController] _loadTentes() failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async => _loadTentes());
  }

  Future<void> deleteTente(int id) async {
    try {
      final groupId = await LocalStorageService.instance.getGroupId();
      if (groupId == null) throw Exception('Groupe introuvable.');
      await _repo.deleteTente(id, groupId);
      await reload();
    } catch (e, st) {
      developer.log('[TentesController] deleteTente() failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> createTente(Tente tente) async {
    try {
      final groupId = await LocalStorageService.instance.getGroupId();
      if (groupId == null) throw Exception('Groupe introuvable.');

      await _repo.createTente(groupId, tente);
      await reload();
    } catch (e, st) {
      developer.log('[TentesController] createTente() failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> updateTente(Tente tente) async {
    try {
      final groupId = await LocalStorageService.instance.getGroupId();
      if (groupId == null) throw Exception('Groupe introuvable.');

      await _repo.updateTente(groupId, tente);
      await reload();
    } catch (e, st) {
      developer.log('[TentesController] updateTente() failed', error: e, stackTrace: st);
      rethrow;
    }
  }
}

final tentesProvider =
AsyncNotifierProvider<TentesController, List<Tente>>(TentesController.new);
