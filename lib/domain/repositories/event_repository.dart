import '../entities/event.dart';
import '../entities/menu.dart';

abstract class EventRepository {
  updateEventTents(int eventId, List<int> tentIds, Event event);
  Future<void> createEvent(Event event);
  Future<Event> getEvent(int id);
  Future<List<Event>> getAllEvents();
  Future<MealPlan> getMealPlan(int eventId, int dayNumber, MealType meal);
  Future<void> addEventMenu({
    required int eventId,
    required int menuId,
    required int dayNumber,
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
    int dayNumber,
    MealType meal, int quantity
  );
  Future<void> duplicateMealPlans(
      String eventId,
      MealPlan source,
      List<MapEntry<DateTime, MealType>> targets,
      );
  Future<void> deleteEvent(int id);
}
