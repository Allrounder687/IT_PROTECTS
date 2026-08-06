import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:biometric_storage/biometric_storage.dart';
import '../data/auth_repository.dart';
import '../domain/auth_use_case.dart';
import '../../settings/state/settings_providers.dart';
import '../../../core/providers/auth_mode_provider.dart';
import '../../../core/providers/session_provider.dart';
import '../../vault/data/local_vault_repository.dart';

enum AuthState { locked, authenticating, unlocked, error }

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class AuthNotifier extends Notifier<AuthState> {
  static const _biometricKeyName = 'master_key_biometric';

  @override
  AuthState build() {
    return AuthState.locked;
  }

  Future<void> createPrimaryPin(String pin) async {
    state = AuthState.authenticating;
    try {
      final authUseCase = ref.read(authUseCaseProvider);
      final authRepo = ref.read(authRepositoryProvider);

      final salt = await authRepo.getOrGenerateSalt();
      final newHash = await authUseCase.hashPin(pin, salt);
      await authRepo.savePinHash(newHash);
      
      // Generate a new random master key
      final masterKeyBytes = await authUseCase.generateRandomKey();
      
      // Derive KEK from PIN
      final kek = await authUseCase.deriveKek(pin, salt);
      
      // Wrap Master Key with KEK and save
      final wrappedKey = await authUseCase.wrapMasterKey(masterKeyBytes, kek);
      await authRepo.saveWrappedMasterKey(wrappedKey);
      
      // Store raw master key in session
      ref.read(sessionProvider.notifier).state = masterKeyBytes;
      
      ref.read(authModeProvider.notifier).state = AuthMode.real;
      state = AuthState.unlocked;
    } catch (e) {
      state = AuthState.error;
    }
  }

  Future<void> createDecoyPin(String pin) async {
    try {
      final authUseCase = ref.read(authUseCaseProvider);
      final authRepo = ref.read(authRepositoryProvider);

      final salt = await authRepo.getOrGenerateDecoySalt();
      final newHash = await authUseCase.hashPin(pin, salt);
      await authRepo.saveDecoyPinHash(newHash);
      
      // Generate a new random decoy master key
      final decoyMasterKeyBytes = await authUseCase.generateRandomKey();
      
      // Derive Decoy KEK from PIN
      final decoyKek = await authUseCase.deriveKek(pin, salt);
      
      // Wrap Decoy Master Key with Decoy KEK and save
      final wrappedDecoyKey = await authUseCase.wrapMasterKey(decoyMasterKeyBytes, decoyKek);
      await authRepo.saveWrappedDecoyMasterKey(wrappedDecoyKey);
      
      // Update settings
      ref.read(securitySettingsProvider.notifier).toggleDecoyVault(true);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> unlockVault(String pin) async {
    state = AuthState.authenticating;
    try {
      final authUseCase = ref.read(authUseCaseProvider);
      final authRepo = ref.read(authRepositoryProvider);

      final storedPinHash = await authRepo.getPinHash();
      final salt = await authRepo.getOrGenerateSalt();

      if (storedPinHash == null) {
        state = AuthState.error;
        return;
      }

      // Verification mode
      final enteredHash = await authUseCase.hashPin(pin, salt);
      if (enteredHash == storedPinHash) {
        // Real PIN matches
        final kek = await authUseCase.deriveKek(pin, salt);
        final wrappedKey = await authRepo.getWrappedMasterKey();
        
        if (wrappedKey != null) {
          final masterKeyBytes = await authUseCase.unwrapMasterKey(wrappedKey, kek);
          ref.read(sessionProvider.notifier).state = masterKeyBytes;
          
          ref.read(authModeProvider.notifier).state = AuthMode.real;
          state = AuthState.unlocked;
          return;
        }
      }

      // Check Decoy PIN
      final securitySettings = ref.read(securitySettingsProvider);
      if (securitySettings.decoyVaultEnabled) {
        final storedDecoyPinHash = await authRepo.getDecoyPinHash();
        if (storedDecoyPinHash != null) {
          final decoySalt = await authRepo.getOrGenerateDecoySalt();
          final enteredDecoyHash = await authUseCase.hashPin(pin, decoySalt);
          if (enteredDecoyHash == storedDecoyPinHash) {
            // Decoy PIN matches
            final decoyKek = await authUseCase.deriveKek(pin, decoySalt);
            final wrappedDecoyKey = await authRepo.getWrappedDecoyMasterKey();
            
            if (wrappedDecoyKey != null) {
              final decoyMasterKeyBytes = await authUseCase.unwrapMasterKey(wrappedDecoyKey, decoyKek);
              ref.read(sessionProvider.notifier).state = decoyMasterKeyBytes;
              
              ref.read(authModeProvider.notifier).state = AuthMode.decoy;
              state = AuthState.unlocked;
              return;
            }
          }
        }
      }

      await _logIntruderAlert();
      state = AuthState.error;
    } catch (e) {
      await _logIntruderAlert();
      state = AuthState.error;
    }
  }

  Future<void> enrollBiometrics() async {
    try {
      final masterKeyBytes = ref.read(sessionProvider);
      if (masterKeyBytes == null) throw Exception("Vault must be unlocked to enroll biometrics");
      
      final storageFile = await BiometricStorage().getStorage(
        _biometricKeyName,
        options: StorageFileInitOptions(
          authenticationValidityDurationSeconds: -1, 
          authenticationRequired: true,
        ),
      );
      
      // Store the master key as a comma-separated string of bytes
      final keyString = masterKeyBytes.join(',');
      await storageFile.write(keyString);
      
      ref.read(securitySettingsProvider.notifier).toggleBiometric(true);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> unlockWithBiometrics() async {
    state = AuthState.authenticating;
    try {
      final storageFile = await BiometricStorage().getStorage(
        _biometricKeyName,
        options: StorageFileInitOptions(
          authenticationValidityDurationSeconds: -1, 
          authenticationRequired: true,
        ),
      );
      
      final keyString = await storageFile.read();
      if (keyString != null && keyString.isNotEmpty) {
        final masterKeyBytes = keyString.split(',').map(int.parse).toList();
        ref.read(sessionProvider.notifier).state = masterKeyBytes;
        ref.read(authModeProvider.notifier).state = AuthMode.real;
        state = AuthState.unlocked;
      } else {
        throw Exception("No biometric key found");
      }
    } on AuthException catch (e) {
      if (e.code.toString().contains('canceled')) {
        state = AuthState.error;
        return;
      }
      
      // Biometric set changed or failed.
      try {
        final storageFile = await BiometricStorage().getStorage(_biometricKeyName);
        await storageFile.delete();
      } catch (_) {}
      ref.read(securitySettingsProvider.notifier).toggleBiometric(false);
      state = AuthState.error;
    } catch (e) {
      state = AuthState.error;
    }
  }

  void lockVault() {
    ref.read(sessionProvider.notifier).state = null;
    state = AuthState.locked;
  }

  Future<void> resetVault() async {
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final vaultRepo = ref.read(localVaultRepositoryProvider);
      
      try {
        await vaultRepo.deleteVault();
      } catch (_) {
        // Ignore errors deleting vault to guarantee secure storage is wiped
      }
      
      await authRepo.clearAll();
      
      final prefs = ref.read(prefsProvider);
      await prefs.clear();
      
      ref.read(sessionProvider.notifier).state = null;
      ref.read(authModeProvider.notifier).state = AuthMode.real;
      
      state = AuthState.locked;
    } catch (e) {
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
      await controller.takePicture();
      await controller.dispose();
    } catch (e) {
      // Ignore errors for intruder snap
    }
  }
}
