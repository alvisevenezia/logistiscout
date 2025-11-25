import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logistiscout/domain/entities/controle.dart';
import 'package:logistiscout/data/repositories/controle_repository.dart';

class ControlController extends FamilyAsyncNotifier<List<Control>, int> {
  final _repo = ControlRepository();

  @override
  Future<List<Control>> build(int tentId) async {
    return _repo.getControlList(tentId);
  }

  Future<void> reload() async {
    final tentId = arg;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async => _repo.getControlList(tentId));
  }

  Future<void> addControl(Control control) async {
    await _repo.addControl(control);
    await reload();
  }

  Future<void> updateControl(Control control) async {
    if (control.id == null) return;
    await _repo.updateControl(control);
    await reload();
  }

  Future<void> deleteControl(int controlId) async {
    await _repo.deleteControl(controlId);
    await reload();
  }
}

final controlProvider =
AsyncNotifierProvider.family<ControlController, List<Control>, int>(
  ControlController.new,
);
