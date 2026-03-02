import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logistiscout/core/di.dart';
import 'package:logistiscout/services/local_storage_service.dart';
import 'package:logistiscout/services/token_store.dart';
import 'package:logistiscout/ui/pages/account/group_settings_page.dart';
import 'package:logistiscout/ui/pages/auth/auth_gate.dart';
import 'package:logistiscout/ui/pages/contact/contact_page.dart';
import 'package:logistiscout/ui/pages/event/evenement_detail_page.dart';
import 'package:logistiscout/ui/pages/event/evenement_page.dart';
import 'package:logistiscout/ui/pages/home_page.dart';
import 'package:logistiscout/ui/pages/auth/login_page.dart';
import 'package:logistiscout/ui/pages/tent/tente_detail_page.dart';
import 'package:logistiscout/ui/pages/tent/tentes_page.dart';

final _router = GoRouter(
  initialLocation: '/bootstrap',
  routes: [
    GoRoute(
      path: '/bootstrap',
      builder: (context, state) => const AuthGate(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => LoginPage(
        onLogin: () => context.go('/home'),
      ),
    ),
    GoRoute(
      path: '/account',
      builder: (context, state) => const GroupSettingsPage(),
    ),
    // Bottom-nav shell
    ShellRoute(
      builder: (context, state, child) => _MainNavigation(child: child),
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: '/tents',
          builder: (context, state) => const TentesPage(),
          routes: [
            GoRoute(
              path: ':tentId',
              builder: (context, state) {
                final tentId = int.parse(state.pathParameters['tentId']!);
                return TenteDetailPage(tentId: tentId);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/events',
          builder: (context, state) => const EvenementsPage(),
          routes: [
            GoRoute(
              path: ':eventId',
              builder: (context, state) {
                final eventId = int.parse(state.pathParameters['eventId']!);
                return EventDetailPage(eventId: eventId);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/contact',
          builder: (context, state) => const ContactPage(),
        ),
      ],
    ),

    // Optional: redirect root to accueil
    GoRoute(
      path: '/',
      redirect: (_, __) => '/home',
    ),
  ],
);


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Logistiscout',
      routerConfig: _router,
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


class _MainNavigation extends StatelessWidget {
  final Widget child;
  const _MainNavigation({required this.child});

  int _locationToIndex(String location) {
    if (location.startsWith('/tents')) return 1;
    if (location.startsWith('/events')) return 2;
    if (location.startsWith('/contact')) return 3;
    return 0; // /accueil (and default)
  }

  String _indexToLocation(int index) {
    switch (index) {
      case 1:
        return '/tents';
      case 2:
        return '/events';
      case 3:
        return '/contact';
      case 0:
      default:
        return '/home';
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final selectedIndex = _locationToIndex(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => context.go(_indexToLocation(index)),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.cabin), label: 'Tentes'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Événements'),
          BottomNavigationBarItem(icon: Icon(Icons.contact_support), label: 'Contact'),
        ],
      ),
    );
  }
}
