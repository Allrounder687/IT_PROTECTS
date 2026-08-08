import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'settings_providers.dart';

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

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'deviceOs': deviceOs,
    'location': location,
    'photoPath': photoPath,
  };

  factory IntrusionLog.fromJson(Map<String, dynamic> json) => IntrusionLog(
    id: json['id'],
    timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
    deviceOs: json['deviceOs'],
    location: json['location'],
    photoPath: json['photoPath'],
  );
}

class IntruderLogNotifier extends Notifier<List<IntrusionLog>> {
  @override
  List<IntrusionLog> build() {
    final prefs = ref.read(prefsProvider);
    final str = prefs.getString('intruder_logs');
    if (str != null) {
      final List<dynamic> decoded = jsonDecode(str);
      return decoded.map((e) => IntrusionLog.fromJson(e)).toList();
    }
    return [];
  }

  void addLog() {
    final log = IntrusionLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      deviceOs: '${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
      location: 'Unknown Location',
    );
    state = [log, ...state];
    _save();
  }

  void clearLogs() {
    state = [];
    _save();
  }

  void _save() {
    final prefs = ref.read(prefsProvider);
    prefs.setString('intruder_logs', jsonEncode(state.map((e) => e.toJson()).toList()));
  }
}

final intruderLogProvider = NotifierProvider<IntruderLogNotifier, List<IntrusionLog>>(
  IntruderLogNotifier.new,
);
