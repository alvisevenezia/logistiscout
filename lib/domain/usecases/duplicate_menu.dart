import '../entities/menu.dart';
import '../repositories/event_repository.dart';

class DuplicateMenu {
  final EventRepository repo;
  DuplicateMenu(this.repo);

  Future<void> call(
      String eventId,
      MealPlan source,
      List<MapEntry<DateTime, MealType>> targets,
      ) {
    return repo.duplicateMealPlans(eventId, source, targets);
  }
}
