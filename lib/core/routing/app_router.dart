import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/pin_screen.dart';
import '../../features/vault/presentation/vault_dashboard_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
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
      path: '/vault',
      builder: (context, state) => const VaultDashboardScreen(),
    ),
  ],
);
