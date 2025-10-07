import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logistiscout/domain/entities/controle.dart';
import 'package:logistiscout/data/repositories/controle_repository.dart';

/// Riverpod FamilyAsyncNotifier controller for managing contrôles of a specific tente
class ControleController extends FamilyAsyncNotifier<List<Controle>, int> {
  final _repo = ControleRepository();

  @override
  Future<List<Controle>> build(int tenteId) async {
    return _repo.getControles(tenteId);
  }

  /// Reload all contrôles for this tente
  Future<void> reload() async {
    final tenteId = arg; // Built-in getter for FamilyAsyncNotifier
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async => _repo.getControles(tenteId));
  }

  /// Add a new contrôle
  Future<void> addControle(Controle controle) async {
    await _repo.addControle(controle);
    await reload();
  }

  /// Update an existing contrôle
  Future<void> updateControle(Controle controle) async {
    if (controle.id == null) return;
    await _repo.updateControle(controle);
    await reload();
  }

  /// Delete a contrôle
  Future<void> deleteControle(int controleId) async {
    await _repo.deleteControle(controleId);
    await reload();
  }
}

/// ✅ Correct provider family type
final controleProvider =
AsyncNotifierProvider.family<ControleController, List<Controle>, int>(
  ControleController.new,
);
