class SecuritySettings {
  final bool biometricEnabled;
  final bool intruderPhotosEnabled;
  final bool faceDownLockEnabled;
  final bool decoyVaultEnabled;

  SecuritySettings({
    required this.biometricEnabled,
    required this.intruderPhotosEnabled,
    required this.faceDownLockEnabled,
    required this.decoyVaultEnabled,
  });

  SecuritySettings copyWith({
    bool? biometricEnabled,
    bool? intruderPhotosEnabled,
    bool? faceDownLockEnabled,
    bool? decoyVaultEnabled,
  }) {
    return SecuritySettings(
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      intruderPhotosEnabled: intruderPhotosEnabled ?? this.intruderPhotosEnabled,
      faceDownLockEnabled: faceDownLockEnabled ?? this.faceDownLockEnabled,
      decoyVaultEnabled: decoyVaultEnabled ?? this.decoyVaultEnabled,
    );
  }
}

class CloudSyncSettings {
  final String? defaultProviderId;
  final bool autoSyncEnabled;
  final bool wifiOnlySync;

  CloudSyncSettings({
    this.defaultProviderId,
    required this.autoSyncEnabled,
    required this.wifiOnlySync,
  });

  CloudSyncSettings copyWith({
    String? defaultProviderId,
    bool? autoSyncEnabled,
    bool? wifiOnlySync,
  }) {
    return CloudSyncSettings(
      defaultProviderId: defaultProviderId ?? this.defaultProviderId,
      autoSyncEnabled: autoSyncEnabled ?? this.autoSyncEnabled,
      wifiOnlySync: wifiOnlySync ?? this.wifiOnlySync,
    );
  }
}

enum PlaybackMode { immersive, safe, minimal }

class PlaybackPrivacySettings {
  final PlaybackMode playbackMode;
  final bool showFilenames;
  final bool showMetadata;

  PlaybackPrivacySettings({
    required this.playbackMode,
    required this.showFilenames,
    required this.showMetadata,
  });

  PlaybackPrivacySettings copyWith({
    PlaybackMode? playbackMode,
    bool? showFilenames,
    bool? showMetadata,
  }) {
    return PlaybackPrivacySettings(
      playbackMode: playbackMode ?? this.playbackMode,
      showFilenames: showFilenames ?? this.showFilenames,
      showMetadata: showMetadata ?? this.showMetadata,
    );
  }
}
