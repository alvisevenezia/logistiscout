import 'package:flutter_test/flutter_test.dart';
import 'package:logistiscout/data/repositories/event_repository_impl.dart';
import 'package:logistiscout/domain/entities/event.dart';
import 'package:logistiscout/domain/entities/menu.dart';
import 'package:logistiscout/services/api_service.dart';
import 'package:mocktail/mocktail.dart';

class MockApiService extends Mock implements ApiService {}

void main() {
  Event buildEvent({required int id}) {
    return Event(
      id: id,
      nom: 'Camp Test',
      date: DateTime(2026, 4, 9, 10, 0, 0),
      dateFin: DateTime(2026, 4, 11, 18, 0, 0),
      type: 'camp',
      associatedTents: const [1, 2, 3],
      unites: const [10, 11],
      groupId: '2',
    );
  }

  group('EventRepositoryImpl API contract', () {
    test('createEvent envoie le payload attendu', () async {
      final api = MockApiService();
      final repo = EventRepositoryImpl(api);
      final event = buildEvent(id: 42);

      when(() => api.addEvent(any())).thenAnswer((_) async {});

      await repo.createEvent(event);

      final captured =
          verify(() => api.addEvent(captureAny())).captured.single
              as Map<String, dynamic>;

      expect(captured['id'], 42);
      expect(captured['nom'], 'Camp Test');
      expect(captured['type'], 'camp');
      expect(captured['tentesAssociees'], [1, 2, 3]);
      expect(captured['unites'], [10, 11]);
      expect(captured['groupeId'], '2');
      expect(captured['date'], event.date.toIso8601String());
      expect(captured['dateFin'], event.dateFin.toIso8601String());
    });

    test('updateEvent envoie event.id et le payload attendu', () async {
      final api = MockApiService();
      final repo = EventRepositoryImpl(api);
      final event = buildEvent(id: 7);

      when(() => api.updateEvent(any(), any())).thenAnswer((_) async {});

      await repo.updateEvent(event);

      final captured =
          verify(() => api.updateEvent(7, captureAny())).captured.single
              as Map<String, dynamic>;
      expect(captured['nom'], 'Camp Test');
      expect(captured['tentesAssociees'], [1, 2, 3]);
      expect(captured['unites'], [10, 11]);
      expect(captured['groupeId'], '2');
    });

    test('addEventMenu envoie le payload attendu', () async {
      final api = MockApiService();
      final repo = EventRepositoryImpl(api);

      when(() => api.addEventMenu(any())).thenAnswer((_) async {});

      await repo.addEventMenu(
        eventId: 3,
        menuId: 9,
        dayNumber: 2,
        meal: MealType.diner,
        portions: 18,
      );

      final captured =
          verify(() => api.addEventMenu(captureAny())).captured.single
              as Map<String, dynamic>;

      expect(captured, {
        'event_id': 3,
        'menu_id': 9,
        'day_number': 2,
        'type_repas': 'diner',
        'quantite_personnes': 18,
      });
    });

    test('getAllEvents accepte groupeId legacy du backend', () async {
      final api = MockApiService();
      final repo = EventRepositoryImpl(api);

      when(
        () => api.getEventList(),
      ).thenAnswer((_) async => [
        {
          'id': 5,
          'nom': 'Camp Legacy',
          'date': '2026-06-01T10:00:00.000',
          'dateFin': '2026-06-02T16:00:00.000',
          'type': 'camp',
          'tentesAssociees': [4],
          'unites': [2],
          'groupeId': 99,
        },
      ]);

      final events = await repo.getAllEvents();

      expect(events, hasLength(1));
      expect(events.first.groupId, '99');
    });
  });
}
