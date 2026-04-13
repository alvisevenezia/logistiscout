import 'package:flutter_test/flutter_test.dart';
import 'package:logistiscout/data/repositories/group_repository.dart';
import 'package:logistiscout/services/api_service.dart';
import 'package:mocktail/mocktail.dart';

class MockApiService extends Mock implements ApiService {}

void main() {
  group('GroupRepository API contract', () {
    test(
      'updateGroupProfileFields envoie uniquement les champs attendus',
      () async {
        final api = MockApiService();
        final repo = GroupRepository(api: api);

        when(
          () => api.updateGroupProfileFields(any()),
        ).thenAnswer((_) async {});

        await repo.updateGroupProfileFields(
          name: 'Groupe X',
          email: 'x@example.com',
          login: 'groupe_x',
          members: '[]',
          type: 'scout',
        );

        final captured =
            verify(
                  () => api.updateGroupProfileFields(captureAny()),
                ).captured.single
                as Map<String, dynamic>;

        expect(captured, {
          'name': 'Groupe X',
          'email': 'x@example.com',
          'login': 'groupe_x',
          'members': '[]',
          'type': 'scout',
        });
      },
    );

    test('createUnit envoie name/color/type', () async {
      final api = MockApiService();
      final repo = GroupRepository(api: api);

      when(() => api.createGroupUnit(any())).thenAnswer(
        (_) async => {
          'id': 1,
          'name': 'Scouts-Guides',
          'color': 0xFF0077B3,
          'type': 'custom',
        },
      );

      await repo.createUnit(
        name: 'Scouts-Guides',
        color: 0xFF0077B3,
        type: 'custom',
      );

      final captured =
          verify(() => api.createGroupUnit(captureAny())).captured.single
              as Map<String, dynamic>;
      expect(captured, {
        'name': 'Scouts-Guides',
        'color': 0xFF0077B3,
        'type': 'custom',
      });
    });

    test('updateUnit envoie uniquement les champs modifies', () async {
      final api = MockApiService();
      final repo = GroupRepository(api: api);

      when(() => api.updateGroupUnit(any(), any())).thenAnswer(
        (_) async => {
          'id': 9,
          'name': 'Scouts',
          'color': 0xFF123456,
          'type': 'custom',
        },
      );

      await repo.updateUnit(unitId: 9, name: 'Scouts', color: 0xFF123456);

      final captured =
          verify(() => api.updateGroupUnit(9, captureAny())).captured.single
              as Map<String, dynamic>;
      expect(captured, {'name': 'Scouts', 'color': 0xFF123456});
    });

    test(
      'deleteTentStatus envoie replacementStatusId et archiveOnly',
      () async {
        final api = MockApiService();
        final repo = GroupRepository(api: api);

        when(
          () => api.deleteTentStatus(
            any(),
            replacementStatusId: any(named: 'replacementStatusId'),
            archiveOnly: any(named: 'archiveOnly'),
          ),
        ).thenAnswer((_) async {});

        await repo.deleteTentStatus(
          12,
          replacementStatusId: 3,
          archiveOnly: true,
        );

        verify(
          () => api.deleteTentStatus(
            12,
            replacementStatusId: 3,
            archiveOnly: true,
          ),
        ).called(1);
      },
    );
  });
}
