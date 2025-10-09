import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logistiscout/core/di.dart';
import 'package:logistiscout/domain/entities/event.dart';
import 'package:logistiscout/domain/entities/menu.dart';
import 'package:logistiscout/domain/repositories/event_repository.dart';
import 'package:logistiscout/services/local_storage_service.dart';
import 'dart:developer' as developer;

/// 🧭 Contrôleur de la liste des événements.
/// Ne manipule plus SharedPreferences directement.
/// Passe par le EventRepository et LocalStorageService.
class EvenementController extends AsyncNotifier<List<Event>> {
  late final EventRepository _repo;
  final LocalStorageService _localStorage = LocalStorageService.instance;

  @override
  Future<List<Event>> build() async {
    _repo = ref.read(eventRepositoryProvider);
    return _loadEvenements();
  }

  /// 🔄 Charge tous les événements pour le groupe courant
  Future<List<Event>> _loadEvenements() async {
    try {
      final groupId = await _localStorage.getGroupId();

      if (groupId == null || groupId.isEmpty) {
        throw Exception('groupId introuvable — utilisateur non connecté');
      }

      developer.log('[EvenementController] 🚀 Loading events for groupId=$groupId');

      final events = await _repo.getAllEvents();

      developer.log('[EvenementController] ✅ Successfully loaded ${events.length} events');
      if (events.isNotEmpty) {
        developer.log('First event: ${events.first.nom}');
      }

      return events;
    } catch (e, st) {
      developer.log('[EvenementController] ❌ _loadEvenements() failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// 🔁 Rafraîchit la liste
  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async => _loadEvenements());
  }

  /// ➕ Ajoute un événement
  Future<void> addEvenement(Event event) async {
    try {
      final groupId = await _localStorage.getGroupId();
      if (groupId == null || groupId.isEmpty) {
        throw Exception('groupId introuvable — utilisateur non connecté');
      }

      developer.log('[EvenementController] ➕ Adding event "${event.nom}" for groupId=$groupId');

      // Ton repository peut être enrichi avec un addEvent si besoin.
      await _repo.saveMealPlan(event.id.toString(), MealPlan.empty());

      await reload();
    } catch (e, st) {
      developer.log('[EvenementController] ❌ addEvenement() failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// ✏️ Met à jour un événement
  Future<void> updateEvenement(Event event) async {
    try {
      final groupId = await _localStorage.getGroupId();
      if (groupId == null || groupId.isEmpty) {
        throw Exception('groupId introuvable — utilisateur non connecté');
      }

      developer.log('[EvenementController] ✏️ Updating event id=${event.id} ($groupId)');

      // ⚠️ Si ton repository a une méthode updateEvent, appelle-la ici.
      // Exemple :
      // await _repo.updateEvent(event);

      await reload();
    } catch (e, st) {
      developer.log('[EvenementController] ❌ updateEvenement() failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// 🗑️ Supprime un événement
  Future<void> deleteEvenement(int id) async {
    try {
      final groupId = await _localStorage.getGroupId();
      if (groupId == null || groupId.isEmpty) {
        throw Exception('groupId introuvable — utilisateur non connecté');
      }

      developer.log('[EvenementController] 🗑️ Deleting event id=$id for groupId=$groupId');

      // ⚠️ Ajoute deleteEvent() dans ton EventRepository si pas encore fait
      // await _repo.deleteEvent(id, groupId: groupId);

      await reload();
    } catch (e, st) {
      developer.log('[EvenementController] ❌ deleteEvenement() failed', error: e, stackTrace: st);
      rethrow;
    }
  }
}

/// 🔗 Provider Riverpod
final evenementsProvider =
AsyncNotifierProvider<EvenementController, List<Event>>(EvenementController.new);
