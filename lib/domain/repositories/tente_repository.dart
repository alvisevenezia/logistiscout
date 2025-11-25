import 'package:logistiscout/domain/entities/tente.dart';

abstract class TentRepository {
  Future<List<Tent>> getTentList();
  Future<void> createTent(String groupId, Tent tent);
  Future<void> updateTent(String groupId, Tent tent);
  Future<void> deleteTent(int id, String groupId);
  Future<List<Tent>> getAvailableTent(DateTime start, DateTime end);
}
