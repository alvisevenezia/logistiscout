import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistiscout/core/di.dart';
import 'package:logistiscout/data/repositories/group_repository.dart';
import 'package:logistiscout/domain/entities/group.dart';
import 'package:logistiscout/domain/entities/group_unit.dart';
import 'package:logistiscout/domain/entities/tent_status.dart';
import 'package:logistiscout/domain/entities/unit.dart';
import 'package:mocktail/mocktail.dart';

class MockGroupRepository extends Mock implements GroupRepository {}

class FakeGroup extends Fake implements Group {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeGroup());
  });

  Group buildGroup({
    String name = 'Groupe Alpha',
    String email = 'alpha@example.com',
    String login = 'alpha_login',
    List<GroupUnit>? units,
    List<TentStatusRef>? statuses,
  }) {
    return Group(
      id: '1',
      name: name,
      email: email,
      members: '[]',
      login: login,
      type: 'scout',
      units:
          units ??
          [
            GroupUnit(
              id: '10',
              name: 'Groupe',
              color: 0xFF420068,
              type: Unit.groupe,
            ),
          ],
      tentStatuses:
          statuses ??
          const [
            TentStatusRef(
              id: 1,
              name: 'Bon',
              color: 0xFF388E3C,
              order: 0,
              isDefault: true,
              isArchived: false,
            ),
          ],
    );
  }

  group('GroupSettingsController', () {
    test(
      'changement infos groupe: saveProfileFields met a jour le profil',
      () async {
        final repo = MockGroupRepository();
        var current = buildGroup();

        when(() => repo.getGroupInfo()).thenAnswer((_) async => current);
        when(() => repo.updateGroup(any())).thenAnswer((invocation) async {
          final updated = invocation.positionalArguments.first as Group;
          current = updated;
        });

        final container = ProviderContainer(
          overrides: [groupRepositoryProvider.overrideWithValue(repo)],
        );
        addTearDown(container.dispose);

        await container.read(accountControllerProvider.future);

        final ok = await container
            .read(accountControllerProvider.notifier)
            .saveProfileFields(
              name: 'Nouveau Nom',
              email: 'nouveau@example.com',
              login: 'nouveau_login',
            );

        expect(ok, isTrue);
        verify(() => repo.updateGroup(any())).called(1);
        final state = container.read(accountControllerProvider).valueOrNull;
        expect(state, isNotNull);
        expect(state!.name, 'Nouveau Nom');
        expect(state.email, 'nouveau@example.com');
        expect(state.login, 'nouveau_login');
      },
    );

    test('creation/modification/suppression unite', () async {
      final repo = MockGroupRepository();
      var current = buildGroup(units: const []);

      when(() => repo.getGroupInfo()).thenAnswer((_) async => current);
      when(
        () => repo.createUnit(
          name: any(named: 'name'),
          color: any(named: 'color'),
        ),
      ).thenAnswer((invocation) async {
        final name = invocation.namedArguments[#name] as String;
        final color = invocation.namedArguments[#color] as int;
        final newUnit = GroupUnit(
          id: '99',
          name: name,
          color: color,
          type: Unit.fromString(name),
        );
        current = current.copyWith(units: [...current.units, newUnit]);
        return newUnit;
      });
      when(
        () => repo.updateUnit(
          unitId: any(named: 'unitId'),
          name: any(named: 'name'),
          color: any(named: 'color'),
        ),
      ).thenAnswer((invocation) async {
        final id = invocation.namedArguments[#unitId] as int;
        final name = invocation.namedArguments[#name] as String?;
        final color = invocation.namedArguments[#color] as int?;
        current = current.copyWith(
          units: current.units
              .map(
                (u) => u.id == id.toString()
                    ? u.copyWith(name: name ?? u.name, color: color ?? u.color)
                    : u,
              )
              .toList(),
        );
        return current.units.firstWhere((u) => u.id == id.toString());
      });
      when(() => repo.deleteUnit(any())).thenAnswer((invocation) async {
        final id = invocation.positionalArguments.first as int;
        current = current.copyWith(
          units: current.units.where((u) => u.id != id.toString()).toList(),
        );
      });

      final container = ProviderContainer(
        overrides: [groupRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await container.read(accountControllerProvider.future);
      final controller = container.read(accountControllerProvider.notifier);

      await controller.addUnit(
        name: 'Scouts-Guides',
        color: 0xFF0077B3,
        type: Unit.scouts,
      );
      verify(
        () => repo.createUnit(name: 'Scouts-Guides', color: 0xFF0077B3),
      ).called(1);

      await controller.updateUnit(
        '99',
        name: 'Scouts',
        color: 0xFF123456,
        type: Unit.scouts,
      );
      verify(
        () => repo.updateUnit(unitId: 99, name: 'Scouts', color: 0xFF123456),
      ).called(1);

      await controller.removeUnit('99');
      verify(() => repo.deleteUnit(99)).called(1);
    });

    test('creation/modification/suppression status', () async {
      final repo = MockGroupRepository();
      var current = buildGroup(
        statuses: const [
          TentStatusRef(
            id: 1,
            name: 'Bon',
            color: 0xFF388E3C,
            order: 0,
            isDefault: true,
            isArchived: false,
          ),
        ],
      );

      when(() => repo.getGroupInfo()).thenAnswer((_) async => current);
      when(
        () => repo.createTentStatus(
          name: any(named: 'name'),
          color: any(named: 'color'),
          order: any(named: 'order'),
        ),
      ).thenAnswer((invocation) async {
        final name = invocation.namedArguments[#name] as String;
        final color = invocation.namedArguments[#color] as int;
        final order = invocation.namedArguments[#order] as int? ?? 0;
        final created = TentStatusRef(
          id: 2,
          name: name,
          color: color,
          order: order,
          isDefault: false,
          isArchived: false,
        );
        current = current.copyWith(
          tentStatuses: [...current.tentStatuses, created],
        );
        return created;
      });
      when(
        () => repo.updateTentStatus(
          any(),
          name: any(named: 'name'),
          color: any(named: 'color'),
          isArchived: any(named: 'isArchived'),
        ),
      ).thenAnswer((invocation) async {
        final id = invocation.positionalArguments.first as int;
        final name = invocation.namedArguments[#name] as String?;
        final color = invocation.namedArguments[#color] as int?;
        final isArchived = invocation.namedArguments[#isArchived] as bool?;
        current = current.copyWith(
          tentStatuses: current.tentStatuses
              .map(
                (s) => s.id == id
                    ? s.copyWith(
                        name: name ?? s.name,
                        color: color ?? s.color,
                        isArchived: isArchived ?? s.isArchived,
                      )
                    : s,
              )
              .toList(),
        );
        return current.tentStatuses.firstWhere((s) => s.id == id);
      });
      when(
        () => repo.deleteTentStatus(
          any(),
          replacementStatusId: any(named: 'replacementStatusId'),
        ),
      ).thenAnswer((invocation) async {
        final id = invocation.positionalArguments.first as int;
        current = current.copyWith(
          tentStatuses: current.tentStatuses.where((s) => s.id != id).toList(),
        );
      });

      final container = ProviderContainer(
        overrides: [groupRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await container.read(accountControllerProvider.future);
      final controller = container.read(accountControllerProvider.notifier);

      final created = await controller.addTentStatus(
        name: 'A verifier',
        color: 0xFFFFA000,
      );
      expect(created, isTrue);
      verify(
        () => repo.createTentStatus(
          name: 'A verifier',
          color: 0xFFFFA000,
          order: 1,
        ),
      ).called(1);

      final updated = await controller.updateTentStatus(
        2,
        name: 'A reparer',
        color: 0xFFFF0000,
      );
      expect(updated, isTrue);
      verify(
        () => repo.updateTentStatus(
          2,
          name: 'A reparer',
          color: 0xFFFF0000,
          isArchived: null,
        ),
      ).called(1);

      await controller.removeTentStatus(2);
      verify(
        () => repo.deleteTentStatus(2, replacementStatusId: null),
      ).called(1);
    });
  });
}
