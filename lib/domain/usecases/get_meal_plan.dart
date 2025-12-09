import '../entities/menu.dart';
import '../repositories/event_repository.dart';

class GetMealPlan {
  final EventRepository repo;
  GetMealPlan(this.repo);

  Future<MealPlan> call(int eventId, int dayNumber, MealType meal) {
    return repo.getMealPlan(eventId, dayNumber, meal);
  }
}
