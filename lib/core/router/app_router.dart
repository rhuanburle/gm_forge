import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_service.dart';
import '../../features/adventure/presentation/pages/dashboard_page.dart';
import '../../features/adventure/presentation/pages/adventure_editor_page.dart';
import '../../features/adventure/presentation/pages/adventure_play_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';

/// App Router configuration using go_router with auth redirect
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = ref.read(isLoggedInProvider);
      final isLoggingIn = state.matchedLocation == '/login';

      // If not logged in and not on login page, redirect to login
      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }

      // If logged in and on login page, redirect to home
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
        path: '/adventure/play/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return AdventurePlayPage(adventureId: id);
        },
      ),
    ],
  );
});

/// Legacy appRouter for backward compatibility during migration
final appRouter = GoRouter(
  initialLocation: '/',
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
      path: '/adventure/play/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return AdventurePlayPage(adventureId: id);
      },
    ),
  ],
);
