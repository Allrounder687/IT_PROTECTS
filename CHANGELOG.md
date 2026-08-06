# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added (Phase 19: Security Settings, Intruder Alerts & Logs UI)
- **Settings Screen Updates**: Added Face-down auto lock toggle and a Playback Mode selector dialog (Immersive, Safe, Minimal).
- **Change PIN Flow**: Created a robust `ChangePinScreen` to verify current PIN before setting a new one.
- **Intruder Logs Screen**: Built `IntruderLogsScreen` providing a detailed view of failed unlock attempts (timestamp, device info, location, photo placeholder), powered by a mock `intruderLogProvider`.
- **Refactoring**: Replaced deprecated `RadioListTile` widgets with standard `ListTile` components for playback mode selection.

### Added (Phase 18: Providers & Cloud Sync UI)
- **Global Sync Indicator**: Implemented `SyncIndicatorWidget` in the `CustomAppBar` to reflect idle, syncing, and error states.
- **Sync Panel**: Added `SyncPanelSheet` (bottom sheet) to show detailed sync queue, last sync time, and last error.
- **Provider Management**: Upgraded `StorageProvidersScreen` to use visually distinct `Card` layouts with `LinearProgressIndicator` for quota tracking, plus clear link/unlink/default buttons.
- **Provider Details**: Built `ProviderDetailScreen` mapping albums and offering manual sync triggers.

### Added (Phase 17: Media Viewer, Safe Send & Trash/Space Saver UI)
- **Immersive HUD**: Added top and bottom app bars to `MediaViewerScreen` offering quick actions: Favorite, Move, Decoy, Safe Send, and Delete. Added file metadata info overlay.
- **Interactive Image Viewer**: Refactored `ImageItemViewer` using `InteractiveViewer` for performant, matrix-based pinch-to-zoom and double-tap zooming.
- **Video Chrome & Safe Send**: Enhanced `VideoItemViewer` with a real scrubber, play/pause, mute toggle, and an animated Safe Send countdown badge.
- **Trash & Space Saver**: Created `TrashScreen` for batch restoring/deleting items and `SpaceSaverScreen` for managing cloud vs. local compression footprints.

### Added (Phase 16: Home / Vault & Albums UX)
- **Vault Dashboard**: Refactored with `CustomAppBar`, dynamic Filter Chips (All, Photos, Videos, Docs, Favorites), and a sleek modern BottomSheet for the floating action button.
- **Albums Experience**: Migrated `AlbumsScreen` grid to utilize the interactive `AlbumCard`. Created a dedicated `AlbumDetailScreen` (via route `/albums/:id`) scoped to individual albums.
- **Component Polish**: Updated `VaultCard` to display real encrypted image thumbnails using `EncryptedGridWidget`.

### Added (Phase 15: Adaptive App Shell & 2026 UI Standards)
- **Adaptive Scaffold**: Refactored `MainScaffold` to automatically pivot between a `NavigationBar` for mobile screens and a `NavigationRail` for tablets/desktops.
- **2026 Design System**: Upgraded `AppTheme` typography using `google_fonts` (`Outfit`).
- **Reusable UI Components**: Built `VaultCard`, `AlbumCard`, `CustomAppBar`, `PrimaryButton`, and `SettingsGroupHeader` with hover micro-animations and scaled dynamics.

### Added (Phase 14: Lock Screen & Auth Shell)
- Refactored core cryptography to generate a random 256-bit Master Key and wrap it with Argon2id PIN derivatives.
- Implemented robust `biometric_storage` integration: Face ID / Fingerprint unwraps the biometric-gated Master Key directly.
- Added Face-Down Auto Lock feature using `sensors_plus` to instantly lock the vault via accelerometer when face down.
- Implemented global "Lock" action in the `MainScaffold` bottom navigation bar.
- Refined the `PinScreen` unlock UX with 6-digit pads, `flutter_animate` shake effects, and a "Forgot PIN?" explanatory dialog.

### Added (Phase 13: Full Onboarding Funnel)
- Implemented `OnboardingScreen` as the starting point for new users.
- Created multi-step onboarding funnel:
  - `CreatePinScreen` (6-digit primary PIN creation).
  - `ConfirmPinScreen` (6-digit PIN confirmation with shake-on-error animation).
  - `OnboardingDecoyScreen` (Introduction to plausible deniability feature).
  - `CreateDecoyPinScreen` & `ConfirmDecoyPinScreen` (6-digit decoy PIN creation).
  - `BiometricSetupScreen` (Optional biometric unlock integration).
  - `CloudProviderSetupScreen` (Optional cloud backup integration during setup).
- Converted legacy `PinScreen` to be strictly an unlock screen.

