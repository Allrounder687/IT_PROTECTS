# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

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
