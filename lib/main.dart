import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/models.dart';
import 'models/database_helper.dart';
import 'pages/accueil_page.dart';
import 'pages/tentes_page.dart';
import 'pages/unites_page.dart';
import 'pages/evenements_page.dart';
import 'pages/controle_page.dart';
import 'pages/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await deleteDatabase(await getDatabasesPath() + '/logistiscout.db');
  await DatabaseHelper.instance.database;
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool? isLoggedIn;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('groupe_id');
    final mdp = prefs.getString('groupe_mdp');
    setState(() {
      isLoggedIn = (id != null && mdp != null && id.isNotEmpty && mdp.isNotEmpty);
    });
  }

  void _onLogin() {
    setState(() {
      isLoggedIn = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoggedIn == null) {
      return const MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator())));
    }
    return MaterialApp(
      title: 'LogistiScout',
      theme: ThemeData(
        colorScheme: ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xFF003a5d),
          onPrimary: Colors.white,
          secondary: Color(0xFF0077b3),
          onSecondary: Colors.white,
          error: Color(0xFFE2001A),
          onError: Colors.white,
          background: Color(0xFFF5F5F5),
          onBackground: Color(0xFF003a5d),
          surface: Colors.white,
          onSurface: Color(0xFF003a5d),
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF003a5d),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF003a5d),
          foregroundColor: Color(0xFFffffff),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFF003a5d),
          unselectedItemColor: Color(0xFFB0B0B0),
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            color: Color(0xFF0077b3),
            fontWeight: FontWeight.bold,
          ),
          titleMedium: TextStyle(
            color: Color(0xFF0077b3),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      home: isLoggedIn!
          ? const AccueilPage()
          : LoginPage(onLogin: _onLogin),
    );
  }
}
