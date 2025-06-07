import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://57.128.224.111:8000';

  // Authentification groupe
  static Future<Map<String, dynamic>?> loginGroupe(String userlogin, String mdp) async {
    //print('[API] POST /auth/login {userlogin: $userlogin, mdp: ***}');
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userlogin': userlogin, 'mdp': mdp}),
    );
    //print('[API] Response: \\${response.statusCode} - \\${response.body}');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  // Groupes
  static Future<List<dynamic>> getGroupes() async {
    //print('[API] GET /groupes');
    final response = await http.get(Uri.parse('$baseUrl/groupes'));
    //print('[API] Response: ${response.statusCode} - ${response.body}');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Erreur chargement groupes');
  }
  static Future<Map<String, dynamic>> getGroupe(String groupeId) async {
    //print('[API] GET /groupes/$groupeId');
    final response = await http.get(Uri.parse('$baseUrl/groupes/$groupeId'));
    //print('[API] Response: ${response.statusCode} - ${response.body}');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Erreur chargement groupe');
  }

  // Tentes
  static Future<List<dynamic>> getTentes(String groupeId) async {
    final url = '$baseUrl/tentes?groupeId=$groupeId';
    //print('[API] GET $url');
    if (groupeId.isEmpty) {
      //print('[API][ERREUR] groupeId est null ou vide !');
      throw Exception('groupeId manquant');
    }
    final response = await http.get(Uri.parse(url));
    //print('[API] Response: ${response.statusCode} - ${response.body}');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Erreur chargement tentes');
  }
  static Future<Map<String, dynamic>> getTente(int tenteId) async {
    //print('[API] GET /tentes/$tenteId');
    final response = await http.get(Uri.parse('$baseUrl/tentes/$tenteId'));
    //print('[API] Response: ${response.statusCode} - ${response.body}');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Erreur chargement tente');
  }
  static Future<void> addTente(Map<String, dynamic> tente) async {
    // S'assurer que le champ groupeId est bien présent
    if (!tente.containsKey('groupeId') || tente['groupeId'] == null || tente['groupeId'].toString().isEmpty) {
      throw Exception('groupeId manquant lors de l\'ajout de tente');
    }
    //print('[API] POST /tentes {tente: $tente}');
    final response = await http.post(
      Uri.parse('$baseUrl/tentes'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(tente),
    );
    //print('[API] Response: ${response.statusCode} - ${response.body}');
    if (response.statusCode != 201) {
      throw Exception('Erreur ajout tente');
    }
  }
  static Future<void> updateTente(int tenteId, Map<String, dynamic> tente) async {
    // S'assurer que le champ groupeId est bien présent
    if (!tente.containsKey('groupeId') || tente['groupeId'] == null || tente['groupeId'].toString().isEmpty) {
      throw Exception('groupeId manquant lors de la modification de tente');
    }
    //print('[API] PUT /tentes/$tenteId {tente: $tente}');
    final response = await http.put(
      Uri.parse('$baseUrl/tentes/$tenteId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(tente),
    );
    //print('[API] Response: ${response.statusCode} - ${response.body}');
    if (response.statusCode != 200) {
      throw Exception('Erreur modification tente');
    }
  }
  static Future<void> deleteTente(int tenteId) async {
    //print('[API] DELETE /tentes/$tenteId');
    final response = await http.delete(Uri.parse('$baseUrl/tentes/$tenteId'));
    //print('[API] Response: ${response.statusCode} - ${response.body}');
    if (response.statusCode != 204) {
      throw Exception('Erreur suppression tente');
    }
  }

  // Événements
  static Future<List<dynamic>> getEvenements(String groupeId) async {
    //print('[API] GET /evenements?groupeId=$groupeId');
    final response = await http.get(Uri.parse('$baseUrl/evenements?groupeId=$groupeId'));
    //print('[API] Response: ${response.statusCode} - ${response.body}');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Erreur chargement événements');
  }
  static Future<Map<String, dynamic>> getEvenement(int evenementId) async {
    //print('[API] GET /evenements/$evenementId');
    final response = await http.get(Uri.parse('$baseUrl/evenements/$evenementId'));
    //print('[API] Response: ${response.statusCode} - ${response.body}');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Erreur chargement événement');
  }
  static Future<void> addEvenement(Map<String, dynamic> evt) async {
    //print('[API] POST /evenements {evt: $evt}');
    final response = await http.post(
      Uri.parse('$baseUrl/evenements'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(evt),
    );
    //print('[API] Response: ${response.statusCode} - ${response.body}');
    if (response.statusCode != 201) {
      throw Exception('Erreur ajout événement');
    }
  }
  static Future<void> updateEvenement(int evenementId, Map<String, dynamic> evt) async {
    //print('[API] PUT /evenements/$evenementId {evt: $evt}');
    final response = await http.put(
      Uri.parse('$baseUrl/evenements/$evenementId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(evt),
    );
    //print('[API] Response: ${response.statusCode} - ${response.body}');
    if (response.statusCode != 200) {
      throw Exception('Erreur modification événement');
    }
  }
  static Future<void> deleteEvenement(int evenementId) async {
    //print('[API] DELETE /evenements/$evenementId');
    final response = await http.delete(Uri.parse('$baseUrl/evenements/$evenementId'));
    //print('[API] Response: ${response.statusCode} - ${response.body}');
    if (response.statusCode != 204) {
      throw Exception('Erreur suppression événement');
    }
  }

  // Récupère les événements sur une période donnée
  static Future<List<dynamic>> getEvenementsParPeriode(String groupeId, DateTime debut, DateTime fin) async {
    final url = '$baseUrl/evenements?groupeId=$groupeId&debut=${debut.toIso8601String()}&fin=${fin.toIso8601String()}';
    //print('[API] GET $url');
    final response = await http.get(Uri.parse(url));
    //print('[API] Response: \\${response.statusCode} - \\${response.body}');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Erreur chargement événements par période');
  }

  // Réservations
  static Future<List<dynamic>> getReservations({int? tenteId, int? evenementId}) async {
    String url = '$baseUrl/reservations?';
    if (tenteId != null) url += 'tenteId=$tenteId&';
    if (evenementId != null) url += 'evenementId=$evenementId&';
    //print('[API] GET $url');
    final response = await http.get(Uri.parse(url));
    //print('[API] Response: ${response.statusCode} - ${response.body}');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Erreur chargement réservations');
  }
  static Future<void> addReservation(Map<String, dynamic> reservation) async {
    //print('[API] POST /reservations {reservation: $reservation}');
    final response = await http.post(
      Uri.parse('$baseUrl/reservations'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(reservation),
    );
    //print('[API] Response: ${response.statusCode} - ${response.body}');
    if (response.statusCode != 201) {
      throw Exception('Erreur ajout réservation');
    }
  }

  // Contrôles
  static Future<List<dynamic>> getControles(int tenteId) async {
    //print('[API] GET /controles?tenteId=$tenteId');
    final response = await http.get(Uri.parse('$baseUrl/controles?tenteId=$tenteId'));
    //print('[API] Response: ${response.statusCode} - ${response.body}');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Erreur chargement contrôles');
  }
  static Future<void> addControle(Map<String, dynamic> controle) async {
    final url = Uri.parse('$baseUrl/controles');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(controle), // On envoie un map sans id
    );
    if (response.statusCode == 201) {
      return;
    } else {
      //print('[API] Response: ${response.statusCode} - ${response.body}');
      throw Exception('Erreur ajout contrôle');
    }
  }

  static Future<void> updateControle(int controleId, Map<String, dynamic> controle) async {
    //print('[API] PUT /controles/$controleId {controle: $controle}');
    final response = await http.put(
      Uri.parse('$baseUrl/controles/$controleId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(controle),
    );
    //print('[API] Response: ${response.statusCode} - ${response.body}');
    if (response.statusCode != 200) {
      throw Exception('Erreur modification contrôle');
    }
  }
  static Future<void> deleteControle(int controleId) async {
    //print('[API] DELETE /controles/$controleId');
    final response = await http.delete(Uri.parse('$baseUrl/controles/$controleId'));
    //print('[API] Response: ${response.statusCode} - ${response.body}');
    if (response.statusCode != 204) {
      throw Exception('Erreur suppression contrôle');
    }
  }
}

