import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logistiscout/domain/entities/group.dart';
import 'package:logistiscout/domain/entities/group_unit.dart';
import 'package:logistiscout/data/repositories/group_repository.dart';
import 'package:logistiscout/domain/entities/unit.dart';
import '../../core/di.dart';

class GroupSettingsController extends AsyncNotifier<Group> {
  GroupRepository get _groupRepository => ref.read(groupRepositoryProvider);

  @override
  FutureOr<Group> build() async {
    return _groupRepository.getGroupInfo();
  }

  Future<void> _updateGroup(Group updatedGroup) async {
    final previous = state.valueOrNull;
    state = AsyncData(updatedGroup);
    try {
      await _groupRepository.updateGroup(updatedGroup);
    } catch (e, st) {
      if (previous != null) {
        state = AsyncData(previous);
      } else {
        state = AsyncError(e, st);
      }
    }
  }

  void setName(String name) {
    final group = state.valueOrNull;
    if (group == null) return;

    _updateGroup(group.copyWith(name: name));
  }

  void setEmail(String email) {
    final group = state.valueOrNull;
    if (group == null) return;

    _updateGroup(group.copyWith(email: email));
  }

  void setLogin(String login) {
    final group = state.valueOrNull;
    if (group == null) return;

    _updateGroup(group.copyWith(login: login));
  }

  void setPassword(String password) async {
    await _groupRepository.changePassword(password);
  }

  void setType(String type) {
    final group = state.valueOrNull;
    if (group == null) return;

    _updateGroup(group.copyWith(type: type));
  }

  Future<void> createDefaultUnitsIfEmpty() async {
    final current = state.value;

    if (current == null) return;

    if (current.units.isNotEmpty) return;

    final isMarin = current.type.trim().toLowerCase().contains('marin');
    final defaultUnits = isMarin
        ? [
            {'name': 'Farfadets', 'color': 0xFF65bc99},
            {'name': 'Moussaillons', 'color': 0xFF65bc99},
            {'name': 'Mousses', 'color': 0xFF0077b3},
            {'name': 'Marins', 'color': 0xFFd03f15},
            {'name': 'Compagnons', 'color': 0xFF007254},
            {'name': 'Groupe', 'color': 0xFF420068},
          ]
        : [
            {'name': 'Farfadets', 'color': 0xFF65bc99},
            {'name': 'Louveteaux-Jeanettes', 'color': 0xFFFF8300},
            {'name': 'Scouts-Guides', 'color': 0xFF0077b3},
            {'name': 'Pionniers-Caravelles', 'color': 0xFFd03f15},
            {'name': 'Compagnons', 'color': 0xFF007254},
            {'name': 'Groupe', 'color': 0xFF420068},
          ];

    for (final unit in defaultUnits) {
      await _groupRepository.createUnit(
        name: unit['name']! as String,
        color: unit['color']! as int,
      );
    }
    await reload();
  }

  /// Add a unit
  Future<void> addUnit({
    required String name,
    required int color,
    required Unit type,
  }) async {
    await _groupRepository.createUnit(name: name, color: color);
    await reload();
  }

  /// Update a unit
  Future<void> updateUnit(
    String unitId, {
    String? name,
    int? color,
    Unit? type,
  }) async {
    final parsedId = int.tryParse(unitId);
    if (parsedId == null) return;
    await _groupRepository.updateUnit(
      unitId: parsedId,
      name: name,
      color: color,
    );
    await reload();
  }

  /// Remove a unit
  Future<void> removeUnit(String unitId) async {
    final parsedId = int.tryParse(unitId);
    if (parsedId == null) return;
    await _groupRepository.deleteUnit(parsedId);
    await reload();
  }

  /// Reload from repository
  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _groupRepository.getGroupInfo());
  }
}
