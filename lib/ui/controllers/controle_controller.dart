import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logistiscout/domain/entities/controle.dart';
import 'package:logistiscout/data/repositories/controle_repository.dart';

/// Riverpod FamilyAsyncNotifier controller for managing contrôles of a specific tente
class ControleController extends FamilyAsyncNotifier<List<Control>, int> {
  final _repo = ControlRepository();

  @override
  Future<List<Control>> build(int tenteId) async {
    return _repo.getControlList(tenteId);
  }

  /// Reload all contrôles for this tente
  Future<void> reload() async {
    final tenteId = arg; // Built-in getter for FamilyAsyncNotifier
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async => _repo.getControlList(tenteId));
  }

  /// Add a new contrôle
  Future<void> addControle(Control controle) async {
    await _repo.addControl(controle);
    await reload();
  }

  /// Update an existing contrôle
  Future<void> updateControle(Control controle) async {
    if (controle.id == null) return;
    await _repo.updateControl(controle);
    await reload();
  }

  /// Delete a contrôle
  Future<void> deleteControle(int controleId) async {
    await _repo.deleteControl(controleId);
    await reload();
  }
}

/// ✅ Correct provider family type
final controleProvider =
AsyncNotifierProvider.family<ControleController, List<Control>, int>(
  ControleController.new,
);
