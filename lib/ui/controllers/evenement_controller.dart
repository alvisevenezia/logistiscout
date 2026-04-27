import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logistiscout/core/di.dart';
import 'package:logistiscout/domain/entities/event.dart';
import 'package:logistiscout/domain/repositories/event_repository.dart';
import 'dart:developer' as developer;

class EvenementController extends AsyncNotifier<List<Event>> {
  EventRepository get _repo => ref.read(eventRepositoryProvider);

  @override
  Future<List<Event>> build() async {
    return _loadEvenements();
  }

  Future<List<Event>> _loadEvenements() async {
    try {
      developer.log('[EvenementController] 🚀 Loading events ');

      final events = await _repo.getAllEvents();

      developer.log(
        '[EvenementController] ✅ Successfully loaded ${events.length} events',
      );
      if (events.isNotEmpty) {
        developer.log('First event: ${events.first.nom}');
      }

      return events;
    } catch (e, st) {
      developer.log(
        '[EvenementController] ❌ _loadEvenements() failed',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async => _loadEvenements());
  }

  Future<void> addEvenement(Event event) async {
    try {
      developer.log('[EvenementController] ➕ Adding event "${event.nom}" ');

      await _repo.createEvent(event);

      await reload();
    } catch (e, st) {
      developer.log(
        '[EvenementController] ❌ addEvenement() failed',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  Future<void> updateEvenement(Event event) async {
    try {
      developer.log('[EvenementController] ✏️ Updating event id=${event.id}');

      await _repo.updateEvent(event);

      await reload();
    } catch (e, st) {
      developer.log(
        '[EvenementController] ❌ updateEvenement() failed',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  Future<void> deleteEvenement(int id) async {
    try {
      developer.log('[EvenementController] 🗑️ Deleting event id=$id ');

      await _repo.deleteEvent(id);
      await reload();
    } catch (e, st) {
      developer.log(
        '[EvenementController] ❌ deleteEvenement() failed',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }
}

final evenementsProvider =
    AsyncNotifierProvider<EvenementController, List<Event>>(
      EvenementController.new,
    );
