import '../entities/event.dart';
import '../entities/menu.dart';

abstract class EventRepository {
  updateEventTentes(String groupId, int eventId, List<int> tenteIds, Event event);
  Future<Event> getEvent(String id);
  Future<List<Event>> getAllEvents();
  Future<MealPlan> getMealPlan(String eventId, DateTime date, MealType meal);
  Future<void> saveMealPlan(String eventId, MealPlan plan);
  Future<void> deleteEventMenu(int eventMenuId);
  Future<void> duplicateMealPlans(
      String eventId,
      MealPlan source,
      List<MapEntry<DateTime, MealType>> targets,
      );
}
