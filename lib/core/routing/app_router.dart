import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/state/auth_notifier.dart';
import '../../features/auth/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/pin_screen.dart';
import '../../features/auth/presentation/create_pin_screen.dart';
import '../../features/auth/presentation/confirm_pin_screen.dart';
import '../../features/auth/presentation/onboarding_decoy_screen.dart';
import '../../features/auth/presentation/create_decoy_pin_screen.dart';
import '../../features/auth/presentation/confirm_decoy_pin_screen.dart';
import '../../features/auth/presentation/biometric_setup_screen.dart';
import '../../features/auth/presentation/cloud_provider_setup_screen.dart';
import '../../features/vault/presentation/vault_dashboard_screen.dart';
import '../../features/albums/presentation/albums_screen.dart';
import '../../features/albums/presentation/album_detail_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/settings/presentation/storage_providers_screen.dart';
import '../../features/settings/presentation/provider_detail_screen.dart';
import '../../features/settings/presentation/setup_decoy_pin_screen.dart';
import '../../features/settings/presentation/space_saver_screen.dart';
import '../../features/settings/presentation/change_pin_screen.dart';
import '../../features/settings/presentation/intruder_logs_screen.dart';
import '../../features/trash/presentation/trash_screen.dart';
import '../../features/viewer/presentation/media_viewer_screen.dart';
import '../../features/documents/presentation/document_edit_screen.dart';
import '../../features/documents/presentation/document_viewer_screen.dart';
import '../../features/documents/domain/document_template.dart';
import 'main_scaffold.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  
  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (previous != next) {
        notifyListeners();
      }
    });
  }
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      
      if (authState == AuthState.locked) {
        if (!state.matchedLocation.startsWith('/setup') && state.matchedLocation != '/') {
          return '/setup-pin';
        }
      }
      return null;
    },
    routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/setup-pin',
      builder: (context, state) => const PinScreen(),
    ),
    GoRoute(
      path: '/setup-pin/create',
      builder: (context, state) => const CreatePinScreen(),
    ),
    GoRoute(
      path: '/setup-pin/confirm',
      builder: (context, state) {
        final initialPin = state.extra as String? ?? '';
        return ConfirmPinScreen(initialPin: initialPin);
      },
    ),
    GoRoute(
      path: '/setup-decoy',
      builder: (context, state) => const OnboardingDecoyScreen(),
    ),
    GoRoute(
      path: '/setup-decoy/pin',
      builder: (context, state) => const CreateDecoyPinScreen(),
    ),
    GoRoute(
      path: '/setup-decoy/confirm',
      builder: (context, state) {
        final initialPin = state.extra as String? ?? '';
        return ConfirmDecoyPinScreen(initialPin: initialPin);
      },
    ),
    GoRoute(
      path: '/setup-biometrics',
      builder: (context, state) => const BiometricSetupScreen(),
    ),
    GoRoute(
      path: '/setup-cloud',
      builder: (context, state) => const CloudProviderSetupScreen(),
    ),
    GoRoute(
      path: '/viewer/:index',
      builder: (context, state) {
        final index = int.tryParse(state.pathParameters['index'] ?? '0') ?? 0;
        final isDirect = state.uri.queryParameters['isDirect'] == 'true';
        return MediaViewerScreen(initialIndex: index, isDirectItemId: isDirect);
      },
    ),
    GoRoute(
      path: '/document/new',
      builder: (context, state) => const DocumentEditScreen(),
    ),
    GoRoute(
      path: '/document/viewer/:itemId',
      builder: (context, state) {
        final itemId = state.pathParameters['itemId']!;
        return DocumentViewerScreen(itemId: itemId);
      },
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainScaffold(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/vault',
              builder: (context, state) => const VaultDashboardScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/albums',
              builder: (context, state) => const AlbumsScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (context, state) {
                    final id = state.pathParameters['id']!;
                    return AlbumDetailScreen(albumId: id);
                  },
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
              routes: [
                GoRoute(
                  path: 'providers',
                  builder: (context, state) => const StorageProvidersScreen(),
                  routes: [
                    GoRoute(
                      path: ':id',
                      builder: (context, state) {
                        final id = state.pathParameters['id']!;
                        return ProviderDetailScreen(providerId: id);
                      },
                    ),
                  ],
                ),
                GoRoute(
                  path: 'change-pin',
                  builder: (context, state) => const ChangePinScreen(),
                ),
                GoRoute(
                  path: 'intruder-logs',
                  builder: (context, state) => const IntruderLogsScreen(),
                ),
                GoRoute(
                  path: 'setup-decoy',
                  builder: (context, state) => const SetupDecoyPinScreen(),
                ),
                GoRoute(
                  path: 'space-saver',
                  builder: (context, state) => const SpaceSaverScreen(),
                ),
                GoRoute(
                  path: 'trash',
                  builder: (context, state) => const TrashScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);
});
