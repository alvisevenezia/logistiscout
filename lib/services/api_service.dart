import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:logistiscout/services/AppException.dart';
import 'package:logistiscout/services/local_storage_service.dart';

enum HttpMethod {
  get("GET"),
  post("POST"),
  put("PUT"),
  delete("DELETE");

  final String name;
  const HttpMethod(this.name);

}

class ApiService {

  ApiService._internal({required this.baseUrl})
       {
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


  factory ApiService({String baseUrl = 'http://57.128.224.111:8000'}) {
    developer.log('ApiService instance requested', name: 'ApiService');
    return _instance ??= ApiService._internal(baseUrl: baseUrl);
  }

  static void reconfigure({required String baseUrl, http.Client? client}) {
    _instance = ApiService._internal(baseUrl: baseUrl);
  }

  final String baseUrl;

  //Gestion des erreurs HTTP et des exceptions
  Future<http.Response> _safeRequest(
      HttpMethod method,
      String path, {
        Object? body,
      }) async {
    
    final headers = await _headers();
    final uri = Uri.parse('$baseUrl$path');
    
    try {
      developer.log(
        '${method.name} $path body: $body',
        name: 'ApiService',
      );

      late final http.Response response;

      // --- Sélection de la méthode HTTP ---
      switch (method) {
        case HttpMethod.get:
          response = await http
              .get(uri, headers: headers)
              .timeout(const Duration(seconds: 10));
          break;

        case HttpMethod.post:
          response = await http
              .post(uri, headers: headers, body: body)
              .timeout(const Duration(seconds: 10));
          break;

        case HttpMethod.put:
          response = await http
              .put(uri, headers: headers, body: body)
              .timeout(const Duration(seconds: 10));
          break;

        case HttpMethod.delete:
          response = await http
              .delete(uri, headers: headers, body: body)
              .timeout(const Duration(seconds: 10));
          break;
      }

      developer.log(
        'Response $path: ${response.statusCode} - ${response.body}',
        name: 'ApiService',
      );

      // --- Vérification success (2xx) ---
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response;
      }

      // --- Mapping des erreurs ---
      switch (response.statusCode) {
        case 400:
          throw AppException("Requête invalide (400).", statusCode: 400);
        case 401:
        case 403:
          throw AppException("Accès refusé.", statusCode: response.statusCode);
        case 404:
          throw AppException("Ressource non trouvée (404).", statusCode: 404);
        case 500:
        case 502:
        case 503:
        case 504:
          throw AppException("Erreur serveur (${response.statusCode}).",
              statusCode: response.statusCode);
        default:
          throw AppException("Erreur inattendue (${response.statusCode}).",
              statusCode: response.statusCode);
      }
    } on SocketException {
      throw AppException('Pas de connexion Internet.');
    } on TimeoutException {
      throw AppException('La requête a expiré (timeout).');
    } on FormatException {
      throw AppException('La réponse du serveur est invalide.');
    } catch (e) {
      developer.log('Erreur inconnue: $e', name: 'ApiService');
      throw AppException('Une erreur inconnue est survenue.');
    }
  }

