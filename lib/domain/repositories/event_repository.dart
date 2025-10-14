import '../entities/event.dart';
import '../entities/menu.dart';

abstract class EventRepository {
  updateEventTents(String groupId, int eventId, List<int> tentIds, Event event);
  Future<Event> getEvent(String id);
  Future<List<Event>> getAllEvents();
  Future<MealPlan> getMealPlan(String eventId, DateTime date, MealType meal);
  Future<void> addEventMenu({
    required int eventId,
    required int menuId,
    required DateTime date,
    required MealType meal,
    required int portions,
  });
  Future<void> saveMealPlan(String eventId, MealPlan plan);
  Future<void> deleteEventMenu(int eventMenuId);
  Future<void> updateEvent(Event event);
  Future<void> updateEventMenu(
    int eventMenuId,
    int eventId,
    int menuId,
    DateTime date,
    MealType meal, int quantite
  );
  Future<void> duplicateMealPlans(
      String eventId,
      MealPlan source,
      List<MapEntry<DateTime, MealType>> targets,
      );
}
