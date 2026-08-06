import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:it_protects/features/albums/presentation/albums_screen.dart';

void main() {
  setUpAll(() async {
    await loadAppFonts();
  });

  testGoldens('AlbumsScreen - Golden Test', (tester) async {
    final builder = DeviceBuilder()
      ..overrideDevicesForAllScenarios(devices: [
        Device.phone,
        Device.iphone11,
      ])
      ..addScenario(
        name: 'Default state',
        widget: const ProviderScope(
          child: AlbumsScreen(),
        ),
      );

    await tester.pumpDeviceBuilder(builder);
    await screenMatchesGolden(tester, 'albums_screen');
  });
}
