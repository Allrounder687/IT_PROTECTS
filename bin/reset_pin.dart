import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('Clearing secure storage...');
  const storage = FlutterSecureStorage();
  await storage.deleteAll();
  print('Done. Restart the app to create a new PIN.');
}
