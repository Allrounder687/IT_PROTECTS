import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'features/settings/state/settings_providers.dart';
import 'core/security/lifecycle_cleanup_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
  MediaKit.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1280, 800),
      minimumSize: Size(800, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(
    ProviderScope(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
      ],
      child: const ItProtectsApp(),
    ),
  );
}

class ItProtectsApp extends ConsumerWidget {
  const ItProtectsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    return LifecycleCleanupManager(
      child: MaterialApp.router(
        title: 'IT PROTECTS',
        theme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
            return Scaffold(
              body: Column(
                children: [
                  Container(
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppTheme.background,
                      border: Border(bottom: BorderSide(color: Colors.white10, width: 1)),
                    ),
                    child: const WindowCaption(
                      brightness: Brightness.dark,
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                  Expanded(child: child ?? const SizedBox.shrink()),
                ],
              ),
            );
          }
          return child ?? const SizedBox.shrink();
        },
      ),
    );
  }
}
