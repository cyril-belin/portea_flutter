import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'shell_scaffold.dart';
import '../../features/onboarding/presentation/screens/onboarding_welcome_screen.dart';
import '../../features/onboarding/presentation/screens/sign_in_screen.dart';
import '../../features/onboarding/presentation/screens/kennel_setup_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_notifications_screen.dart';
import '../../features/onboarding/presentation/view_models/onboarding_view_model.dart';

import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/breeders/presentation/screens/breeders_list_screen.dart';
import '../../features/breeders/presentation/screens/breeder_profile_screen.dart';
import '../../features/litters/presentation/screens/litters_history_screen.dart';
import '../../features/litters/presentation/screens/litter_declaration_screen.dart';
import '../../features/litters/presentation/screens/litter_detail_screen.dart';

import '../../features/puppies/presentation/screens/puppy_batch_creation_screen.dart';
import '../../features/puppies/presentation/screens/group_weighing_screen.dart';
import '../../features/puppies/presentation/screens/puppy_file_screen.dart';
import '../../features/puppies/presentation/screens/add_care_screen.dart';

import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/settings/presentation/screens/documents_screen.dart';
import '../../features/settings/presentation/screens/portea_premium_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

GoRouter createRouter(OnboardingViewModel onboardingViewModel) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/dashboard',
    refreshListenable: onboardingViewModel,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final isOnboarding = loc.startsWith('/onboarding');

      if (!onboardingViewModel.isAuthenticated) {
        // Not authenticated: only welcome + login are accessible, everything
        // else (dashboard, app tabs, setup, notifications) bounces to welcome.
        if (loc == '/onboarding/welcome' || loc == '/onboarding/login') {
          return null;
        }
        return '/onboarding/welcome';
      }

      // Authenticated + kennel exists -> dashboard, never stay on onboarding.
      if (onboardingViewModel.isOnboardingCompleted && isOnboarding) {
        return '/dashboard';
      }

      // Authenticated but no kennel yet -> kennel setup (skip welcome/login).
      if (onboardingViewModel.needsKennelSetup && loc != '/onboarding/setup') {
        return '/onboarding/setup';
      }

      return null;
    },
    routes: [
      // Onboarding screens
      GoRoute(
        path: '/onboarding/welcome',
        builder: (context, state) => const OnboardingWelcomeScreen(),
      ),
      GoRoute(
        path: '/onboarding/login',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/onboarding/setup',
        builder: (context, state) => const KennelSetupScreen(),
      ),
      GoRoute(
        path: '/onboarding/notifications',
        builder: (context, state) => const OnboardingNotificationsScreen(),
      ),

      // Shell tabs navigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ShellScaffold(navigationShell: navigationShell);
        },
        branches: [
          // Branch 1: Accueil
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          // Branch 2: Reproducteurs
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/breeders',
                builder: (context, state) => const BreedersListScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const BreederProfileScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final id = int.tryParse(state.pathParameters['id'] ?? '');
                      return BreederProfileScreen(id: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          // Branch 3: Portées
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/litters',
                builder: (context, state) => const LittersHistoryScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) =>
                        const LitterDeclarationScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final id =
                          int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
                      return LitterDetailScreen(id: id);
                    },
                    routes: [
                      GoRoute(
                        path: 'puppies/batch',
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (context, state) {
                          final id =
                              int.tryParse(state.pathParameters['id'] ?? '') ??
                              0;
                          return PuppyBatchCreationScreen(litterId: id);
                        },
                      ),
                      GoRoute(
                        path: 'weighing',
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (context, state) {
                          final id =
                              int.tryParse(state.pathParameters['id'] ?? '') ??
                              0;
                          return GroupWeighingScreen(litterId: id);
                        },
                      ),
                      GoRoute(
                        path: 'care',
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (context, state) {
                          final id =
                              int.tryParse(state.pathParameters['id'] ?? '') ??
                              0;
                          final puppyIdStr =
                              state.uri.queryParameters['puppyId'];
                          final puppyId = puppyIdStr != null
                              ? int.tryParse(puppyIdStr)
                              : null;
                          return AddCareScreen(litterId: id, puppyId: puppyId);
                        },
                      ),
                      GoRoute(
                        path: 'documents',
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (context, state) {
                          final id =
                              int.tryParse(state.pathParameters['id'] ?? '') ??
                              0;
                          return DocumentsScreen(litterId: id);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          // Branch 4: Réglages
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),

      // Other root level push routes
      GoRoute(
        path: '/puppies/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return PuppyFileScreen(id: id);
        },
      ),
      GoRoute(
        path: '/premium',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PorteaPremiumScreen(),
      ),
    ],
  );
}
