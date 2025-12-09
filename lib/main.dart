import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logistiscout/services/local_storage_service.dart';
import 'package:logistiscout/ui/pages/contact_page.dart';
import 'package:logistiscout/ui/pages/evenement_page.dart';
import 'package:logistiscout/ui/pages/home_page.dart';
import 'package:logistiscout/ui/pages/login_page.dart';
import 'package:logistiscout/ui/pages/tentes_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final groupID = await LocalStorageService.instance.getGroupId();

  runApp(
    ProviderScope(
      child: MyApp(isLoggedIn: groupID != null && groupID.isNotEmpty),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Logistiscout',
      initialRoute: isLoggedIn ? '/accueil' : '/login',
      routes: {
        '/login': (context) => LoginPage(onLogin: () {
          Navigator.of(context).pushReplacementNamed('/accueil');
        }),
        '/accueil': (context) => const _MainNavigation(),
      },
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF003a5d),
          onPrimary: Colors.white,
          secondary: Color(0xFF0077b3),
          onSecondary: Colors.white,
          error: Color(0xFFE2001A),
          onError: Colors.white,
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
          foregroundColor: Colors.white,
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
    );
  }
}


class _MainNavigation extends StatefulWidget {
  const _MainNavigation();
  @override
  State<_MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<_MainNavigation> {
  int _selectedIndex = 0;
  static const List<Widget> _pages = <Widget>[
    HomePage(),
    TentesPage(),
    EvenementsPage(),
    ContactPage()
  ];

  // Ajout d'une méthode pour valider la capacité des canadiennes
  bool isCapaciteValide(int capacite) {
    return capacite >= 4 && capacite <= 8;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.cabin),
            label: 'Tentes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Événements',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.contact_support),
            label: 'Contact',
          ),
        ],
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

