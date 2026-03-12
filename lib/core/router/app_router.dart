import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_service.dart';
import '../../features/adventure/presentation/pages/dashboard_page.dart';
import '../../features/adventure/presentation/pages/adventure_editor_page.dart';
import '../../features/adventure/presentation/pages/adventure_generator_page.dart';
import '../../features/adventure/presentation/pages/location_editor_page.dart';
import '../../features/adventure/presentation/pages/adventure_play_page.dart';
import '../../features/adventure/presentation/pages/campaign_hub_page.dart';
import '../../features/adventure/presentation/pages/session_prep_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';

CustomTransitionPage<void> _fadeTransition(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 200),
    reverseTransitionDuration: const Duration(milliseconds: 150),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

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
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return _fadeTransition(state, AdventureEditorPage(adventureId: id));
        },
      ),
      GoRoute(
        path: '/adventure/:id/location/:locationId',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final locationId = state.pathParameters['locationId'] ?? '';
          return _fadeTransition(
            state,
            LocationEditorPage(adventureId: id, locationId: locationId),
          );
        },
      ),
      GoRoute(
        path: '/adventure/:id/generate',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return _fadeTransition(state, AdventureGeneratorPage(adventureId: id));
        },
      ),
      GoRoute(
        path: '/adventure/play/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return _fadeTransition(state, AdventurePlayPage(adventureId: id));
        },
      ),
      GoRoute(
        path: '/campaign/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return _fadeTransition(state, CampaignHubPage(campaignId: id));
        },
      ),
      GoRoute(
        path: '/adventure/:id/session/new',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return _fadeTransition(state, SessionPrepPage(adventureId: id));
        },
      ),
      GoRoute(
        path: '/adventure/:id/session/:sessionId',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final sessionId = state.pathParameters['sessionId'] ?? '';
          return _fadeTransition(
            state,
            SessionPrepPage(adventureId: id, sessionId: sessionId),
          );
        },
      ),
    ],
  );
});
