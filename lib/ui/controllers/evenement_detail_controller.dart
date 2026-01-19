import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logistiscout/domain/entities/event.dart';
import 'package:logistiscout/domain/entities/ingredient.dart';
import 'package:logistiscout/domain/entities/menu.dart';
import 'package:logistiscout/domain/entities/recipe.dart';
import 'package:logistiscout/domain/entities/tente.dart';
import 'package:logistiscout/domain/repositories/event_repository.dart';
import 'package:logistiscout/domain/repositories/recipe_repository.dart';
import 'package:logistiscout/domain/repositories/tente_repository.dart';
import 'package:logistiscout/core/di.dart';
import 'package:logistiscout/services/local_storage_service.dart';
import 'dart:developer' as developer;
class EvenementDetailController extends ChangeNotifier {
  final RecipeRepository recipeRepo;
  final TentRepository tenteRepo;
  final EventRepository eventRepo;

  Event? event;
  MealPlan? currentPlan;
  int dayOffset = 0;
  MealType selectedMeal = MealType.dejeuner;
  bool loading = false;
  String? error;
  List<Tent> allTentes = [];
  List<Tent> availableTentes = [];
  Set<int> selectedTenteIds = {};

  EvenementDetailController({
    required this.recipeRepo,
    required this.tenteRepo,
    required this.eventRepo,
  });

