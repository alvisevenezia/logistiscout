import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logistiscout/domain/entities/controle.dart';
import 'package:logistiscout/data/repositories/controle_repository.dart';
import 'dart:typed_data';

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

  Future<Control> addControl(Control control) async {
    final createdControl = await _repo.addControl(control);
    await reload();
    return createdControl;
  }

  Future<Control> updateControl(Control control) async {
    if (control.id == null) {
      throw Exception('Cannot update a controle without an ID');
    }
    final updatedControl = await _repo.updateControl(control);
    await reload();
    return updatedControl;
  }

  Future<Control> uploadControlPicture({
    required int controlId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final updatedControl = await _repo.uploadControlPicture(
      controlId: controlId,
      bytes: bytes,
      fileName: fileName,
    );
    await reload();
    return updatedControl;
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
