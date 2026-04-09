import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistiscout/core/di.dart';
import 'package:logistiscout/domain/entities/event.dart';
import 'package:logistiscout/domain/repositories/event_repository.dart';
import 'package:logistiscout/ui/controllers/evenement_controller.dart';
import 'package:mocktail/mocktail.dart';

class MockEventRepository extends Mock implements EventRepository {}

void main() {
  Event buildEvent({required int id, required String name}) {
    return Event(
      id: id,
      nom: name,
      date: DateTime(2026, 4, 9),
      dateFin: DateTime(2026, 4, 10),
      type: 'camp',
      associatedTents: const [1],
      unites: const [1],
      groupId: '2',
    );
  }

  group('EvenementController', () {
    test('creation/modification/suppression evenement', () async {
      final repo = MockEventRepository();
      var events = <Event>[buildEvent(id: 1, name: 'Week-end')];
      final toCreate = buildEvent(id: 2, name: 'Camp ete');
      final toUpdate = buildEvent(id: 2, name: 'Camp ete v2');

      when(() => repo.getAllEvents()).thenAnswer((_) async => events);
      when(() => repo.createEvent(toCreate)).thenAnswer((_) async {
        events = [...events, toCreate];
      });
      when(() => repo.updateEvent(toUpdate)).thenAnswer((_) async {
        events = events.map((e) => e.id == toUpdate.id ? toUpdate : e).toList();
      });
      when(() => repo.deleteEvent(2)).thenAnswer((_) async {
        events = events.where((e) => e.id != 2).toList();
      });

      final container = ProviderContainer(
        overrides: [eventRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      final initial = await container.read(evenementsProvider.future);
      expect(initial.length, 1);

      final controller = container.read(evenementsProvider.notifier);

      await controller.addEvenement(toCreate);
      verify(() => repo.createEvent(toCreate)).called(1);
      expect(container.read(evenementsProvider).valueOrNull?.length, 2);

      await controller.updateEvenement(toUpdate);
      verify(() => repo.updateEvent(toUpdate)).called(1);
      expect(
        container.read(evenementsProvider).valueOrNull?.last.nom,
        'Camp ete v2',
      );

      await controller.deleteEvenement(2);
      verify(() => repo.deleteEvent(2)).called(1);
      expect(container.read(evenementsProvider).valueOrNull?.length, 1);
    });
  });
}
