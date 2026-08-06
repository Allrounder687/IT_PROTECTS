import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:it_protects/features/vault/presentation/vault_dashboard_screen.dart';

void main() {
  setUpAll(() async {
    await loadAppFonts();
  });

  testGoldens('VaultDashboardScreen - Golden Test', (tester) async {
    final builder = DeviceBuilder()
      ..overrideDevicesForAllScenarios(devices: [
        Device.phone,
        Device.iphone11,
        Device.tabletPortrait,
      ])
      ..addScenario(
        name: 'Default state',
        widget: const ProviderScope(
          child: VaultDashboardScreen(),
        ),
      );

    await tester.pumpDeviceBuilder(builder);
    await screenMatchesGolden(tester, 'vault_dashboard_screen');
  });
}
