import '../entities/event.dart';
import '../repositories/event_repository.dart';

class GetEvent {
  final EventRepository repo;
  GetEvent(this.repo);

  Future<Event> call(int id) => repo.getEvent(id);
}
