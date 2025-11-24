import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logistiscout/data/repositories/tente_repository_impl.dart';
import 'package:logistiscout/domain/repositories/tente_repository.dart';
import 'package:logistiscout/services/api_service.dart';
import 'package:logistiscout/data/repositories/event_repository_impl.dart';
import 'package:logistiscout/data/repositories/recipe_repository_impl.dart';
import 'package:logistiscout/domain/repositories/event_repository.dart';
import 'package:logistiscout/domain/repositories/recipe_repository.dart';
import 'package:logistiscout/domain/usecases/get_event.dart';
import 'package:logistiscout/domain/usecases/get_meal_plan.dart';
import 'package:logistiscout/domain/usecases/save_meal_plan.dart';
import 'package:logistiscout/domain/usecases/duplicate_menu.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  final api = ref.read(apiServiceProvider);
  return EventRepositoryImpl(api);
});

final recipeRepositoryProvider = Provider<RecipeRepository>((ref) {
  final api = ref.read(apiServiceProvider);
  return RecipeRepositoryImpl(api);
});

final getEventUseCaseProvider = Provider<GetEvent>((ref) {
  final repo = ref.read(eventRepositoryProvider);
  return GetEvent(repo);
});

final getMealPlanUseCaseProvider = Provider<GetMealPlan>((ref) {
  final repo = ref.read(eventRepositoryProvider);
  return GetMealPlan(repo);
});

final saveMealPlanUseCaseProvider = Provider<SaveMealPlan>((ref) {
  final repo = ref.read(eventRepositoryProvider);
  return SaveMealPlan(repo);
});

final duplicateMenuUseCaseProvider = Provider<DuplicateMenu>((ref) {
  final repo = ref.read(eventRepositoryProvider);
  return DuplicateMenu(repo);
});

final tenteRepositoryProvider = Provider<TentRepository>((ref) {
  final api = ref.read(apiServiceProvider);
  return TenteRepositoryImpl(api);
});
