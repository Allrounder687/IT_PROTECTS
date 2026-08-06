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

### 4. Security & Per-File Encryption (CEK)
* Re-engineered the cipher to use **Per-File Content Encryption Keys (CEKs)** via AES-256-GCM.
* Implemented the Vault Media Service to read raw image bytes, encrypt them with a unique CEK, wrap the CEK with the Master Key, and save the cipher blob to disk.
* Built the `EncryptedGridWidget` to decrypt and render these blobs purely in volatile memory (Zero-Knowledge Display).
* Groundwork laid for **Decoy Vault** (Fake PIN) and **Intruder Logging** (Silent Camera Snapshots on failed unlock).
