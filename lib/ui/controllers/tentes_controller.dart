import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logistiscout/data/repositories/tente_repository_impl.dart';
import 'package:logistiscout/domain/entities/event.dart';
import 'package:logistiscout/domain/entities/tente.dart';
import 'package:logistiscout/domain/repositories/tente_repository.dart';
import 'package:logistiscout/services/api_service.dart';
import 'package:logistiscout/services/local_storage_service.dart';
import 'dart:developer' as developer;

import 'package:logistiscout/ui/controllers/evenement_controller.dart';

class TentesController extends AsyncNotifier<List<Tent>> {
  late final TentRepository _repo;

  @override
  Future<List<Tent>> build() async {
    _repo = TenteRepositoryImpl(ApiService());
    return _loadTentes();
  }

  Future<List<Tent>> _loadTentes() async {
    try {
      developer.log('[TentesController] Loading tents...');
      final groupId = await LocalStorageService.instance.getGroupId();
      if (groupId == null) {
        throw Exception('Aucun groupe sélectionné.');
      }

      final data = await _repo.getAllTent();
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
      await _repo.deleteTent(id, groupId);
      await reload();
    } catch (e, st) {
      developer.log('[TentesController] deleteTente() failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> createTente(Tent tente) async {
    try {
      final groupId = await LocalStorageService.instance.getGroupId();
      if (groupId == null) throw Exception('Groupe introuvable.');

      await _repo.createTent(groupId, tente);
      await reload();
    } catch (e, st) {
      developer.log('[TentesController] createTente() failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> updateTente(Tent tente) async {
    try {
      final groupId = await LocalStorageService.instance.getGroupId();
      if (groupId == null) throw Exception('Groupe introuvable.');

      await _repo.updateTent(groupId, tente);
      await reload();
    } catch (e, st) {
      developer.log('[TentesController] updateTente() failed', error: e, stackTrace: st);
      rethrow;
    }
  }
}

final tentesProvider =
AsyncNotifierProvider<TentesController, List<Tent>>(TentesController.new);

final evenementsParTenteProvider = FutureProvider.family<List<Event>, int>((ref, tenteId) async {
  final evenementsAsync = await ref.watch(evenementsProvider.future);

  final evenements = evenementsAsync.where((evt) {
    return evt.associatedTents.contains(tenteId);
  }).toList();

  evenements.sort((a, b) => b.date.compareTo(a.date));

  return evenements.take(3).toList();
});
