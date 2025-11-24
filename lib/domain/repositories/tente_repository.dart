import 'package:logistiscout/domain/entities/tente.dart';

abstract class TentRepository {
  Future<Tent> getTent(int id);
  Future<List<Tent>> getAllTent();
  Future<void> createTent(String groupId, Tent tent);
  Future<void> updateTent(String groupId, Tent tent);
  Future<void> deleteTent(int id, String groupId);
  Future<List<Tent>> getAvailableTent(DateTime start, DateTime end);
}
