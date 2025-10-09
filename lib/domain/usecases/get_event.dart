import '../entities/event.dart';
import '../repositories/event_repository.dart';

class GetEvent {
  final EventRepository repo;
  GetEvent(this.repo);

  Future<Event> call(String id) => repo.getEvent(id);
}