  Future<Map<String, dynamic>> loginGroup(String userLogin, String mdp) async {
    final response = await _safeRequest(
      HttpMethod.post,
      '/auth/login',
      body: jsonEncode({'userlogin': userLogin, 'mdp': mdp}),
    );

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> registerGroup(Map<String, dynamic> groupData) async {
    await _safeRequest(
      HttpMethod.post,
      '/auth/create_group',
      body: jsonEncode(groupData),
    );
  }

  Future<List<dynamic>> getGroupList() async {
    final response = await _safeRequest(
      HttpMethod.get,
      '/groupes',
    );

    return jsonDecode(response.body);
  }
  Future<Map<String, dynamic>> getGroup(String groupId) async {
    final response = await _safeRequest(
      HttpMethod.get,
      '/groupes/$groupId',
    );

    return jsonDecode(response.body);
  }

  Future<List<dynamic>> getTentList(String groupId) async {
    final response = await _safeRequest(
      HttpMethod.get,
      '/tentes?groupeId=$groupId',
    );

    return jsonDecode(response.body);
  }

  Future<void> createTent(Map<String, dynamic> tent) async {
    await _safeRequest(
      HttpMethod.post,
      '/tentes',
      body: jsonEncode(tent)
    );
  }

  Future<void> updateTent(int tentId, Map<String, dynamic> tent) async {
    await _safeRequest(
        HttpMethod.put,
        '/tentes/$tentId',
        body: jsonEncode(tent)
    );
  }

  Future<void> deleteTent(int tentId, {required String groupId}) async {
    await _safeRequest(
        HttpMethod.delete,
        '/tentes/$tentId',
    );
  }

  Future<List<dynamic>> getEventList(String groupId) async {
    final response = await _safeRequest(
        HttpMethod.get,
        '/evenements?groupeId=$groupId',
    );
    return jsonDecode(response.body);
  }

  Future<void> addEvent(Map<String, dynamic> evt) async {
    await _safeRequest(
      HttpMethod.post,
      '/evenements',
      body: jsonEncode(evt),
    );
  }

  Future<void> updateEvent(int eventId, Map<String, dynamic> evt) async {
    await _safeRequest(
      HttpMethod.put,
      '/evenements',
      body: jsonEncode(evt),
    );
  }

  Future<void> deleteEvent(int eventId, {required String groupId}) async {
    await _safeRequest(
      HttpMethod.delete,
      '/evenements/$eventId',
    );
  }

  Future<List<dynamic>> getEventListByPeriod(String groupId, DateTime start, DateTime end) async {
    final response = await _safeRequest(
      HttpMethod.get,
      '/evenements?groupeId=$groupId&debut=${start.toIso8601String()}&fin=${end.toIso8601String()}',
    );
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> getReservationList({int? tentId, int? eventId}) async {
    final response = await _safeRequest(
      HttpMethod.get,
      '/reservations',
    );
    return jsonDecode(response.body);
  }

  Future<void> addReservation(Map<String, dynamic> reservation) async {
    await _safeRequest(
      HttpMethod.post,
      '/reservations',
      body: jsonEncode(reservation),
    );
  }

  Future<List<dynamic>> getControlList(int tentId) async {
    final response = await _safeRequest(
      HttpMethod.get,
      '/controles?tenteId=$tentId',
    );
    return jsonDecode(response.body);
  }

  Future<void> addControl(Map<String, dynamic> control) async {
    await _safeRequest(
      HttpMethod.post,
      '/controles',
      body: jsonEncode(control),
    );
  }

  Future<void> updateControl(int controlId, Map<String, dynamic> control) async {
    await _safeRequest(
      HttpMethod.put,
      '/controles/$controlId',
      body: jsonEncode(control),
    );
  }

  Future<void> deleteControl(int controlId) async {
    await _safeRequest(
      HttpMethod.delete,
      '/controles/$controlId',
    );
  }

  Future<List<dynamic>> getMenuList() async {
    final response = await _safeRequest(
      HttpMethod.get,
      '/menus',
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getMenu(int menuId) async {
    final response = await _safeRequest(
      HttpMethod.get,
      '/menus/$menuId',
    );
    return jsonDecode(response.body);

  }

  Future<void> addMenu(Map<String, dynamic> menuJson) async {
    await _safeRequest(
      HttpMethod.post,
      '/menus',
      body: jsonEncode(menuJson),
    );
  }

  Future<void> updateMenu(int menuId, Map<String, dynamic> menuJson) async {
    await _safeRequest(
      HttpMethod.put,
      '/menus',
      body: jsonEncode(menuJson),
    );
  }

  Future<void> deleteMenu(int menuId) async {
    await _safeRequest(
      HttpMethod.delete,
      '/menus/$menuId',
    );
  }

  Future<List<dynamic>> getEventMenuList(int eventId) async {
    final response = await _safeRequest(
      HttpMethod.get,
      '/event_menus?event_id=$eventId',
    );
    return jsonDecode(response.body);
  }

  Future<void> addEventMenu(Map<String, dynamic> menuData) async {
    await _safeRequest(
      HttpMethod.post,
      '/event_menus',
      body: jsonEncode(menuData),
    );
  }

  Future<void> updateEventMenu(int eventMenuId, Map<String, dynamic> menuData) async {
    await _safeRequest(
      HttpMethod.put,
      '/event_menus',
      body: jsonEncode(menuData),
    );
  }

  Future<void> deleteEventMenu(int eventMenuId) async {
    await _safeRequest(
      HttpMethod.delete,
      '/event_menus/$eventMenuId',
    );
  }

  Future<void> createMenu(Map<String, dynamic> menu) async {
    await _safeRequest(
      HttpMethod.delete,
      '/menus',
      body: jsonEncode(menu),
    );
  }
}
