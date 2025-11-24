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


  factory ApiService({String baseUrl = 'http://57.128.224.111:8000', http.Client? client}) {
    developer.log('ApiService instance requested', name: 'ApiService');
    return _instance ??= ApiService._internal(baseUrl: baseUrl, client: client);
  }

  static void reconfigure({required String baseUrl, http.Client? client}) {
    _instance = ApiService._internal(baseUrl: baseUrl, client: client);
  }

  final String baseUrl;
  final http.Client _client;
  Future<Map<String, dynamic>?> loginGroup(String userLogin, String mdp) async {
    developer.log('POST /auth/login {userlogin: $userLogin, mdp: ***}', name: 'ApiService');
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userlogin': userLogin, 'mdp': mdp}),
    );
    developer.log('Response: ${response.statusCode} - ${response.body}', name: 'ApiService');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  Future<void> registerGroup(Map<String, dynamic> groupData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/create_group'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(groupData),
    );

    if (response.statusCode != 201) {
      throw Exception('Erreur création groupe : ${response.body}');
    }
  }

  Future<List<dynamic>> getGroupList() async {
    developer.log('GET /groupes', name: 'ApiService');
    final response = await http.get(Uri.parse('$baseUrl/groupes'));
    developer.log('Response: ${response.statusCode} - ${response.body}', name: 'ApiService');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Erreur chargement groupes');
  }
  Future<Map<String, dynamic>> getGroup(String groupId) async {
    developer.log('GET /groupes/$groupId', name: 'ApiService');
    final response = await http.get(Uri.parse('$baseUrl/groupes/$groupId'));
    developer.log('Response: ${response.statusCode} - ${response.body}', name: 'ApiService');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Erreur chargement groupe');
  }

  Future<List<dynamic>> getTentList(String groupId) async {
    final url = '$baseUrl/tentes?groupeId=$groupId';
    developer.log('GET $url', name: 'ApiService');
    if (groupId.isEmpty) {
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
  Future<Map<String, dynamic>> getTent(int tentId, {String? groupId}) async {
    final url = groupId != null && groupId.isNotEmpty
        ? '$baseUrl/tentes/$tentId?groupeId=$groupId'
        : '$baseUrl/tentes/$tentId';
    developer.log('GET $url', name: 'ApiService');
    final response = await http.get(Uri.parse(url));
    developer.log('Response: ${response.statusCode} - ${response.body}', name: 'ApiService');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Erreur chargement tente');
  }
  Future<void> createTent(Map<String, dynamic> tent) async {
    if (!tent.containsKey('groupeId') || tent['groupeId'] == null || tent['groupeId'].toString().isEmpty) {
      throw Exception('groupeId manquant lors de l\'ajout de tente');
    }
    developer.log('POST /tentes {tente: $tent}', name: 'ApiService');
    final response = await http.post(
      Uri.parse('$baseUrl/tentes'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(tent),
    );
    developer.log('Response: ${response.statusCode} - ${response.body}', name: 'ApiService');
    if (response.statusCode != 201) {
      throw Exception('Erreur ajout tente');
    }
  }
  Future<void> updateTent(int tentId, Map<String, dynamic> tent) async {
    if (!tent.containsKey('groupeId') || tent['groupeId'] == null || tent['groupeId'].toString().isEmpty) {
      throw Exception('groupeId manquant lors de la modification de tente');
    }
    final groupeId = tent['groupeId'];
    final url = '$baseUrl/tentes/$tentId?groupeId=$groupeId';
    developer.log('PUT $url {tente: $tent}', name: 'ApiService');
    final response = await http.put(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(tent),
    );
    developer.log('Response: ${response.statusCode} - ${response.body}', name: 'ApiService');
    if (response.statusCode != 200) {
      throw Exception('Erreur modification tente: ${response.body}');
    }
  }
  Future<void> deleteTent(int tentId, {required String groupId}) async {
    final url = '$baseUrl/tentes/$tentId?groupeId=$groupId';
    developer.log('DELETE $url', name: 'ApiService');
    final response = await http.delete(Uri.parse(url));
    developer.log('Response: ${response.statusCode} - ${response.body}', name: 'ApiService');
    if (response.statusCode != 204) {
      throw Exception('Erreur suppression tente');
    }
  }

  Future<List<dynamic>> getEventList(String groupId) async {
    developer.log('GET /evenements?groupeId=$groupId', name: 'ApiService');
    final response = await http.get(Uri.parse('$baseUrl/evenements?groupeId=$groupId'));
    developer.log('Response: ${response.statusCode} - ${response.body}', name: 'ApiService');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Erreur chargement événements');
  }
  Future<Map<String, dynamic>> getEvent(int eventId, {String? groupId}) async {
    final url = groupId != null && groupId.isNotEmpty
        ? '$baseUrl/evenements/$eventId?groupeId=$groupId'
        : '$baseUrl/evenements/$eventId';
    developer.log('GET $url', name: 'ApiService');
    final response = await http.get(Uri.parse(url));
    developer.log('Response: ${response.statusCode} - ${response.body}', name: 'ApiService');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Erreur chargement événement');
  }
  Future<void> addEvent(Map<String, dynamic> evt) async {
    if (!evt.containsKey('groupeId') || evt['groupeId'] == null || evt['groupeId'].toString().isEmpty) {
      throw Exception('groupeId manquant lors de la modification d\'événement');
    }
    final groupId = evt['groupeId'];
    developer.log('POST /evenements {evt: $evt}', name: 'ApiService');
    final response = await http.post(
      Uri.parse('$baseUrl/evenements?groupeId=$groupId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(evt),
    );
    developer.log('Response: ${response.statusCode} - ${response.body}', name: 'ApiService');
    if (response.statusCode != 201) {
      throw Exception('Erreur ajout événement');
    }
  }
  Future<void> updateEvent(int eventId, Map<String, dynamic> evt) async {

    if (!evt.containsKey('groupeId') || evt['groupeId'] == null || evt['groupeId'].toString().isEmpty) {
      throw Exception('groupeId manquant lors de la modification d\'événement');
    }
    final groupId = evt['groupeId'];
    final url = '$baseUrl/evenements/$eventId?groupeId=$groupId';
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
  Future<void> deleteEvent(int eventId, {required String groupId}) async {
    final url = '$baseUrl/evenements/$eventId?groupeId=$groupId';
    developer.log('DELETE $url', name: 'ApiService');
    final response = await http.delete(Uri.parse(url));
    developer.log('Response: ${response.statusCode} - ${response.body}', name: 'ApiService');
    if (response.statusCode != 204) {
      throw Exception('Erreur suppression événement');
    }
  }

  Future<List<dynamic>> getEventListByPeriod(String groupId, DateTime start, DateTime end) async {
    final url = '$baseUrl/evenements?groupeId=$groupId&debut=${start.toIso8601String()}&fin=${end.toIso8601String()}';
    developer.log('GET $url', name: 'ApiService');
    final response = await http.get(Uri.parse(url));
    developer.log('Response: ${response.statusCode} - ${response.body}', name: 'ApiService');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Erreur chargement événements par période');
  }

  Future<List<dynamic>> getReservationList({int? tentId, int? eventId}) async {
    String url = '$baseUrl/reservations?';
    if (tentId != null) url += 'tenteId=$tentId&';
    if (eventId != null) url += 'evenementId=$eventId&';
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

  Future<List<dynamic>> getControlList(int tentId) async {
    developer.log('GET /controles?tenteId=$tentId', name: 'ApiService');
    final response = await http.get(Uri.parse('$baseUrl/controles?tenteId=$tentId'));
    developer.log('Response: ${response.statusCode} - ${response.body}', name: 'ApiService');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Erreur chargement contrôles');
  }
  Future<void> addControl(Map<String, dynamic> control) async {
    final url = Uri.parse('$baseUrl/controles');
    developer.log('POST $url {controle: $control}', name: 'ApiService');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(control), // On envoie un map sans id
    );
    developer.log('Response: ${response.statusCode} - ${response.body}', name: 'ApiService');
    if (response.statusCode == 201) {
      return;
    } else {
      throw Exception('Erreur ajout contrôle');
    }
  }

  Future<void> updateControl(int controlId, Map<String, dynamic> control) async {
    developer.log('PUT /controles/$controlId {controle: $control}', name: 'ApiService');
    final response = await http.put(
      Uri.parse('$baseUrl/controles/$controlId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(control),
    );
    developer.log('Response: ${response.statusCode} - ${response.body}', name: 'ApiService');
    if (response.statusCode != 200) {
      throw Exception('Erreur modification contrôle');
    }
  }
  Future<void> deleteControl(int controlId) async {
    developer.log('DELETE /controles/$controlId', name: 'ApiService');
    final response = await http.delete(Uri.parse('$baseUrl/controles/$controlId'));
    developer.log('Response: ${response.statusCode} - ${response.body}', name: 'ApiService');
    if (response.statusCode != 204) {
      throw Exception('Erreur suppression contrôle');
    }
  }

  Future<List<dynamic>> getMenuList() async {
    final response = await _client.get(Uri.parse('$baseUrl/menus'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('Erreur ${response.statusCode} en récupérant les menus');
    }
  }

  Future<Map<String, dynamic>> getMenu(int menuId) async {
    final response = await _client.get(Uri.parse('$baseUrl/menus/$menuId'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Erreur ${response.statusCode} en récupérant le menu $menuId');
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

  Future<void> updateMenu(int menuId, Map<String, dynamic> menuJson) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/menus/$menuId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(menuJson),
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur ${response.statusCode} lors de la mise à jour du menu');
    }
  }

  Future<void> deleteMenu(int menuId) async {
    final response = await _client.delete(Uri.parse('$baseUrl/menus/$menuId'));
    if (response.statusCode != 204) {
      throw Exception('Erreur ${response.statusCode} lors de la suppression du menu');
    }
  }

  Future<List<dynamic>> getEventMenuList(int eventId) async {
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


  Future<void> addEventMenu(Map<String, dynamic> data) async {
    final url = '$baseUrl/event_menus';
    developer.log('🔵 POST $url body=$data', name: 'ApiService');

    final response = await http.post(
      Uri.parse(url),
      headers: await _headers(),
      body: jsonEncode(data),
    );

    developer.log('Response ${response.statusCode}: ${response.body}', name: 'ApiService');

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Erreur lors de la création du lien event_menu: ${response.body}');
    }
  }


  Future<void> updateEventMenu(int eventMenuId, Map<String, dynamic> payload) async {
    final url = '$baseUrl/event_menus/$eventMenuId';
    developer.log('[ApiService] 📝 PUT $url - payload=$payload');

    final response = await http.put(
      Uri.parse(url),
      headers: await _headers(),
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Erreur lors de la mise à jour du event_menu: ${response.body}');
    }

    developer.log('[ApiService] ✅ Event menu mis à jour ($eventMenuId)');
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