  Future<void> init(int eventId) async {
    loading = true;
    error = null;
    developer.log('[EvenementDetailController] 🟡 init() starting (eventId=$eventId)');
    notifyListeners();

    try {
      event = await eventRepo.getEvent(eventId);
      developer.log('[EvenementDetailController] ✅ Event loaded: ${event?.nom}');
      await loadTentes();
      allTentes = await tenteRepo.getTentList();
      developer.log('[EvenementDetailController] ✅ Loaded ${allTentes.length} tentes');
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

  Future<void> loadTentes() async {
    if (event == null) return;
    try {
      loading = true;
      notifyListeners();

      allTentes = await tenteRepo.getTentList();
      availableTentes = await tenteRepo.getAvailableTent(event!.date, event!.dateFin);
      developer.log('[EvenementDetailController] ✅ Loaded ${availableTentes.length} available tents');
    } catch (e, st) {
      developer.log('[EvenementDetailController] ❌ loadTentes failed', error: e, stackTrace: st);
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void toggleTenteSelection(int id) {
    if (selectedTenteIds.contains(id)) {
      selectedTenteIds.remove(id);
    } else {
      selectedTenteIds.add(id);
    }
    notifyListeners();
  }

  Future<void> applyTenteChanges() async {
    if (event == null) return;

    try {
      final updatedIds = Set<int>.from(event!.associatedTents);
      for (final id in selectedTenteIds) {
        updatedIds.contains(id) ? updatedIds.remove(id) : updatedIds.add(id);
      }

      final updatedEvent = event!.copyWith(associatedTents: updatedIds.toList());
      event = updatedEvent;
      selectedTenteIds.clear();
      notifyListeners();

      final groupId = await LocalStorageService.instance.getGroupId();
      if (groupId == null) throw Exception("Group ID not found");

      await eventRepo.updateEventTents(
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

  Future<void> _loadPlan(int eventId) async {

    developer.log('[EvenementDetailController] 🔵 _loadPlan() start (eventId=$eventId, '
        'date=$this.dayOffset, meal=$selectedMeal, offset=$dayOffset), dayOffset=$dayOffset');

    try {
      final start = DateTime.now();
      currentPlan = await eventRepo.getMealPlan(eventId,dayOffset, selectedMeal);
      final duration = DateTime.now().difference(start).inMilliseconds;

      developer.log('[EvenementDetailController] ✅ _loadPlan() success '
          '(${currentPlan?.items.length ?? 0} items, ${duration}ms)');
    } catch (e, st) {
      error = e.toString();
      developer.log('[EvenementDetailController] ❌ _loadPlan() failed', error: e, stackTrace: st);
    }
    notifyListeners();
  }

  Future<void> changeOffset(int newOffest) async {
    developer.log('[EvenementDetailController] 🔄 changeDate() → $newOffest');
    dayOffset = newOffest;
    await _loadPlan(event!.id);
  }

  Future<void> changeMeal(MealType meal) async {
    developer.log('[EvenementDetailController] 🔄 changeMeal() → $meal');
    selectedMeal = meal;
    await _loadPlan(event!.id);
  }

  Future<void> setPortions(int portions) async {
    if (currentPlan == null || event == null) return;

    developer.log('[EvenementDetailController] ⚙️ setPortions() → $portions');
    currentPlan = currentPlan!.copyWith(portions: portions);
    notifyListeners();

    try {
      for (final item in currentPlan!.items) {

        await eventRepo.updateEventMenu(
          item.eventId,
          event!.id,
          item.recipeId,
          currentPlan!.dayNumber,
          currentPlan!.mealType,
          portions,
        );
      }

      developer.log('[EvenementDetailController] ✅ Portions updated backend');
    } catch (e, st) {
      developer.log('[EvenementDetailController] ❌ setPortions failed', error: e, stackTrace: st);
    }
  }

  Future<void> createRecipes(List<Recipe> recipes) async {
    if (recipes.isEmpty) return;
    developer.log('[EvenementDetailController] ➕ createRecipes(${recipes.length})');

    final recipeRepo = this.recipeRepo;
    int successCount = 0;

    for (final recipe in recipes) {
      try {
        await recipeRepo.createRecipe(recipe);
        successCount++;
        developer.log('✅ Recette "${recipe.title}" créée sur le backend');
      } catch (e, st) {
        developer.log(
          '[EvenementDetailController] ❌ Échec création recette "${recipe.title}"',
          error: e,
          stackTrace: st,
        );
        // On continue pour les autres recettes
      }
    }

    developer.log('[EvenementDetailController] ✅ $successCount/${recipes.length} recettes créées avec succès');
  }

  Future<void> addMenuItemToMealPlan(MenuItem item) async {
    if (event == null) return;

    developer.log('[EvenementDetailController] 🍽️ addRecipeToMealPlan($item)');

    try {

      await eventRepo.addEventMenu(
        eventId: event!.id,
        menuId: item.recipeId,
        dayNumber: dayOffset,
        meal: selectedMeal,
        portions: currentPlan?.portions ?? 1,
      );

      developer.log('[EvenementDetailController] ✅ Recipe linked to meal plan');

      await _loadPlan(event!.id);
    } catch (e, st) {
      developer.log('[EvenementDetailController] ❌ addRecipeToMealPlan failed',
          error: e, stackTrace: st);
    }
  }


  Future<void> removeRecipeAt(int index) async {
    if (currentPlan == null) return;
    developer.log('[EvenementDetailController] 🗑️ removeRecipeAt(index=$index)');

    try {

      // 🧹 Mise à jour locale
      final updated = List<MenuItem>.of(currentPlan!.items)..removeAt(index);
      currentPlan = currentPlan!.copyWith(items: updated);
      notifyListeners();
    } catch (e, st) {
      developer.log('[EvenementDetailController] ❌ removeRecipeAt failed', error: e, stackTrace: st);
      error = e.toString();
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
      await eventRepo.saveMealPlan(event!.id.toString(), currentPlan!);
      developer.log('[EvenementDetailController] ✅ moveRecipe saved');
    } catch (e, st) {
      developer.log('[EvenementDetailController] ❌ moveRecipe failed', error: e, stackTrace: st);
    }
  }

  Future<void> duplicateTo(List<MapEntry<DateTime, MealType>> targets) async {
    if (currentPlan == null) return;
    developer.log('[EvenementDetailController] 📄 duplicateTo() → ${targets.length} targets');
    try {
      final start = DateTime.now();
      await eventRepo.duplicateMealPlans(event!.id.toString(), currentPlan!, targets);
      final duration = DateTime.now().difference(start).inMilliseconds;
      developer.log('[EvenementDetailController] ✅ duplicateMenuUC done (${duration}ms)');
    } catch (e, st) {
      developer.log('[EvenementDetailController] ❌ duplicateMenuUC failed', error: e, stackTrace: st);
    }
  }

  Future<List<IngredientTotal>> computeTotalIngredientsForEvent() async {
      return [];
    }
}

final evenementDetailProvider =
ChangeNotifierProvider.family<EvenementDetailController, int>((ref, eventId) {
  final recipeRepo = ref.read(recipeRepositoryProvider);
  final tenteRepo = ref.read(tentRepositoryProvider);
  final eventRepo = ref.read(eventRepositoryProvider);

  final ctrl = EvenementDetailController(
    recipeRepo: recipeRepo,
    tenteRepo: tenteRepo,
    eventRepo: eventRepo,
  );

  ctrl.init(eventId);
  return ctrl;
});
