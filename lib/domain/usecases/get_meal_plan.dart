import '../entities/menu.dart';
import '../repositories/event_repository.dart';

class GetMealPlan {
  final EventRepository repo;
  GetMealPlan(this.repo);

  Future<MealPlan> call(String eventId, DateTime date, MealType meal) {
    return repo.getMealPlan(eventId, date, meal);
  }
}
