import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;

final temporaryFileManagerProvider = Provider<TemporaryFileManager>((ref) {
  return TemporaryFileManager();
});

class SecurePlaybackSession {
  final String id;
  final File file;
  final Function() onDispose;

  SecurePlaybackSession({
    required this.id,
    required this.file,
    required this.onDispose,
  });

  Future<void> dispose() async {
    await onDispose();
  }
}

class TemporaryFileManager {
  final Uuid _uuid = const Uuid();

  Future<File> createTemporaryFile(String extension) async {
    // We use the application support directory or temporary directory.
    // getTemporaryDirectory() is usually the OS cache dir, which can be wiped,
    // but getApplicationSupportDirectory is private and often excluded from cloud backups on iOS.
    // For maximum privacy, we'll use getTemporaryDirectory which is not backed up.
    final dir = await getTemporaryDirectory();
    
    // Random, non-identifying filename
    final fileName = '${_uuid.v4()}$extension';
    final filePath = p.join(dir.path, fileName);
    
    return File(filePath);
  }

  Future<void> writeBytes(File file, List<int> bytes) async {
    await file.writeAsBytes(bytes, flush: true);
  }

  Future<void> deleteFile(File file) async {
    if (await file.exists()) {
      // In a real high-security app, you might try to write zeros over the file first
      // before deleting it, though flash storage wear-leveling makes this imperfect.
      
      // Simple secure overwrite attempt
      final length = await file.length();
      final zeros = List.filled(1024, 0); // small buffer
      
      try {
        final raf = await file.open(mode: FileMode.write);
        int written = 0;
        while (written < length) {
          final toWrite = (length - written > zeros.length) ? zeros.length : length - written;
          await raf.writeFrom(zeros, 0, toWrite);
          written += toWrite;
        }
        await raf.close();
      } catch (e) {
        // Overwrite failed, proceed to delete anyway
      }
      
      await file.delete();
    }
  }
}
