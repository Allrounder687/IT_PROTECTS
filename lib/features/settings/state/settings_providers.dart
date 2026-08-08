import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/settings_models.dart';
import '../../providers/state/sync_status_notifier.dart';

final prefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Override in main() after init');
});

final securitySettingsProvider = NotifierProvider<SecuritySettingsNotifier, SecuritySettings>(
  SecuritySettingsNotifier.new,
);

class SecuritySettingsNotifier extends Notifier<SecuritySettings> {
  @override
  SecuritySettings build() {
    final prefs = ref.read(prefsProvider);
    return SecuritySettings(
      biometricEnabled: prefs.getBool('sec_biometric') ?? true,
      intruderPhotosEnabled: prefs.getBool('sec_intruder_photos') ?? false,
      faceDownLockEnabled: prefs.getBool('sec_face_down') ?? true,
      decoyVaultEnabled: prefs.getBool('sec_decoy_enabled') ?? false,
    );
  }

  Future<void> toggleBiometric(bool enabled) async {
    final prefs = ref.read(prefsProvider);
    await prefs.setBool('sec_biometric', enabled);
    state = state.copyWith(biometricEnabled: enabled);
  }

  Future<void> toggleDecoyVault(bool enabled) async {
    final prefs = ref.read(prefsProvider);
    await prefs.setBool('sec_decoy_enabled', enabled);
    state = state.copyWith(decoyVaultEnabled: enabled);
  }

  Future<void> toggleIntruderPhotos(bool enabled) async {
    final prefs = ref.read(prefsProvider);
    await prefs.setBool('sec_intruder_photos', enabled);
    state = state.copyWith(intruderPhotosEnabled: enabled);
  }

  Future<void> toggleFaceDownLock(bool enabled) async {
    final prefs = ref.read(prefsProvider);
    await prefs.setBool('sec_face_down', enabled);
    state = state.copyWith(faceDownLockEnabled: enabled);
  }
}

final cloudSyncSettingsProvider = NotifierProvider<CloudSyncSettingsNotifier, CloudSyncSettings>(
  CloudSyncSettingsNotifier.new,
);

class CloudSyncSettingsNotifier extends Notifier<CloudSyncSettings> {
  @override
  CloudSyncSettings build() {
    final prefs = ref.read(prefsProvider);
    return CloudSyncSettings(
      defaultProviderId: prefs.getString('sync_default_provider'),
      autoSyncEnabled: prefs.getBool('sync_auto') ?? true,
      wifiOnlySync: prefs.getBool('sync_wifi_only') ?? true,
    );
  }

  Future<void> setDefaultProvider(String? providerId) async {
    final prefs = ref.read(prefsProvider);
    if (providerId == null) {
      await prefs.remove('sync_default_provider');
    } else {
      await prefs.setString('sync_default_provider', providerId);
    }
    state = state.copyWith(defaultProviderId: providerId);
  }

  Future<void> toggleAutoSync(bool enabled) async {
    final prefs = ref.read(prefsProvider);
    await prefs.setBool('sync_auto', enabled);
    state = state.copyWith(autoSyncEnabled: enabled);
    if (enabled) {
      ref.read(syncStatusProvider.notifier).markAsQueued();
    }
  }

  Future<void> toggleWifiOnly(bool enabled) async {
    final prefs = ref.read(prefsProvider);
    await prefs.setBool('sync_wifi_only', enabled);
    state = state.copyWith(wifiOnlySync: enabled);
  }
}

final playbackPrivacySettingsProvider = NotifierProvider<PlaybackPrivacySettingsNotifier, PlaybackPrivacySettings>(
  PlaybackPrivacySettingsNotifier.new,
);

class PlaybackPrivacySettingsNotifier extends Notifier<PlaybackPrivacySettings> {
  @override
  PlaybackPrivacySettings build() {
    final prefs = ref.read(prefsProvider);
    final modeIndex = prefs.getInt('play_mode') ?? 1; // Default to safe mode
    final mode = PlaybackMode.values[modeIndex];
    return PlaybackPrivacySettings(
      playbackMode: mode,
      showFilenames: prefs.getBool('play_show_filenames') ?? false,
      showMetadata: prefs.getBool('play_show_metadata') ?? false,
    );
  }

  Future<void> setPlaybackMode(PlaybackMode mode) async {
    final prefs = ref.read(prefsProvider);
    await prefs.setInt('play_mode', mode.index);
    state = state.copyWith(playbackMode: mode);
  }

  Future<void> toggleShowFilenames(bool enabled) async {
    final prefs = ref.read(prefsProvider);
    await prefs.setBool('play_show_filenames', enabled);
    state = state.copyWith(showFilenames: enabled);
  }

  Future<void> toggleShowMetadata(bool enabled) async {
    final prefs = ref.read(prefsProvider);
    await prefs.setBool('play_show_metadata', enabled);
    state = state.copyWith(showMetadata: enabled);
  }
}
