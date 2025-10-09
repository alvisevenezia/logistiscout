import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:logistiscout/services/local_storage_service.dart';

class ApiService {

  ApiService._internal({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client() {
    developer.log('ApiService singleton created', name: 'ApiService');
  }

  static ApiService? _instance;

  Future<Map<String, String>> _headers() async {
    final token = await LocalStorageService.instance.getToken();

    final headers = {
      'Content-Type': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }


  /// Get the singleton (creates on first call).
  factory ApiService({String baseUrl = 'http://57.128.224.111:8000', http.Client? client}) {
    developer.log('ApiService instance requested', name: 'ApiService');
    return _instance ??= ApiService._internal(baseUrl: baseUrl, client: client);
  }

  /// For tests or environment switches (optional).
  static void reconfigure({required String baseUrl, http.Client? client}) {
    _instance = ApiService._internal(baseUrl: baseUrl, client: client);
  }

  final String baseUrl;
  final http.Client _client;
  // Authentification groupe
  Future<Map<String, dynamic>?> loginGroupe(String userlogin, String mdp) async {
    developer.log('POST /auth/login {userlogin: $userlogin, mdp: ***}', name: 'ApiService');
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userlogin': userlogin, 'mdp': mdp}),
    );
    developer.log('Response: ${response.statusCode} - ${response.body}', name: 'ApiService');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  Future<void> registerGroupe(Map<String, dynamic> groupeData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/create_group'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(groupeData),
    );

    if (response.statusCode != 201) {
      throw Exception('Erreur création groupe : ${response.body}');
    }
  }

  // Groupes
  Future<List<dynamic>> getGroupes() async {
    developer.log('GET /groupes', name: 'ApiService');
    final response = await http.get(Uri.parse('$baseUrl/groupes'));
    developer.log('Response: ${response.statusCode} - ${response.body}', name: 'ApiService');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Erreur chargement groupes');
  }
  Future<Map<String, dynamic>> getGroupe(String groupeId) async {
    developer.log('GET /groupes/$groupeId', name: 'ApiService');
    final response = await http.get(Uri.parse('$baseUrl/groupes/$groupeId'));
    developer.log('Response: ${response.statusCode} - ${response.body}', name: 'ApiService');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Erreur chargement groupe');
  }

  // Tentes
  Future<List<dynamic>> getTentes(String groupeId) async {
    final url = '$baseUrl/tentes?groupeId=$groupeId';
    developer.log('GET $url', name: 'ApiService');
    if (groupeId.isEmpty) {
      developer.log('groupeId est null ou vide !', name: 'ApiService', error: 'groupeId manquant');
      throw Exception('groupeId manquant');
    }
    final response = await http.get(Uri.parse(url));
    developer.log('Response: ${response.statusCode} - ${response.body}', name: 'ApiService');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Erreur chargement tentes');
  }
  Future<Map<String, dynamic>> getTente(int tenteId, {String? groupeId}) async {
    final url = groupeId != null && groupeId.isNotEmpty
        ? '$baseUrl/tentes/$tenteId?groupeId=$groupeId'
        : '$baseUrl/tentes/$tenteId';
    developer.log('GET $url', name: 'ApiService');
    final response = await http.get(Uri.parse(url));
    developer.log('Response: ${response.statusCode} - ${response.body}', name: 'ApiService');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Erreur chargement tente');
  }
  Future<void> createTente(Map<String, dynamic> tente) async {
    // S'assurer que le champ groupeId est bien présent
    if (!tente.containsKey('groupeId') || tente['groupeId'] == null || tente['groupeId'].toString().isEmpty) {
      throw Exception('groupeId manquant lors de l\'ajout de tente');
    }
    developer.log('POST /tentes {tente: $tente}', name: 'ApiService');
    final response = await http.post(
      Uri.parse('$baseUrl/tentes'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(tente),
    );
    developer.log('Response: ${response.statusCode} - ${response.body}', name: 'ApiService');
    if (response.statusCode != 201) {
      throw Exception('Erreur ajout tente');
    }
  }
  Future<void> updateTente(int tenteId, Map<String, dynamic> tente) async {
    // S'assurer que le champ groupeId est bien présent
    if (!tente.containsKey('groupeId') || tente['groupeId'] == null || tente['groupeId'].toString().isEmpty) {
      throw Exception('groupeId manquant lors de la modification de tente');
    }
    final groupeId = tente['groupeId'];
    final url = '$baseUrl/tentes/$tenteId?groupeId=$groupeId';
    developer.log('PUT $url {tente: $tente}', name: 'ApiService');
    final response = await http.put(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(tente),
    );
    developer.log('Response: ${response.statusCode} - ${response.body}', name: 'ApiService');
    if (response.statusCode != 200) {
      throw Exception('Erreur modification tente: ${response.body}');
    }
  }
  Future<void> deleteTente(int tenteId, {required String groupeId}) async {
    final url = '$baseUrl/tentes/$tenteId?groupeId=$groupeId';
    developer.log('DELETE $url', name: 'ApiService');
    final response = await http.delete(Uri.parse(url));
    developer.log('Response: ${response.statusCode} - ${response.body}', name: 'ApiService');
    if (response.statusCode != 204) {
      throw Exception('Erreur suppression tente');
    }
  }

  // Événements
  Future<List<dynamic>> getEvenements(String groupeId) async {
    developer.log('GET /evenements?groupeId=$groupeId', name: 'ApiService');
    final response = await http.get(Uri.parse('$baseUrl/evenements?groupeId=$groupeId'));
    developer.log('Response: ${response.statusCode} - ${response.body}', name: 'ApiService');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Erreur chargement événements');
  }
  Future<Map<String, dynamic>> getEvenement(int evenementId, {String? groupeId}) async {
    final url = groupeId != null && groupeId.isNotEmpty
        ? '$baseUrl/evenements/$evenementId?groupeId=$groupeId'
        : '$baseUrl/evenements/$evenementId';
    developer.log('GET $url', name: 'ApiService');
    final response = await http.get(Uri.parse(url));
    developer.log('Response: ${response.statusCode} - ${response.body}', name: 'ApiService');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Erreur chargement événement');
  }
  Future<void> addEvenement(Map<String, dynamic> evt) async {
    if (!evt.containsKey('groupeId') || evt['groupeId'] == null || evt['groupeId'].toString().isEmpty) {
      throw Exception('groupeId manquant lors de la modification d\'événement');
    }
    final groupeId = evt['groupeId'];
    developer.log('POST /evenements {evt: $evt}', name: 'ApiService');
    final response = await http.post(
      Uri.parse('$baseUrl/evenements?groupeId=$groupeId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(evt),
    );
    developer.log('Response: ${response.statusCode} - ${response.body}', name: 'ApiService');
    if (response.statusCode != 201) {
      throw Exception('Erreur ajout événement');
    }
  }
  Future<void> updateEvenement(int evenementId, Map<String, dynamic> evt) async {
    if (!evt.containsKey('groupeId') || evt['groupeId'] == null || evt['groupeId'].toString().isEmpty) {
      throw Exception('groupeId manquant lors de la modification d\'événement');
    }
    final groupeId = evt['groupeId'];
    final url = '$baseUrl/evenements/$evenementId?groupeId=$groupeId';
    developer.log('PUT $url {evt: $evt}', name: 'ApiService');
    final response = await http.put(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(evt),
    );
    developer.log('Response: ${response.statusCode} - ${response.body}', name: 'ApiService');
    if (response.statusCode != 200) {
      throw Exception('Erreur modification événement: ${response.body}');
    }
  }
  Future<void> deleteEvenement(int evenementId, {required String groupeId}) async {
    final url = '$baseUrl/evenements/$evenementId?groupeId=$groupeId';
    developer.log('DELETE $url', name: 'ApiService');
    final response = await http.delete(Uri.parse(url));
    developer.log('Response: ${response.statusCode} - ${response.body}', name: 'ApiService');
    if (response.statusCode != 204) {
      throw Exception('Erreur suppression événement');
    }
  }

  // Récupère les événements sur une période donnée
  Future<List<dynamic>> getEvenementsParPeriode(String groupeId, DateTime debut, DateTime fin) async {
    final url = '$baseUrl/evenements?groupeId=$groupeId&debut=${debut.toIso8601String()}&fin=${fin.toIso8601String()}';
    developer.log('GET $url', name: 'ApiService');
    final response = await http.get(Uri.parse(url));
    developer.log('Response: ${response.statusCode} - ${response.body}', name: 'ApiService');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Erreur chargement événements par période');
  }

  // Réservations
  Future<List<dynamic>> getReservations({int? tenteId, int? evenementId}) async {
    String url = '$baseUrl/reservations?';
    if (tenteId != null) url += 'tenteId=$tenteId&';
    if (evenementId != null) url += 'evenementId=$evenementId&';
    developer.log('GET $url', name: 'ApiService');
    final response = await http.get(Uri.parse(url));
    developer.log('Response: ${response.statusCode} - ${response.body}', name: 'ApiService');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Erreur chargement réservations');
  }
  Future<void> addReservation(Map<String, dynamic> reservation) async {
    developer.log('POST /reservations {reservation: $reservation}', name: 'ApiService');
    final response = await http.post(
      Uri.parse('$baseUrl/reservations'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(reservation),
    );
    developer.log('Response: ${response.statusCode} - ${response.body}', name: 'ApiService');
    if (response.statusCode != 201) {
      throw Exception('Erreur ajout réservation');
    }
  }

  // Contrôles
  Future<List<dynamic>> getControles(int tenteId) async {
    developer.log('GET /controles?tenteId=$tenteId', name: 'ApiService');
    final response = await http.get(Uri.parse('$baseUrl/controles?tenteId=$tenteId'));
    developer.log('Response: ${response.statusCode} - ${response.body}', name: 'ApiService');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Erreur chargement contrôles');
  }
  Future<void> addControle(Map<String, dynamic> controle) async {
    final url = Uri.parse('$baseUrl/controles');
    developer.log('POST $url {controle: $controle}', name: 'ApiService');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(controle), // On envoie un map sans id
    );
    developer.log('Response: ${response.statusCode} - ${response.body}', name: 'ApiService');
    if (response.statusCode == 201) {
      return;
    } else {
      throw Exception('Erreur ajout contrôle');
    }
  }

  Future<void> updateControle(int controleId, Map<String, dynamic> controle) async {
    developer.log('PUT /controles/$controleId {controle: $controle}', name: 'ApiService');
    final response = await http.put(
      Uri.parse('$baseUrl/controles/$controleId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(controle),
    );
    developer.log('Response: ${response.statusCode} - ${response.body}', name: 'ApiService');
    if (response.statusCode != 200) {
      throw Exception('Erreur modification contrôle');
    }
  }
  Future<void> deleteControle(int controleId) async {
    developer.log('DELETE /controles/$controleId', name: 'ApiService');
    final response = await http.delete(Uri.parse('$baseUrl/controles/$controleId'));
    developer.log('Response: ${response.statusCode} - ${response.body}', name: 'ApiService');
    if (response.statusCode != 204) {
      throw Exception('Erreur suppression contrôle');
    }
  }
// ==========================================================
// 🍽️ MENUS (Recettes)
// ==========================================================

  Future<List<dynamic>> getMenus() async {
    final response = await _client.get(Uri.parse('$baseUrl/menus'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('Erreur ${response.statusCode} en récupérant les menus');
    }
  }

  Future<Map<String, dynamic>> getMenu(int id) async {
    final response = await _client.get(Uri.parse('$baseUrl/menus/$id'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Erreur ${response.statusCode} en récupérant le menu $id');
    }
  }

  Future<void> addMenu(Map<String, dynamic> menuJson) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/menus'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(menuJson),
    );
    if (response.statusCode != 201) {
      throw Exception('Erreur ${response.statusCode} lors de la création du menu');
    }
  }

  Future<void> updateMenu(int id, Map<String, dynamic> menuJson) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/menus/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(menuJson),
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur ${response.statusCode} lors de la mise à jour du menu');
    }
  }

  Future<void> deleteMenu(int id) async {
    final response = await _client.delete(Uri.parse('$baseUrl/menus/$id'));
    if (response.statusCode != 204) {
      throw Exception('Erreur ${response.statusCode} lors de la suppression du menu');
    }
  }

// ==========================================================
// 📅 EVENT MENUS (Planification de repas)
// ==========================================================

  Future<List<dynamic>> getEventMenus(int eventId) async {
    final url = Uri.parse('$baseUrl/event_menus?event_id=$eventId');
    developer.log('[ApiService] 🔵 GET $url');

    try {
      final response = await http.get(url, headers: await _headers());
      developer.log('[ApiService] Response ${response.statusCode}: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      } else {
        throw Exception('Erreur ${response.statusCode} en récupérant les menus de l’événement $eventId');
      }
    } catch (e, st) {
      developer.log('[ApiService] ❌ getEventMenus() failed', error: e, stackTrace: st);
      rethrow;
    }
  }


  Future<void> addEventMenu(Map<String, dynamic> eventMenuJson) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/event_menus'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(eventMenuJson),
    );
    if (response.statusCode != 201) {
      throw Exception('Erreur ${response.statusCode} lors de la création du menu planifié');
    }
  }

  Future<void> updateEventMenu(int id, Map<String, dynamic> eventMenuJson) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/event_menus/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(eventMenuJson),
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur ${response.statusCode} lors de la mise à jour du menu planifié');
    }
  }

  Future<void> deleteEventMenu(int eventMenuId) async {
    final url = '$baseUrl/event_menus/$eventMenuId';
    final response = await http.delete(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 204) {
      throw Exception('Erreur suppression event_menu: ${response.body}');
    }

    developer.log('[ApiService] 🗑️ EventMenu supprimé (id=$eventMenuId)');
  }
  Future<void> createMenu(Map<String, dynamic> menu) async {
    final url = '$baseUrl/menus';
    developer.log('POST $url {menu: $menu}', name: 'ApiService');

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(menu),
    );

    developer.log(
      'Response: ${response.statusCode} - ${response.body}',
      name: 'ApiService',
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Erreur lors de la création du menu: ${response.body}');
    }
  }
}
