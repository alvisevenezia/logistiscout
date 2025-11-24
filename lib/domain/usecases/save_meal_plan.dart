import '../entities/menu.dart';
import '../repositories/event_repository.dart';

class SaveMealPlan {
  final EventRepository repo;
  SaveMealPlan(this.repo);

  Future<void> call(String eventId, MealPlan plan) {
    return repo.saveMealPlan(eventId, plan);
  }
}
