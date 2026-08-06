import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:it_protects/features/settings/presentation/settings_screen.dart';
import 'package:it_protects/features/settings/state/settings_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    await loadAppFonts();
  });

  testGoldens('SettingsScreen - Golden Test', (tester) async {
    // Need to mock SharedPreferences for the settings providers
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final builder = DeviceBuilder()
      ..overrideDevicesForAllScenarios(devices: [
        Device.phone,
        Device.iphone11,
      ])
      ..addScenario(
        name: 'Default state',
        widget: ProviderScope(
          overrides: [
            prefsProvider.overrideWithValue(prefs),
          ],
          child: const SettingsScreen(),
        ),
      );

    await tester.pumpDeviceBuilder(builder);
    await screenMatchesGolden(tester, 'settings_screen');
  });
}
