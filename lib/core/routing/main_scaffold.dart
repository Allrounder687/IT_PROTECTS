import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/state/auth_notifier.dart';
import '../presentation/components/desktop_sidebar.dart';

class MainScaffold extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainScaffold({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 600;

        if (isDesktop) {
          return Scaffold(
            body: Row(
              children: [
                DesktopSidebar(navigationShell: navigationShell),
                Expanded(child: navigationShell),
              ],
            ),
          );
        }

        return Scaffold(
          body: navigationShell,
          bottomNavigationBar: NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (index) {
              if (index == 3) {
                ref.read(authNotifierProvider.notifier).lockVault();
              } else {
                navigationShell.goBranch(
                  index,
                  initialLocation: index == navigationShell.currentIndex,
                );
              }
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.shield_outlined),
                selectedIcon: Icon(Icons.shield),
                label: 'Vault',
              ),
              NavigationDestination(
                icon: Icon(Icons.photo_album_outlined),
                selectedIcon: Icon(Icons.photo_album),
                label: 'Albums',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Settings',
              ),
              NavigationDestination(
                icon: Icon(Icons.lock_outline, color: Colors.redAccent),
                label: 'Lock',
              ),
            ],
          ),
        );
      },
    );
  }
}
