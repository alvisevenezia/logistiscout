import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logistiscout/domain/entities/group.dart';
import 'package:logistiscout/domain/entities/group_unit.dart';
import 'package:logistiscout/data/repositories/group_repository.dart';
import 'package:logistiscout/domain/entities/unit.dart';
import '../../core/di.dart';


/// PROVIDER
final groupSettingsControllerProvider =
AsyncNotifierProvider<GroupSettingsController, Group>(
  GroupSettingsController.new,
);



/// CONTROLLER
class GroupSettingsController extends AsyncNotifier<Group> {
  late final GroupRepository groupRepository;

  @override
  FutureOr<Group> build() async {
    groupRepository = ref.read(groupRepositoryProvider);
    return groupRepository.getGroupInfo();
  }

  // =====================================================================
  //                         UPDATE HELPER
  // =====================================================================

  /// Set state & persist
  Future<void> _updateGroup(Group newGroup) async {
    state = AsyncData(newGroup);
    await groupRepository.updateGroup(newGroup);
  }

  // =====================================================================
  //                         BASIC FIELDS
  // =====================================================================

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
    await groupRepository.changePassword(password);
  }

  void setType(String type) {
    final group = state.valueOrNull;
    if (group == null) return;

    _updateGroup(group.copyWith(type: type));
  }

  // =====================================================================
  //                         UNITS MANAGEMENT
  // =====================================================================

  /// Add a unit
  Future<void> addUnit({
    required String name,
    required int color,
    required Unit type,
  }) async {
    final group = state.valueOrNull;
    if (group == null) return;

    // Create a new unique ID (timestamp)
    final newUnit = GroupUnit(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      color: color,
      type: type,
    );

    final updatedUnits = [...group.units, newUnit];

    _updateGroup(group.copyWith(units: updatedUnits));
  }

  /// Update a unit
  Future<void> updateUnit(
      String unitId, {
        String? name,
        int? color,
        Unit? type,
      }) async {
    final group = state.valueOrNull;
    if (group == null) return;

    final updated = group.units.map((u) {
      if (u.id == unitId) {
        return u.copyWith(
          name: name,
          color: color,
          type: type,
        );
      }
      return u;
    }).toList();

    _updateGroup(group.copyWith(units: updated));
  }

  /// Remove a unit
  Future<void> removeUnit(String unitId) async {
    final group = state.valueOrNull;
    if (group == null) return;

    final updated = group.units.where((u) => u.id != unitId).toList();

    _updateGroup(group.copyWith(units: updated));
  }

  // =====================================================================
  //                         FORCE REFRESH
  // =====================================================================

  /// Reload from repository
  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => groupRepository.getGroupInfo());
  }
}