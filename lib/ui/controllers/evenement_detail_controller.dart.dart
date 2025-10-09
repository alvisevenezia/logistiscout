import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logistiscout/domain/entities/event.dart';
import 'package:logistiscout/domain/entities/menu.dart';
import 'package:logistiscout/domain/entities/recipe.dart';
import 'package:logistiscout/domain/entities/tente.dart';
import 'package:logistiscout/domain/repositories/event_repository.dart';
import 'package:logistiscout/domain/repositories/recipe_repository.dart';
import 'package:logistiscout/domain/repositories/tente_repository.dart';
import 'package:logistiscout/domain/usecases/duplicate_menu.dart';
import 'package:logistiscout/domain/usecases/get_event.dart';
import 'package:logistiscout/domain/usecases/get_meal_plan.dart';
import 'package:logistiscout/domain/usecases/save_meal_plan.dart';
import 'package:logistiscout/core/di.dart';
import 'package:logistiscout/services/local_storage_service.dart';
import 'dart:developer' as developer;

import 'package:logistiscout/ui/controllers/tentes_controller.dart';

/// 🧭 Contrôleur dédié à la page Détail d’un événement.
/// Gère les onglets (Infos, Tentes, Menus) et toute la logique des menus/recettes.
class EvenementDetailController extends ChangeNotifier {
  // === Dépendances (use cases) ===
  final GetEvent getEventUC;
  final GetMealPlan getMealPlanUC;
  final SaveMealPlan saveMealPlanUC;
  final DuplicateMenu duplicateMenuUC;
  final RecipeRepository recipeRepo;
  final TenteRepository tenteRepo;
  final EventRepository eventRepo;

  // === État interne ===
  Event? event;
  MealPlan? currentPlan;
  DateTime? selectedDate;
  MealType selectedMeal = MealType.dejeuner;
  bool loading = false;
  String? error;
  List<Tente> allTentes = [];

  EvenementDetailController({
    required this.getEventUC,
    required this.getMealPlanUC,
    required this.saveMealPlanUC,
    required this.duplicateMenuUC,
    required this.recipeRepo,
    required this.tenteRepo,
    required this.eventRepo,
  });

  // === Initialisation ===
  Future<void> init(String eventId) async {
    loading = true;
    error = null;
    developer.log('[EvenementDetailController] 🟡 init() starting (eventId=$eventId)');
    notifyListeners();

    try {
      event = await getEventUC(eventId);
      developer.log('[EvenementDetailController] ✅ Event loaded: ${event?.nom}');
      await loadTentes();
      allTentes = await tenteRepo.getAllTentes();
      developer.log('[EvenementDetailController] ✅ Loaded ${allTentes.length} tentes');
      selectedDate = event?.date;
      await _loadPlan(eventId);
    } catch (e, st) {
      error = e.toString();
      developer.log('[EvenementDetailController] ❌ init() failed', error: e, stackTrace: st);
    } finally {
      loading = false;
      developer.log('[EvenementDetailController] 🟢 init() completed');
      notifyListeners();
    }
  }
// --- Nouveaux champs pour la gestion des tentes ---
  List<Tente> availableTentes = [];
  Set<int> selectedTenteIds = {};

