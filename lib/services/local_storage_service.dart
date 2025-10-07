import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  LocalStorageService._();
  static final LocalStorageService instance = LocalStorageService._();

  Future<void> saveGroupId(String groupId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('groupId', groupId);
  }

  Future<String?> getGroupId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('groupId');
  }

  Future<void> saveUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
  }

  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<void> clearGroupData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('groupeId');
    await prefs.remove('groupe_mdp');
    await prefs.remove('token');
  }

  Future<void> saveControleurName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('controleurName', name);
  }

  Future<String?> getControleurName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('controleurName');
  }
}