### Added (Phase 12 - Albums Management)
- Implemented full CRUD functionality for Albums in `LocalVaultRepository` and `AlbumsNotifier`.
- Added dynamic creation bottom sheet for new custom albums.
- Added context menus to rename albums and lock/unlock them interactively.

### Changed (Phase 11 - Media Viewer Wiring)
- Replaced mock video scrubber with real `media_kit` streams for hardware-accelerated playback.
- Wired the decryption pipeline securely into `playbackSessionProvider` using in-memory AES-GCM and `TemporaryFileManager`.
- Connected `ImageItemViewer` to dynamically display the decrypted temporary image files.

### Added (Phase 10 - Decoy Vault Plausible Deniability)
- Introduced `AuthMode` (Real vs Decoy) managed by `authModeProvider`.
- Added rigorous backend filtering using `is_decoy_visible` flags in `LocalVaultRepository`.
- Built `SetupDecoyPinScreen` allowing a secondary PIN to open an entirely separate vault keyspace.

### Added (Phase 8 - Search & Infinite Pagination)
- Developed cursor-based infinite pagination for the main Vault Dashboard via `PaginatedVaultNotifier`.
- Created `SearchNotifier` with Riverpod-based debouncing to instantly filter items as users type.

### Changed (Phase 7.2 - Defensible Security & Lifecycle Cleanup)
- **Zero Telemetry Policy:** Implemented `SecureLogger` to enforce zero analytic/console logging in Release mode, preventing metadata and crash dump leaks.
- **Aggressive Lifecycle Purging:** Implemented `LifecycleCleanupManager` (`WidgetsBindingObserver`) that actively triggers a mass deletion of the temporary cache directory the moment the app enters the background, goes inactive, or detaches.
- **Threat Model Reality:** Updated `security_design.md` to accurately reflect flash memory wear-leveling constraints and that the Master Key is stored wrapped on-disk rather than solely existing in the ether.

### Changed (Phase 7.1 - Secure Playback Sessions)
- **Security Update:** Transitioned media decryption pipeline to `SecurePlaybackSession` temporary file management, circumventing in-memory limitations for `media_kit` and `syncfusion` while aggressively disposing files to minimize plaintext windows.
- Refactored `VideoItemViewer`, `DocItemViewer`, and `ImageItemViewer` to mount secure local file URIs rather than byte arrays.
- Implemented `TemporaryFileManager` using `path_provider` (temporary/cache OS directory) excluded from backups.
- Authored extensive unit tests for secure temporary file creation, byte writing, and permanent cleanup on provider cancellation.

### Added (Phase 7 - Media Viewer System)
- Initialized `media_kit` for hardware-accelerated cross-platform secure video playback.
- Initialized `syncfusion_flutter_pdfviewer` for secure multi-platform document viewing.
- Created `MediaViewerScreen` with `PageView.builder` for seamless swiping between items.
- Built a modular viewer system: `ImageItemViewer` (Pinch-to-zoom), `VideoItemViewer` (Timeline/Scrubber mock), and `DocItemViewer` (Syncfusion PDF skeleton).
- Developed `fullMediaProvider` showcasing an asynchronous in-memory LRU caching architecture for high-resolution decrypted blobs.

### Added (Phase 6 - UI/UX Design System 2026)
- Created 2026-style Material Design 3 theme with Slate & Indigo color palette (`app_theme.dart`).
- Migrated navigation to `StatefulShellRoute` with a responsive bottom navigation bar.
- Redesigned `VaultDashboardScreen` with inline search, animated cloud sync indicator, and `flutter_animate` micro-interactions.

### Added (Phase 5 - Cloud Sync Engine Skeleton)
- Abstracted `StorageProvider` for universal cloud BYOS.
- Implemented `GoogleDriveRepository` using `google_sign_in` and `googleapis`.
- Created `SyncStatusNotifier` and `ActiveCloudProviderNotifier` for state machine management.
- Added `wrapped_content_key` and `iv` to SQLite schemas.
- Implemented Intruder Alert logging via silent front-camera snapshots on unlock failure.
- Implemented `getOrGenerateDecoySalt` foundation for the Decoy Vault.

### Changed (Phase 3 - Architecture & Riverpod Restructure)
- Completely refactored the app into a Clean Architecture (feature-based).
- Decoupled all cryptographic operations from the Presentation layer into the Domain layer.
- Switched to strict `Notifier` and `AsyncNotifier` usage.

### Added (Phase 2 - Local Vault Encrypted Viewing)
- Created the core encryption pipeline (`EncryptionUseCase`) and local SQLite storage (`LocalVaultRepository`).
- Added capability to import and encrypt media from the device gallery.
- Added Zero-Knowledge viewing of encrypted blobs directly in memory.

### Added (Phase 1 - Scaffolding)
- Project scaffold and Onboarding UI.
- Auth routing and initial PIN setup logic via Argon2id.
