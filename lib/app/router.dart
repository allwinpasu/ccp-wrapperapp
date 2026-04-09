import 'package:ccp_app/features/auth/presentation/screens/login_screen.dart';
import 'package:ccp_app/features/auth/presentation/screens/register_screen.dart';
import 'package:ccp_app/features/home/presentation/screens/home_screen.dart';
import 'package:go_router/go_router.dart';
import '../features/settings/presentation/pages/settings_screen.dart';
import '../features/settings/presentation/pages/profile_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/register',
    routes: [
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      // GoRoute(
      //   path: '/profile',
      //   name: 'profile',
      //   builder: (context, state) => const ProfileScreen(),
      // ),
    ],
  );
}
