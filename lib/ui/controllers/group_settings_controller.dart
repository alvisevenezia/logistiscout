import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logistiscout/domain/entities/group.dart';
import 'package:logistiscout/domain/entities/tent_status.dart';
import 'package:logistiscout/data/repositories/group_repository.dart';
import 'package:logistiscout/domain/entities/unit.dart';
import '../../core/di.dart';

class GroupSettingsController extends AsyncNotifier<Group> {
  GroupRepository get _groupRepository => ref.read(groupRepositoryProvider);

  @override
  FutureOr<Group> build() async {
    ref.onDispose(() {});
    return _groupRepository.getGroupInfo();
  }

  Future<bool> _updateGroup(Group updatedGroup) async {
    final previous = state.valueOrNull;
    state = AsyncData(updatedGroup);
    try {
      await _groupRepository.updateGroup(updatedGroup);
      return true;
    } catch (e, st) {
      if (previous != null) {
        state = AsyncData(previous);
      } else {
        state = AsyncError(e, st);
      }
      return false;
    }
  }

  void setName(String name) {
    final group = state.valueOrNull;
    if (group == null) return;

    _updateGroup(group.copyWith(name: name));
  }

  void setLogin(String login) {
    final group = state.valueOrNull;
    if (group == null) return;

    _updateGroup(group.copyWith(login: login));
  }

  void setPassword(String password) async {
    await _groupRepository.changePassword(password);
  }

  Future<bool> saveProfileFields({
    String? name,
    String? email,
    String? login,
  }) async {
    final group = state.valueOrNull;
    if (group == null) return false;

    final normalizedName = name?.trim();
    final normalizedEmail = email?.trim();
    final normalizedLogin = login?.trim();

    if (normalizedEmail == null || normalizedEmail.isEmpty) {
      return false;
    }

    return _updateGroup(
      group.copyWith(
        name: normalizedName == null || normalizedName.isEmpty
            ? null
            : normalizedName,
        email: normalizedEmail,
        login: normalizedLogin == null || normalizedLogin.isEmpty
            ? null
            : normalizedLogin,
      ),
    );
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

  Future<bool> addTentStatus({required String name, required int color}) async {
    final group = state.valueOrNull;
    if (group == null) return false;

    final normalized = name.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    final exists = group.tentStatuses.any(
      (s) => s.name.trim().toLowerCase() == normalized,
    );
    if (exists) return false;

    await _groupRepository.createTentStatus(
      name: name.trim(),
      color: color,
      order: group.tentStatuses.length,
    );
    await reload();
    return true;
  }

  Future<bool> updateTentStatus(
    int statusId, {
    required String name,
    required int color,
    bool? isArchived,
  }) async {
    final group = state.valueOrNull;
    if (group == null) return false;

    final normalized = name.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    final duplicate = group.tentStatuses.any(
      (s) => s.id != statusId && s.name.trim().toLowerCase() == normalized,
    );
    if (duplicate) return false;

    await _groupRepository.updateTentStatus(
      statusId,
      name: name.trim(),
      color: color,
      isArchived: isArchived,
    );
    await reload();
    return true;
  }

  Future<void> archiveTentStatus(int statusId) async {
    await _groupRepository.deleteTentStatus(statusId, archiveOnly: true);
    await reload();
  }

  Future<void> removeTentStatus(
    int statusId, {
    int? replacementStatusId,
  }) async {
    await _groupRepository.deleteTentStatus(
      statusId,
      replacementStatusId: replacementStatusId,
    );
    await reload();
  }

  Future<void> duplicateTentStatus(int statusId) async {
    final group = state.valueOrNull;
    if (group == null) return;
    final matches = group.tentStatuses.where((s) => s.id == statusId);
    if (matches.isEmpty) return;
    final source = matches.first;

    var nextName = '${source.name} (copie)';
    var suffix = 2;
    final names = group.tentStatuses
        .map((s) => s.name.trim().toLowerCase())
        .toSet();
    while (names.contains(nextName.trim().toLowerCase())) {
      nextName = '${source.name} (copie $suffix)';
      suffix++;
    }

    await _groupRepository.createTentStatus(
      name: nextName,
      color: source.color,
      order: group.tentStatuses.length,
    );
    await reload();
  }

  Future<void> reorderTentStatuses(List<TentStatusRef> ordered) async {
    for (var i = 0; i < ordered.length; i++) {
      await _groupRepository.updateTentStatus(ordered[i].id, order: i);
    }
    await reload();
  }

  Future<void> restoreDefaultTentStatuses() async {
    await _groupRepository.resetDefaultTentStatuses();
    await reload();
  }
}
