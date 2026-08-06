import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:it_protects/features/viewer/data/temporary_file_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  setUpAll(() {
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return '.';
    });
  });

  group('TemporaryFileManager Secure Playback Tests', () {
    late TemporaryFileManager manager;

    setUp(() {
      manager = TemporaryFileManager();
    });

    test('creates file with correct extension', () async {
      final file = await manager.createTemporaryFile('.mp4');
      
      expect(file.path.endsWith('.mp4'), isTrue);
      // Ensure file doesn't exist yet until written
      expect(await file.exists(), isFalse);
    });

    test('writes bytes and securely deletes file', () async {
      final file = await manager.createTemporaryFile('.txt');
      await manager.writeBytes(file, [1, 2, 3]);

      expect(await file.exists(), isTrue);
      expect(await file.length(), 3);

      await manager.deleteFile(file);

      expect(await file.exists(), isFalse);
    });

    test('SecurePlaybackSession calls delete on dispose', () async {
      final file = await manager.createTemporaryFile('.pdf');
      await manager.writeBytes(file, [1, 2, 3]);

      final session = SecurePlaybackSession(
        id: '123',
        file: file,
        onDispose: () async {
          await manager.deleteFile(file);
        },
      );

      expect(await session.file.exists(), isTrue);

      await session.dispose();

      expect(await session.file.exists(), isFalse);
    });
  });
}
