import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:logistiscout/data/models/login_notice_dto.dart';
import 'package:logistiscout/services/app_exception.dart';
import 'package:logistiscout/services/client_context_service.dart';
import 'package:logistiscout/services/token_store.dart';

enum HttpMethod {
  get("GET"),
  post("POST"),
  put("PUT"),
  delete("DELETE"),
  patch("PATCH");

  final String name;
  const HttpMethod(this.name);
}

class ApiService {
  ApiService._internal({required this.baseUrl}) {
    developer.log('ApiService singleton created', name: 'ApiService');
  }

  static ApiService? _instance;
  Future<bool>? _refreshInFlight;

  Future<Map<String, String>> _headers() async {
    final token = await TokenStore.instance.readAccessToken();
    final clientContextHeaders = await ClientContextService.instance
        .buildHeaders();

    final headers = {'Content-Type': 'application/json'};

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    headers.addAll(clientContextHeaders);

    return headers;
  }

  static const String _defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.logistiscout.fr',
  );

  factory ApiService({String baseUrl = _defaultBaseUrl}) {
    developer.log('ApiService instance requested', name: 'ApiService');
    return _instance ??= ApiService._internal(baseUrl: baseUrl);
  }

  static void reconfigure({required String baseUrl, http.Client? client}) {
    _instance = ApiService._internal(baseUrl: baseUrl);
  }

  final String baseUrl;

  String? _extractErrorDetail(String rawBody) {
    try {
      final decoded = jsonDecode(rawBody);
      if (decoded is Map<String, dynamic>) {
        final detail = decoded['detail'];
        if (detail is String && detail.trim().isNotEmpty) {
          return detail.trim();
        }
      }
    } catch (_) {
      // Keep fallback mapping when response body is not valid JSON.
    }
    return null;
  }

  //Gestion des erreurs HTTP et des exceptions
  Future<http.Response> _safeRequest(
    HttpMethod method,
    String path, {
    Object? body,
    Map<String, String>? extraHeaders,
    bool retrying = false,
  }) async {
    final headers = await _headers();
    if (extraHeaders != null && extraHeaders.isNotEmpty) {
      headers.addAll(extraHeaders);
    }
    final uri = Uri.parse('$baseUrl/v2$path');

    try {
      developer.log('${method.name} /v2$path body: $body', name: 'ApiService');

      late final http.Response response;

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
        case HttpMethod.patch:
          response = await http
              .patch(uri, headers: headers, body: body)
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
      final isAuthError =
          response.statusCode == 401 || response.statusCode == 403;
      final isRefreshCall = path == '/auth/refresh';
      final isLoginCall = path == '/auth/login';
      final backendDetail = _extractErrorDetail(response.body);

      if (isAuthError && !retrying && !isRefreshCall && !isLoginCall) {
        final refreshed = await refreshToken();
        if (refreshed) {
          // retry once with the new access token
          return _safeRequest(method, path, body: body, retrying: true);
        } else {
          await TokenStore.instance.clear();
          throw AppException(
            "Session expirée. Veuillez vous reconnecter.",
            statusCode: response.statusCode,
          );
        }
      }

      // --- Your existing error mapping ---
      switch (response.statusCode) {
        case 400:
          throw AppException(
            backendDetail ?? "Requête invalide (400).",
            statusCode: 400,
          );
        case 401:
        case 403:
          throw AppException(
            backendDetail ?? "Accès refusé.",
            statusCode: response.statusCode,
          );
        case 404:
          throw AppException(
            backendDetail ?? "Ressource non trouvée (404).",
            statusCode: 404,
          );
        case 500:
        case 502:
        case 503:
        case 504:
          throw AppException(
            "Erreur serveur (${response.statusCode}).",
            statusCode: response.statusCode,
          );
        default:
          throw AppException(
            "Erreur inattendue (${response.statusCode}).",
            statusCode: response.statusCode,
          );
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

  Future<dynamic> checkToken() async {
    final response = await _safeRequest(HttpMethod.get, '/auth/check');
    return jsonDecode(response.body);
  }

  Future<bool> refreshToken() async {
    final inFlight = _refreshInFlight;
    if (inFlight != null) {
      return inFlight;
    }

    final completer = Completer<bool>();
    _refreshInFlight = completer.future;

    () async {
      try {
        final refreshToken = await TokenStore.instance.readRefreshToken();
        if (refreshToken == null || refreshToken.isEmpty) {
          completer.complete(false);
          return;
        }

        final uri = Uri.parse('$baseUrl/v2/auth/refresh');

        final res = await http
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'refresh_token': refreshToken}),
            )
            .timeout(const Duration(seconds: 10));

        if (res.statusCode < 200 || res.statusCode >= 300) {
          completer.complete(false);
          return;
        }

        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final newAccess = data['access_token'] as String?;
        final newRefresh = data['refresh_token'] as String?;

        if (newAccess == null || newAccess.isEmpty) {
          completer.complete(false);
          return;
        }

        await TokenStore.instance.saveAccessToken(newAccess);
        if (newRefresh != null && newRefresh.isNotEmpty) {
          await TokenStore.instance.saveRefreshToken(newRefresh);
        }
        completer.complete(true);
      } catch (_) {
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      } finally {
        if (identical(_refreshInFlight, completer.future)) {
          _refreshInFlight = null;
        }
      }
    }();

    return completer.future;
  }

  Future<dynamic> getGroupInfo() {
    return _safeRequest(
      HttpMethod.get,
      '/me',
    ).then((response) => jsonDecode(response.body));
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

  Future<Map<String, dynamic>> requestPasswordReset(String identifier) async {
    final response = await _safeRequest(
      HttpMethod.post,
      '/auth/password_reset/request',
      body: jsonEncode({'identifier': identifier}),
    );

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> confirmPasswordReset({
    required String resetToken,
    required String newPassword,
  }) async {
    await _safeRequest(
      HttpMethod.post,
      '/auth/password_reset/confirm',
      body: jsonEncode({
        'reset_token': resetToken,
        'new_password': newPassword,
      }),
    );
  }

  Future<List<LoginNoticeDto>> getActiveNotices() async {
    final response = await _safeRequest(HttpMethod.get, '/notices/active');
    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .map((item) => LoginNoticeDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> acknowledgeNotices(List<int> noticeIds) async {
    if (noticeIds.isEmpty) {
      return;
    }

    await _safeRequest(
      HttpMethod.post,
      '/notices/ack',
      body: jsonEncode({'noticeIds': noticeIds}),
    );
  }

  Future<Map<String, dynamic>> acceptTermsOnServer(String termsVersion) async {
    final response = await _safeRequest(
      HttpMethod.post,
      '/legal/terms/accept',
      body: jsonEncode({'termsVersion': termsVersion}),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<LoginNoticeDto>> listAdminNotices({
    required String adminToken,
  }) async {
    final response = await _safeRequest(
      HttpMethod.get,
      '/admin/notices',
      extraHeaders: {'X-Admin-Token': adminToken},
    );
    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .map((item) => LoginNoticeDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<LoginNoticeDto> createAdminNotice(
    Map<String, dynamic> payload, {
    required String adminToken,
  }) async {
    final response = await _safeRequest(
      HttpMethod.post,
      '/admin/notices',
      body: jsonEncode(payload),
      extraHeaders: {'X-Admin-Token': adminToken},
    );
    return LoginNoticeDto.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<LoginNoticeDto> updateAdminNotice(
    int noticeId,
    Map<String, dynamic> payload, {
    required String adminToken,
  }) async {
    final response = await _safeRequest(
      HttpMethod.put,
      '/admin/notices/$noticeId',
      body: jsonEncode(payload),
      extraHeaders: {'X-Admin-Token': adminToken},
    );
    return LoginNoticeDto.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> deleteAdminNotice(
    int noticeId, {
    required String adminToken,
  }) async {
    await _safeRequest(
      HttpMethod.delete,
      '/admin/notices/$noticeId',
      extraHeaders: {'X-Admin-Token': adminToken},
    );
  }

  Future<List<dynamic>> getGroupList() async {
    final response = await _safeRequest(HttpMethod.get, '/groupes');

    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getGroup(String groupId) async {
    final response = await _safeRequest(HttpMethod.get, '/groupes/$groupId');

    return jsonDecode(response.body);
  }

  Future<List<dynamic>> getTentList() async {
    final response = await _safeRequest(HttpMethod.get, '/tentes');

    return jsonDecode(response.body);
  }

  Future<void> createTent(Map<String, dynamic> tent) async {
    await _safeRequest(HttpMethod.post, '/tentes', body: jsonEncode(tent));
  }

  Future<void> updateTent(int tentId, Map<String, dynamic> tent) async {
    await _safeRequest(
      HttpMethod.put,
      '/tentes/$tentId',
      body: jsonEncode(tent),
    );
  }

  Future<void> deleteTent(int tentId) async {
    await _safeRequest(HttpMethod.delete, '/tentes/$tentId');
  }

  Future<List<dynamic>> getEventList() async {
    final response = await _safeRequest(
      HttpMethod.get,
      '/evenements?unit_mode=ids',
    );
    return jsonDecode(response.body);
  }

  Future<void> addEvent(Map<String, dynamic> evt) async {
    await _safeRequest(HttpMethod.post, '/evenements', body: jsonEncode(evt));
  }

  Future<void> updateEvent(int eventId, Map<String, dynamic> evt) async {
    await _safeRequest(
      HttpMethod.put,
      '/evenements/$eventId',
      body: jsonEncode(evt),
    );
  }

  Future<void> deleteEvent(int eventId) async {
    await _safeRequest(HttpMethod.delete, '/evenements/$eventId');
  }

  Future<List<dynamic>> getEventListByPeriod(
    String groupId,
    DateTime start,
    DateTime end,
  ) async {
    final response = await _safeRequest(
      HttpMethod.get,
      '/evenements&debut=${start.toIso8601String()}&fin=${end.toIso8601String()}',
    );
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> getReservationList({int? tentId, int? eventId}) async {
    final response = await _safeRequest(HttpMethod.get, '/reservations');
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

  Future<Map<String, dynamic>> addControl(Map<String, dynamic> control) async {
    final response = await _safeRequest(
      HttpMethod.post,
      '/controles',
      body: jsonEncode(control),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> uploadControlPicture({
    required int controlId,
    required Uint8List bytes,
    required String fileName,
    bool retrying = false,
  }) async {
    final uri = Uri.parse('$baseUrl/v2/controles/$controlId/picture');
    final headers = await _headers();
    final authHeader = headers['Authorization'];
    headers.remove('Content-Type');

    developer.log(
      'POST multipart /v2/controles/$controlId/picture '
      'fileName=$fileName size=${bytes.length}B retrying=$retrying '
      'authPresent=${authHeader != null && authHeader.isNotEmpty} uri=$uri',
      name: 'ApiService',
    );

    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(headers)
      ..files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: fileName),
      );

    late final http.Response response;
    try {
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
      );
      response = await http.Response.fromStream(streamedResponse);
    } on SocketException catch (e, st) {
      developer.log(
        'SocketException during uploadControlPicture: $e',
        name: 'ApiService',
        error: e,
        stackTrace: st,
      );
      throw AppException('Pas de connexion Internet.');
    } on TimeoutException catch (e, st) {
      developer.log(
        'Timeout during uploadControlPicture: $e',
        name: 'ApiService',
        error: e,
        stackTrace: st,
      );
      throw AppException('Upload photo expiré (timeout).');
    } catch (e, st) {
      developer.log(
        'Unexpected error during uploadControlPicture send: $e',
        name: 'ApiService',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }

    developer.log(
      'Response /v2/controles/$controlId/picture: ${response.statusCode} - ${response.body}',
      name: 'ApiService',
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    final isAuthError =
        response.statusCode == 401 || response.statusCode == 403;
    if (isAuthError && !retrying) {
      developer.log(
        'Picture upload got ${response.statusCode}; attempting token refresh and retry',
        name: 'ApiService',
      );
      final refreshed = await refreshToken();
      developer.log(
        'Token refresh after picture upload auth error: $refreshed',
        name: 'ApiService',
      );
      if (refreshed) {
        return uploadControlPicture(
          controlId: controlId,
          bytes: bytes,
          fileName: fileName,
          retrying: true,
        );
      }
    }

    if (response.statusCode == 413) {
      throw AppException(
        'Upload de photo impossible (413) : photo trop lourde.',
        statusCode: response.statusCode,
      );
    }

    throw AppException(
      'Upload de photo impossible (${response.statusCode}) - ${response.body}',
      statusCode: response.statusCode,
    );
  }

  Future<void> updateControl(
    int controlId,
    Map<String, dynamic> control,
  ) async {
    await _safeRequest(
      HttpMethod.put,
      '/controles/$controlId',
      body: jsonEncode(control),
    );
  }

  Future<void> deleteControl(int controlId) async {
    await _safeRequest(HttpMethod.delete, '/controles/$controlId');
  }

  Future<List<dynamic>> getMenuList() async {
    final response = await _safeRequest(HttpMethod.get, '/menus');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getReceipe(int menuId) async {
    final response = await _safeRequest(HttpMethod.get, '/menus/$menuId');
    return jsonDecode(response.body);
  }

  Future<void> addMenu(Map<String, dynamic> menuJson) async {
    await _safeRequest(HttpMethod.post, '/menus', body: jsonEncode(menuJson));
  }

  Future<void> updateMenu(int menuId, Map<String, dynamic> menuJson) async {
    await _safeRequest(HttpMethod.put, '/menus', body: jsonEncode(menuJson));
  }

  Future<void> deleteMenu(int menuId) async {
    await _safeRequest(HttpMethod.delete, '/menus/$menuId');
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

  Future<void> updateEventMenu(
    int eventMenuId,
    Map<String, dynamic> menuData,
  ) async {
    await _safeRequest(
      HttpMethod.put,
      '/event_menus/$eventMenuId',
      body: jsonEncode(menuData),
    );
  }

  Future<void> deleteEventMenu(int eventMenuId) async {
    await _safeRequest(HttpMethod.delete, '/event_menus/$eventMenuId');
  }

  Future<void> createMenu(Map<String, dynamic> menu) async {
    await _safeRequest(HttpMethod.post, '/menus', body: jsonEncode(menu));
  }

  Future<void> updateGroupInfo(Map<String, dynamic> json) async {
    await _safeRequest(HttpMethod.put, '/me', body: jsonEncode(json));
  }

  Future<void> updateGroupProfileFields(Map<String, dynamic> json) async {
    await _safeRequest(HttpMethod.put, '/me', body: jsonEncode(json));
  }

  Future<void> deleteCurrentGroup() async {
    try {
      await _safeRequest(HttpMethod.delete, '/me');
    } on AppException catch (e) {
      if (e.statusCode != 405) rethrow;
      await _safeRequest(HttpMethod.post, '/me/delete');
    }
  }

  Future<Map<String, dynamic>> createGroupUnit(
    Map<String, dynamic> json,
  ) async {
    final response = await _safeRequest(
      HttpMethod.post,
      '/me/units',
      body: jsonEncode(json),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateGroupUnit(
    int unitId,
    Map<String, dynamic> json,
  ) async {
    final response = await _safeRequest(
      HttpMethod.put,
      '/me/units/$unitId',
      body: jsonEncode(json),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> deleteGroupUnit(int unitId, {bool forceReplace = false}) async {
    final suffix = forceReplace ? '?force_replace=true' : '';
    await _safeRequest(HttpMethod.delete, '/me/units/$unitId$suffix');
  }

  Future<List<dynamic>> getTentStatuses() async {
    final response = await _safeRequest(HttpMethod.get, '/me/tent-statuses');
    return jsonDecode(response.body) as List<dynamic>;
  }

  Future<Map<String, dynamic>> createTentStatus(
    Map<String, dynamic> json,
  ) async {
    final response = await _safeRequest(
      HttpMethod.post,
      '/me/tent-statuses',
      body: jsonEncode(json),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateTentStatus(
    int statusId,
    Map<String, dynamic> json,
  ) async {
    final response = await _safeRequest(
      HttpMethod.put,
      '/me/tent-statuses/$statusId',
      body: jsonEncode(json),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> deleteTentStatus(
    int statusId, {
    int? replacementStatusId,
    bool archiveOnly = false,
  }) async {
    await _safeRequest(
      HttpMethod.delete,
      '/me/tent-statuses/$statusId',
      body: jsonEncode({
        'replacementStatusId': replacementStatusId,
        'archiveOnly': archiveOnly,
      }),
    );
  }

  Future<List<dynamic>> resetDefaultTentStatuses() async {
    final response = await _safeRequest(
      HttpMethod.post,
      '/me/tent-statuses/reset-defaults',
    );
    return jsonDecode(response.body) as List<dynamic>;
  }
}
