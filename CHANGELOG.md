# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

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
