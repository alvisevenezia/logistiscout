import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:logistiscout/services/AppException.dart';
import 'package:logistiscout/services/token_store.dart';

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
    final token = await TokenStore.instance.readAccessToken();

    final headers = {
      'Content-Type': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }


  factory ApiService({String baseUrl = 'https://api.logistiscout.fr'}) {
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
        bool retrying = false,
      }) async {
    final headers = await _headers();
    final uri = Uri.parse('$baseUrl/v2$path');

    try {
      developer.log('${method.name} /v2$path body: $body', name: 'ApiService');

      late final http.Response response;

      switch (method) {
        case HttpMethod.get:
          response = await http.get(uri, headers: headers)
              .timeout(const Duration(seconds: 10));
          break;
        case HttpMethod.post:
          response = await http.post(uri, headers: headers, body: body)
              .timeout(const Duration(seconds: 10));
          break;
        case HttpMethod.put:
          response = await http.put(uri, headers: headers, body: body)
              .timeout(const Duration(seconds: 10));
          break;
        case HttpMethod.delete:
          response = await http.delete(uri, headers: headers, body: body)
              .timeout(const Duration(seconds: 10));
          break;
      }

      developer.log(
        'Response /v2$path: ${response.statusCode} - ${response.body}',
        name: 'ApiService',
      );

      // ✅ Success
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response;
      }

      // 🔁 If unauthorized, try refresh once then retry original request
      final isAuthError = response.statusCode == 401 || response.statusCode == 403;
      final isRefreshCall = path == '/auth/refresh';

      if (isAuthError && !retrying && !isRefreshCall) {
        final refreshed = await refreshToken();
        if (refreshed) {
          // retry once with the new access token
          return _safeRequest(method, path, body: body, retrying: true);
        } else {
          await TokenStore.instance.clear();
          throw AppException("Session expirée. Veuillez vous reconnecter.",
              statusCode: response.statusCode);
        }
      }

      // --- Your existing error mapping ---
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
      if (e is AppException) rethrow;
      throw AppException('Une erreur inconnue est survenue.');
    }
  }


  Future<bool> refreshToken() async {
    final refreshToken = await TokenStore.instance.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    final uri = Uri.parse('$baseUrl/v2/auth/refresh');

    try {
      final res = await http
          .post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode < 200 || res.statusCode >= 300) {
        return false;
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final newAccess = data['access_token'] as String?;
      final newRefresh = data['refresh_token'] as String?;

      if (newAccess == null || newAccess.isEmpty) return false;

      await TokenStore.instance.saveAccessToken(newAccess);
      if (newRefresh != null && newRefresh.isNotEmpty) {
        await TokenStore.instance.saveRefreshToken(newRefresh);
      }
      return true;
    } catch (_) {
      return false;
    }
  }


  Future<Map<String, dynamic>> loginGroup(String userLogin, String mdp) async {
    final response = await _safeRequest(
      HttpMethod.post,
      '/auth/login',
      body: jsonEncode({'userlogin': userLogin, 'mdp': mdp}),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    final access = data['access_token'] as String?;
    final refresh = data['refresh_token'] as String?;

    if (access != null) {
      await TokenStore.instance.saveAccessToken(access);
    }
    if (refresh != null) {
      await TokenStore.instance.saveRefreshToken(refresh);
    }

    return data;
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
      '/tentes',
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

  Future<List<dynamic>> getEventList() async {
    final response = await _safeRequest(
        HttpMethod.get,
        '/evenements',
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
      '/evenements/$eventId',
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
      '/evenements&debut=${start.toIso8601String()}&fin=${end.toIso8601String()}',
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

  Future<Map<String, dynamic>> getReceipe(int menuId) async {
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

  Future<List<dynamic>> getEventMealPlanList(int eventId) async {
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
      '/event_menus/$eventMenuId',
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
      HttpMethod.post,
      '/menus',
      body: jsonEncode(menu),
    );
  }
}