  /// Charge toutes les tentes assignées + dispo
  Future<void> loadTentes() async {
    if (event == null) return;
    try {
      loading = true;
      notifyListeners();

      allTentes = await tenteRepo.getAllTentes();
      availableTentes = await tenteRepo.getAvailableTentes(event!.date, event!.dateFin);
      developer.log('[EvenementDetailController] ✅ Loaded ${availableTentes.length} available tents');
    } catch (e, st) {
      developer.log('[EvenementDetailController] ❌ loadTentes failed', error: e, stackTrace: st);
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Sélectionne ou désélectionne une tente
  void toggleTenteSelection(int id) {
    if (selectedTenteIds.contains(id)) {
      selectedTenteIds.remove(id);
    } else {
      selectedTenteIds.add(id);
    }
    notifyListeners();
  }

  /// Applique la bascule assigné/dispo et sync backend
  Future<void> applyTenteChanges() async {
    if (event == null) return;

    try {
      final updatedIds = Set<int>.from(event!.tentesAssociees);
      for (final id in selectedTenteIds) {
        updatedIds.contains(id) ? updatedIds.remove(id) : updatedIds.add(id);
      }

      final updatedEvent = event!.copyWith(tentesAssociees: updatedIds.toList());
      event = updatedEvent;
      selectedTenteIds.clear();
      notifyListeners();

      final groupId = await LocalStorageService.instance.getGroupId();
      if (groupId == null) throw Exception("Group ID not found");

      await eventRepo.updateEventTentes(
        groupId,
        updatedEvent.id,
        updatedIds.toList(),
        updatedEvent,
      );

      developer.log('[EvenementDetailController] ✅ Tentes updated on backend');
    } catch (e, st) {
      developer.log('[EvenementDetailController] ❌ applyTenteChanges failed', error: e, stackTrace: st);
      error = e.toString();
    }
  }

  Future<void> _loadPlan(String eventId) async {
    if (selectedDate == null) {
      developer.log('[EvenementDetailController] ⚠️ _loadPlan() skipped: selectedDate is null');
      return;
    }

    developer.log('[EvenementDetailController] 🔵 _loadPlan() start (eventId=$eventId, '
        'date=$selectedDate, meal=$selectedMeal)');

    try {
      final start = DateTime.now();
      currentPlan = await getMealPlanUC(eventId, selectedDate!, selectedMeal);
      final duration = DateTime.now().difference(start).inMilliseconds;

      developer.log('[EvenementDetailController] ✅ _loadPlan() success '
          '(${currentPlan?.items.length ?? 0} items, ${duration}ms)');
    } catch (e, st) {
      error = e.toString();
      developer.log('[EvenementDetailController] ❌ _loadPlan() failed', error: e, stackTrace: st);
    }
    notifyListeners();
  }

  // === Navigation et changement d’état ===
  Future<void> changeDate(DateTime date) async {
    developer.log('[EvenementDetailController] 🔄 changeDate() → $date');
    selectedDate = date;
    await _loadPlan(event!.id.toString());
  }

  Future<void> changeMeal(MealType meal) async {
    developer.log('[EvenementDetailController] 🔄 changeMeal() → $meal');
    selectedMeal = meal;
    await _loadPlan(event!.id.toString());
  }

  // === Gestion des portions ===
  Future<void> setPortions(int portions) async {
    if (currentPlan == null) return;
    developer.log('[EvenementDetailController] ⚙️ setPortions() to $portions');
    currentPlan = currentPlan!.copyWith(portions: portions);
    notifyListeners();

    try {
      final start = DateTime.now();
      await saveMealPlanUC(event!.id.toString(), currentPlan!);
      final duration = DateTime.now().difference(start).inMilliseconds;
      developer.log('[EvenementDetailController] ✅ saveMealPlanUC completed (${duration}ms)');
    } catch (e, st) {
      developer.log('[EvenementDetailController] ❌ saveMealPlanUC failed', error: e, stackTrace: st);
    }
  }

  // === Gestion des recettes ===
  Future<void> addRecipes(List<MenuItem> items) async {
    if (items.isEmpty) return;
    developer.log('[EvenementDetailController] ➕ createRecipes(${items.length})');

    final recipeRepo = this.recipeRepo;
    int successCount = 0;

    for (final item in items) {
      try {
        await recipeRepo.createRecipe(item.recipe);
        successCount++;
        developer.log('✅ Recette "${item.recipe.title}" créée sur le backend');
      } catch (e, st) {
        developer.log(
          '[EvenementDetailController] ❌ Échec création recette "${item.recipe.title}"',
          error: e,
          stackTrace: st,
        );
        // On continue pour les autres recettes
      }
    }

    developer.log('[EvenementDetailController] ✅ $successCount/${items.length} recettes créées avec succès');
  }

  /// Ajoute des recettes existantes au plan de repas courant (sans les créer)
  Future<void> addRecipesToMealPlan(List<MenuItem> items) async {
    if (currentPlan == null) return;
    developer.log('[EvenementDetailController] ➕ addRecipesToMealPlan(${items.length})');

    final updated = List<MenuItem>.of(currentPlan!.items)..addAll(items);
    currentPlan = currentPlan!.copyWith(items: updated);
    notifyListeners();

    try {
      await saveMealPlanUC(event!.id.toString(), currentPlan!);
      developer.log('[EvenementDetailController] ✅ addRecipesToMealPlan saved');
    } catch (e, st) {
      developer.log('[EvenementDetailController] ❌ addRecipesToMealPlan failed', error: e, stackTrace: st);
    }
  }

  Future<void> removeRecipeAt(int index) async {
    if (currentPlan == null) return;
    developer.log('[EvenementDetailController] 🗑️ removeRecipeAt(index=$index)');
    final updated = List<MenuItem>.of(currentPlan!.items)..removeAt(index);
    currentPlan = currentPlan!.copyWith(items: updated);
    notifyListeners();

    try {
      await saveMealPlanUC(event!.id.toString(), currentPlan!);
      developer.log('[EvenementDetailController] ✅ removeRecipeAt saved');
    } catch (e, st) {
      developer.log('[EvenementDetailController] ❌ removeRecipeAt failed', error: e, stackTrace: st);
    }
  }

  Future<void> moveRecipe(int oldIndex, int newIndex) async {
    if (currentPlan == null) return;
    developer.log('[EvenementDetailController] 🔀 moveRecipe($oldIndex → $newIndex)');
    final updated = List<MenuItem>.of(currentPlan!.items);
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex > oldIndex ? newIndex - 1 : newIndex, item);
    currentPlan = currentPlan!.copyWith(items: updated);
    notifyListeners();

    try {
      await saveMealPlanUC(event!.id.toString(), currentPlan!);
      developer.log('[EvenementDetailController] ✅ moveRecipe saved');
    } catch (e, st) {
      developer.log('[EvenementDetailController] ❌ moveRecipe failed', error: e, stackTrace: st);
    }
  }

  // === Duplication ===
  Future<void> duplicateTo(List<MapEntry<DateTime, MealType>> targets) async {
    if (currentPlan == null) return;
    developer.log('[EvenementDetailController] 📄 duplicateTo() → ${targets.length} targets');
    try {
      final start = DateTime.now();
      await duplicateMenuUC(event!.id.toString(), currentPlan!, targets);
      final duration = DateTime.now().difference(start).inMilliseconds;
      developer.log('[EvenementDetailController] ✅ duplicateMenuUC done (${duration}ms)');
    } catch (e, st) {
      developer.log('[EvenementDetailController] ❌ duplicateMenuUC failed', error: e, stackTrace: st);
    }
  }
}

// === Provider ===
final evenementDetailProvider =
ChangeNotifierProvider.family<EvenementDetailController, String>((ref, eventId) {
  final getEventUC = ref.read(getEventUseCaseProvider);
  final getMealPlanUC = ref.read(getMealPlanUseCaseProvider);
  final saveMealPlanUC = ref.read(saveMealPlanUseCaseProvider);
  final duplicateMenuUC = ref.read(duplicateMenuUseCaseProvider);
  final recipeRepo = ref.read(recipeRepositoryProvider);
  final tenteRepo = ref.read(tenteRepositoryProvider);
  final eventRepo = ref.read(eventRepositoryProvider);

  final ctrl = EvenementDetailController(
    getEventUC: getEventUC,
    getMealPlanUC: getMealPlanUC,
    saveMealPlanUC: saveMealPlanUC,
    duplicateMenuUC: duplicateMenuUC,
    recipeRepo: recipeRepo,
    tenteRepo: tenteRepo,
    eventRepo: eventRepo,
  );

  ctrl.init(eventId);
  return ctrl;
});
