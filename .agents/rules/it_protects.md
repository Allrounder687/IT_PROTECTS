# IT PROTECTS - Architectural Guidelines & Security Constraints

When working on the IT_PROTECTS project, all agents MUST adhere to the following rules and constraints:

## 1. Security & Privacy Threat Model
- **No Plaintext Leaks:** Never send plaintext media, filenames, keys, or user data to Google Drive, Dropbox, OneDrive, telemetry logs, analytics, crash reports, or public cache directories.
- **Secure Logging:** Use the custom `SecureLogger` class. Do not use standard `print()` or `log()` if it might leak metadata in release mode.
- **Data at Rest & Flash Wear-Leveling:** Do not guarantee users that encryption keys "never touch the disk." SSD/eMMC flash wear-leveling makes this impossible to guarantee. Treat local device storage honestly.
- **Media Playback Integrity:** Do not promise 100% in-memory playback on all OS platforms, as many libraries require file handles. Instead, decrypt to a secure temporary directory for playback and rely on aggressive lifecycle cleanup.
- **Lifecycle Cleanup:** Always use `LifecycleCleanupManager` to scrub and wipe the temporary media playback directory the moment the app is suspended, backgrounded, or closed.

## 2. Desktop Database Constraints (SQLite FFI)
- **Library Selection:** For Windows, Linux, and macOS builds, you MUST use `sqflite_common_ffi` combined with `sqlcipher_flutter_libs`.
- **Encryption Initialization:** On FFI desktop builds, the standard `password` parameter on `openDatabase` does NOT work. You must inject the key using a raw SQL command inside the `onConfigure` block:
  ```dart
  onConfigure: (db) async {
    await db.execute("PRAGMA key = 'YOUR_PASSWORD_HERE';");
  }
  ```

## 3. Windows Native Build Dependencies
- **C++ ATL:** To successfully compile the Flutter Windows runner, the host environment must have the **C++ ATL for latest v143 build tools** installed via the Visual Studio Installer. Without this, the build will fail looking for `atlstr.h`.

## 4. Media & Document Viewers
- **Video:** Use `media_kit` and `media_kit_video`. It is the definitive choice for cross-platform GPU-backed playback in this app, supporting mobile, desktop, and large screens without freezing the UI.
- **Documents:** Use `syncfusion_flutter_pdfviewer` for rich, multi-platform document viewing over minimal alternatives.

## 5. Riverpod Clean Architecture
- **State Management:** Always use Riverpod 2.x `Notifier` and `AsyncNotifier`. Avoid legacy `StateNotifier`.
- **Directory Structure:** Strictly organize features by domain:
  - `domain/` (Data models and entities)
  - `data/` (Repositories and API/DB clients)
  - `state/` (Notifiers and Providers)
  - `presentation/` (ConsumerWidgets and UI components)
- **UI Connectivity:** Use `ConsumerWidget` and `ref.watch` heavily. The UI should be a thin wrapper around reactive state.

## 6. UI/UX Design System
- **Aesthetic:** Dark-mode-first, low-stimulus, minimalist UI with Material Design 3 (Material You).
- **Navigation:** Bottom navigation (3-5 items), gesture navigation, thumb-friendly layouts.
- **Responsiveness:** Maintain adaptive layouts for tablets, desktop, and TV (grid focus, larger touch targets).

## 7. Cloud Storage Integrations
- **Supported Providers:** Google Drive, Dropbox, and Microsoft OneDrive.
- **Authentication Flows:** 
  - **Mobile:** Use native Google Sign-In SDK for Google Drive, and `flutter_appauth` (OAuth 2.0 PKCE) for Dropbox and OneDrive.
  - **Desktop / TV:** Use OAuth 2.0 Device Authorization Grant flow or a `url_launcher` loopback flow.
- **Redirect URIs:** All standard OAuth providers (Dropbox, Azure) MUST be configured with the custom scheme: `com.syeds.itprotects://oauthredirect`.
- **Zero-Knowledge Encryption:** Files synchronized to ANY cloud provider MUST be encrypted as `.enc` files before transmission. NEVER upload plaintext metadata or files.
