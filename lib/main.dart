import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logistiscout/core/legal_constants.dart';
import 'package:logistiscout/ui/pages/account/group_settings_page.dart';
import 'package:logistiscout/ui/pages/auth/auth_gate.dart';
import 'package:logistiscout/ui/pages/contact/contact_page.dart';
import 'package:logistiscout/ui/pages/event/evenement_detail_page.dart';
import 'package:logistiscout/ui/pages/event/evenement_page.dart';
import 'package:logistiscout/ui/pages/home_page.dart';
import 'package:logistiscout/ui/pages/auth/login_page.dart';
import 'package:logistiscout/ui/pages/legal/terms_page.dart';
import 'package:logistiscout/ui/pages/tent/tente_detail_page.dart';
import 'package:logistiscout/ui/pages/tent/tentes_page.dart';

final _router = GoRouter(
  initialLocation: '/bootstrap',
  routes: [
    GoRoute(path: '/bootstrap', builder: (context, state) => const AuthGate()),
    GoRoute(
      path: '/login',
      builder: (context, state) => LoginPage(
        termsVersion: kTermsVersion,
        onLogin: () => context.go('/home'),
      ),
    ),
    GoRoute(
      path: '/terms',
      builder: (context, state) {
        final user = state.uri.queryParameters['user'] ?? '';
        final next = state.uri.queryParameters['next'] ?? '/home';
        return TermsPage(
          termsVersion: kTermsVersion,
          userIdentity: user,
          nextRoute: next,
        );
      },
    ),
    GoRoute(
      path: '/account',
      builder: (context, state) => const GroupSettingsPage(),
    ),
    // Bottom-nav shell
    ShellRoute(
      builder: (context, state, child) => _MainNavigation(child: child),
      routes: [
        GoRoute(path: '/home', builder: (context, state) => const HomePage()),
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
    GoRoute(path: '/', redirect: (_, __) => '/home'),
  ],
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(ProviderScope(child: MyApp()));
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

class _MainNavigation extends StatefulWidget {
  final Widget child;
  const _MainNavigation({required this.child});

  @override
  State<_MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<_MainNavigation> {
  String? _previousLocation;
  int _slideDirection = 1;

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

  int _pathDepth(String location) {
    return Uri.parse(location).pathSegments.length;
  }

  int _computeDirection(String previousLocation, String currentLocation) {
    final previousIndex = _locationToIndex(previousLocation);
    final currentIndex = _locationToIndex(currentLocation);
    if (currentIndex != previousIndex) {
      return currentIndex > previousIndex ? 1 : -1;
    }

    final previousDepth = _pathDepth(previousLocation);
    final currentDepth = _pathDepth(currentLocation);
    if (currentDepth > previousDepth) {
      return 1;
    }
    if (currentDepth < previousDepth) {
      return -1;
    }
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final selectedIndex = _locationToIndex(location);

    if (_previousLocation == null) {
      _previousLocation = location;
    } else if (_previousLocation != location) {
      _slideDirection = _computeDirection(_previousLocation!, location);
      _previousLocation = location;
    }

    return Scaffold(
      body: TweenAnimationBuilder<double>(
        key: ValueKey(location),
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOutCubicEmphasized,
        tween: Tween<double>(begin: 0, end: 1),
        child: widget.child,
        builder: (context, progress, child) {
          final width = MediaQuery.sizeOf(context).width;
          final dx = (1 - progress) * 0.03 * _slideDirection;
          return ClipRect(
            child: Opacity(
              opacity: 0.92 + (0.08 * progress),
              child: Transform.translate(
                offset: Offset(dx * width, 0),
                child: child,
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => context.go(_indexToLocation(index)),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.cabin), label: 'Tentes'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Événements'),
          BottomNavigationBarItem(
            icon: Icon(Icons.contact_support),
            label: 'Contact',
          ),
        ],
      ),
    );
  }
}
