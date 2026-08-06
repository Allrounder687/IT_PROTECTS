import 'package:flutter_riverpod/flutter_riverpod.dart';

class IntrusionLog {
  final String id;
  final DateTime timestamp;
  final String deviceOs;
  final String? location;
  final String? photoPath;

  const IntrusionLog({
    required this.id,
    required this.timestamp,
    required this.deviceOs,
    this.location,
    this.photoPath,
  });
}

class IntruderLogNotifier extends Notifier<List<IntrusionLog>> {
  @override
  List<IntrusionLog> build() {
    // Mock data for initial UI build
    return [
      IntrusionLog(
        id: '1',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        deviceOs: 'iOS 17.2',
        location: 'Unknown location',
        photoPath: null, // Placeholder for captured photo
      ),
      IntrusionLog(
        id: '2',
        timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
        deviceOs: 'iOS 17.2',
        location: 'Home Network',
        photoPath: 'assets/mock/intruder.jpg', // Normally a file path
      ),
    ];
  }

  void clearLogs() {
    state = [];
  }
}

final intruderLogProvider = NotifierProvider<IntruderLogNotifier, List<IntrusionLog>>(
  IntruderLogNotifier.new,
);
