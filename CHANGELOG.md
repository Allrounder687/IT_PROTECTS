# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added (Phase 4 - Security & Cryptography)
- Introduced Per-File Content Encryption Keys (CEKs).
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
