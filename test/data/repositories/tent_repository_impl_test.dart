import 'package:flutter_test/flutter_test.dart';
import 'package:logistiscout/data/repositories/tente_repository_impl.dart';
import 'package:logistiscout/domain/entities/tente.dart';
import 'package:logistiscout/services/api_service.dart';
import 'package:mocktail/mocktail.dart';

class MockApiService extends Mock implements ApiService {}

void main() {
  Tent buildTent({int id = 1, String nom = 'Tente A'}) {
    return Tent(
      id: id,
      nom: nom,
      uniteId: 1,
      state: TentState.good,
      tentStatusId: 1,
      tentStatusLabel: 'Bon',
      tentStatusColor: 0xFF388E3C,
      comment: 'RAS',
      isFloorEmbedded: false,
      nbPlaces: 8,
      tentType: 'canadienne',
      assignedUnit: 'Scouts-Guides',
      agenda: const [],
      controlHistory: const [],
      colors: const ['vert'],
      groupId: '2',
      team: 'Equipe 1',
      location: 'Local',
    );
  }

  group('TentRepositoryImpl', () {
    test('creation/modification/suppression tente', () async {
      final api = MockApiService();
      final repo = TentRepositoryImpl(api);
      final tent = buildTent();

      when(() => api.createTent(any())).thenAnswer((_) async {});
      when(() => api.updateTent(any(), any())).thenAnswer((_) async {});
      when(() => api.deleteTent(any())).thenAnswer((_) async {});

      await repo.createTent(tent);
      verify(() => api.createTent(any())).called(1);

      await repo.updateTent(tent.copyWith(nom: 'Tente B'));
      verify(() => api.updateTent(1, any())).called(1);

      await repo.deleteTent(1);
      verify(() => api.deleteTent(1)).called(1);
    });

    test('getTentList mappe correctement une tente', () async {
      final api = MockApiService();
      final repo = TentRepositoryImpl(api);

      when(() => api.getTentList()).thenAnswer(
        (_) async => [
          {
            'id': 1,
            'nom': 'Tente A',
            'uniteId': 1,
            'etat': 'Bon',
            'tentStatusId': 10,
            'tentStatusLabel': 'Operationnelle',
            'tentStatusColor': 4281902043,
            'remarques': 'OK',
            'estIntegree': false,
            'nbPlaces': 6,
            'typeTente': 'canadienne',
            'unitePreferee': 'Scouts-Guides',
            'agenda': [],
            'controlHistory': [],
            'couleurs': ['vert'],
            'groupeId': '2',
            'equipe': 'Equipe 1',
            'localisation': 'Hangar',
          },
        ],
      );

      final tents = await repo.getTentList();

      expect(tents.length, 1);
      expect(tents.first.nom, 'Tente A');
      expect(tents.first.tentStatusLabel, 'Operationnelle');
      expect(tents.first.nbPlaces, 6);
    });
  });
}
