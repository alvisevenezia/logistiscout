import 'package:logistiscout/domain/entities/tente.dart';

abstract class TenteRepository {
  Future<Tente> getTente(int id);
  Future<List<Tente>> getAllTentes();
  Future<Tente> createTente(Map<String, dynamic> json);
  Future<void> deleteTente(int id);
}