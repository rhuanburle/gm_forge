import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_service.dart';
import '../../features/adventure/presentation/pages/dashboard_page.dart';
import '../../features/adventure/presentation/pages/adventure_editor_page.dart';
import '../../features/adventure/presentation/pages/location_editor_page.dart';
import '../../features/adventure/presentation/pages/adventure_play_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final isLoggedIn = ref.watch(isLoggedInProvider);
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggingIn = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }

      if (isLoggedIn && isLoggingIn) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/', builder: (context, state) => const DashboardPage()),
      GoRoute(
        path: '/adventure/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return AdventureEditorPage(adventureId: id);
        },
      ),
      GoRoute(
        path: '/adventure/:id/location/:locationId',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final locationId = state.pathParameters['locationId'] ?? '';
          return LocationEditorPage(adventureId: id, locationId: locationId);
        },
      ),
      GoRoute(
        path: '/adventure/play/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return AdventurePlayPage(adventureId: id);
        },
      ),
    ],
  );
});
