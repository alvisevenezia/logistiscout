import 'package:logistiscout/domain/entities/tente.dart';

abstract class TenteRepository {
  Future<Tente> getTente(int id);
  Future<List<Tente>> getAllTentes();
  Future<void> createTente(String groupId, Tente tente);
  Future<void> updateTente(String groupId, Tente tente);
  Future<void> deleteTente(int id, String groupId);
  Future<List<Tente>> getAvailableTentes(DateTime debut, DateTime fin);
}
