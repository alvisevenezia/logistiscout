import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logistiscout/data/repositories/group_repository.dart';
import 'package:logistiscout/data/repositories/tente_repository_impl.dart';
import 'package:logistiscout/domain/entities/group.dart';
import 'package:logistiscout/domain/repositories/tente_repository.dart';
import 'package:logistiscout/services/api_service.dart';
import 'package:logistiscout/data/repositories/event_repository_impl.dart';
import 'package:logistiscout/data/repositories/recipe_repository_impl.dart';
import 'package:logistiscout/domain/repositories/event_repository.dart';
import 'package:logistiscout/domain/repositories/recipe_repository.dart';
import 'package:logistiscout/ui/controllers/group_settings_controller.dart';

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

final tentRepositoryProvider = Provider<TentRepository>((ref) {
  final api = ref.read(apiServiceProvider);
  return TentRepositoryImpl(api);
});

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  final api = ref.read(apiServiceProvider);
  return GroupRepository(api: api);
});

final accountControllerProvider = AsyncNotifierProvider<GroupSettingsController, Group>(
  () => GroupSettingsController(),
);