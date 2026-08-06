# PrivateVault (IT PROTECTS)

A client-side encrypted vault backed by free cloud providers (Google Drive, Dropbox, OneDrive, etc.). PrivateVault replaces subscription-based photo vaults with a fully open, zero-knowledge, BYOS (Bring Your Own Storage) model.

## Completed Phases

### 1. Project Scaffolding & Onboarding UI
* Scaffolded a clean, dark-themed Flutter application.
* Created the Onboarding flow and the PIN Setup screen.
* Established the core Riverpod and GoRouter dependencies.

### 2. Architectural Restructure (Clean Architecture)
* Refactored the entire application into a strict 2026 feature-first Clean Architecture.
* Separated logic into `presentation`, `state`, `domain`, and `data` layers.
* Removed all cryptography and database logic from the UI.
* Switched entirely to `Notifier` and `AsyncNotifier` structures.

### 3. Core Cryptography & Database
* Implemented **Argon2id** key derivation (32MB memory, 2 iterations, 2 lanes) to safely derive a 256-bit Master Key from a 4-digit PIN.
* Integrated `flutter_secure_storage` to safely persist cryptographic salts and Master Keys.
* Initialized `sqflite_sqlcipher` using the 256-bit Database Key and set up the local schema (Albums, Media Items, and Intrusion Logs).

### 5. Cloud Sync & Provider Architecture
* Abstracted `StorageProvider` for universal BYOS connectivity.
* Added settings to choose and persist default Cloud Sync Providers.

### 8. Search & Infinite Pagination
* Upgraded Vault Dashboard with riverpod-based cursor infinite scrolling and search debouncing.

### 10. Decoy Vault & Plausible Deniability
* Complete secondary keyspace implementation routing users to a "fake" vault when they enter a secondary decoy PIN.
* Seamlessly hides real encrypted blobs by filtering DB results purely based on `AuthMode`.

### 11. Media Viewer Wiring
* Fully functional media viewer capable of hardware-accelerated decryption streams.
* Bound to `media_kit` real player events for a perfectly synced scrubbing UI.

### 12. Albums Management
* First-class Album objects managed via SQLite CRUD.
* Long-press contextual menus to dynamically rename albums and toggle lock states.
