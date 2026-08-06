import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import '../data/auth_repository.dart';
import '../domain/auth_use_case.dart';

enum AuthState { locked, authenticating, unlocked, error }

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    return AuthState.locked;
  }

  Future<void> unlockVault(String pin) async {
    state = AuthState.authenticating;
    try {
      final authUseCase = ref.read(authUseCaseProvider);
      final authRepo = ref.read(authRepositoryProvider);

      final salt = await authRepo.getOrGenerateSalt();
      final masterKey = await authUseCase.deriveMasterKey(pin, salt);
      final masterKeyBytes = await masterKey.extractBytes();
      
      await authRepo.saveMasterKey(masterKeyBytes);
      
      state = AuthState.unlocked;
    } catch (e) {
      await _logIntruderAlert();
      state = AuthState.error;
    }
  }

  Future<void> _logIntruderAlert() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      
      final controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      
      await controller.initialize();
      final image = await controller.takePicture();
      await controller.dispose();
      
      // The image is saved to a temporary directory. 
      // In a full implementation, we'd save this path to the DB's intrusion_logs table.
      print('Intruder snapshot saved to: ${image.path}');
    } catch (e) {
      print('Failed to take intruder snapshot: $e');
    }
  }
}
