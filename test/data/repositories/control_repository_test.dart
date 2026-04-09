import 'package:flutter_test/flutter_test.dart';
import 'package:logistiscout/data/repositories/controle_repository.dart';
import 'package:logistiscout/domain/entities/controle.dart';
import 'package:logistiscout/services/api_service.dart';
import 'package:mocktail/mocktail.dart';

class MockApiService extends Mock implements ApiService {}

void main() {
  group('ControlRepository', () {
    test('controle: creation', () async {
      final api = MockApiService();
      final repo = ControlRepository(api: api);
      final control = Control(
        tentId: 1,
        userId: 42,
        date: DateTime(2026, 4, 9),
        checklist: const {'piquets': true},
        comment: 'Tout va bien',
      );

      when(() => api.addControl(any())).thenAnswer(
        (_) async => {
          'id': 99,
          'tenteId': 1,
          'userId': 42,
          'date': DateTime(2026, 4, 9).toIso8601String(),
          'checklist': {'piquets': true},
          'remarques': 'Tout va bien',
        },
      );

      final created = await repo.addControl(control);

      expect(created.id, 99);
      expect(created.tentId, 1);
      verify(() => api.addControl(any())).called(1);
    });

    test('controle: modification', () async {
      final api = MockApiService();
      final repo = ControlRepository(api: api);
      final control = Control(
        id: 7,
        tentId: 1,
        userId: 42,
        date: DateTime(2026, 4, 9),
        checklist: const {'toile': true},
        comment: 'RAS',
      );

      when(() => api.updateControl(7, any())).thenAnswer((_) async {});

      final updated = await repo.updateControl(control);

      expect(updated.id, 7);
      verify(() => api.updateControl(7, any())).called(1);
    });

    test('controle: suppression', () async {
      final api = MockApiService();
      final repo = ControlRepository(api: api);

      when(() => api.deleteControl(7)).thenAnswer((_) async {});

      await repo.deleteControl(7);

      verify(() => api.deleteControl(7)).called(1);
    });

    test('updateControl echoue si id absent', () async {
      final api = MockApiService();
      final repo = ControlRepository(api: api);
      final control = Control(
        tentId: 1,
        userId: 42,
        date: DateTime(2026, 4, 9),
        checklist: const {'toile': true},
        comment: 'RAS',
      );

      expect(() => repo.updateControl(control), throwsException);
      verifyNever(() => api.updateControl(any(), any()));
    });
  });
}
