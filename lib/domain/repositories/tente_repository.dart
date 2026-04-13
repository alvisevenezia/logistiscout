import 'package:logistiscout/domain/entities/tente.dart';

abstract class TentRepository {
  Future<List<Tent>> getTentList();
  Future<void> createTent(Tent tent);
  Future<void> updateTent(Tent tent);
  Future<void> deleteTent(int id);
  Future<List<Tent>> getAvailableTent(DateTime start, DateTime end);
}
