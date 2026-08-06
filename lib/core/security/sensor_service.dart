import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';

final sensorServiceProvider = Provider<SensorService>((ref) {
  return SensorService();
});

class SensorService {
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  final _faceDownController = StreamController<bool>.broadcast();
  
  Stream<bool> get faceDownStream => _faceDownController.stream;

  void startListening() {
    if (_accelerometerSubscription != null) return;
    
    // sensors_plus is not supported on Windows/Linux/macOS out of the box in the same way.
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return;
    }
    
    try {
      _accelerometerSubscription = accelerometerEventStream().listen((AccelerometerEvent event) {
        // Z axis approaches -9.8 when face down on a flat surface.
        // We use -8.0 as a threshold to allow for slight tilts.
        if (event.z < -8.0) {
          _faceDownController.add(true);
        }
      }, onError: (e) {
        // Ignore errors if sensors are unavailable
      });
    } catch (e) {
      // Ignore initialization errors
    }
  }

  void stopListening() {
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
  }

  void dispose() {
    stopListening();
    _faceDownController.close();
  }
}
