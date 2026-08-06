import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'core/security/lifecycle_cleanup_manager.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  runApp(
    const ProviderScope(
      child: ItProtectsApp(),
    ),
  );
}

class ItProtectsApp extends ConsumerWidget {
  const ItProtectsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LifecycleCleanupManager(
      child: MaterialApp.router(
        title: 'IT PROTECTS',
        theme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
