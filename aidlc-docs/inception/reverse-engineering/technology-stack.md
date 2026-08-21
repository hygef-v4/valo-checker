# Technology Stack — ValoCheck

## Programming Languages

- **Dart**: SDK `^3.11.5` — Main programming language for application UI, state management, networking, and tests.
- **Java / Kotlin**: Target platform layer for Android integration (via Flutter Android embedding).
- **Swift / Objective-C**: Target platform layer for iOS integration (via Flutter iOS embedding).

---

## Frameworks & Libraries

### Core Framework
- **Flutter Framework**: Cross-platform UI toolkit targeting Android and iOS.

### UI & Presentation
- **`google_fonts: ^6.2.1`**: Typography integration using Google's `Inter` font.
- **`cupertino_icons: ^1.0.8`**: iOS-styled icons for cross-platform visual consistency.
- **`cached_network_image: ^3.3.1`**: High-performance asynchronous image caching for skins, agent portraits, and map splashes.

### Web & Authentication
- **`webview_flutter: ^4.10.0`**: Embedded Chromium/WebKit browser for secure Riot Sign-On (RSO).

### Networking & Serialization
- **`http: ^1.2.1`**: Asynchronous HTTP client for Riot PD endpoints and Valorant-API.com.
- **`dart:convert`**: Standard JSON encoding and decoding.

### Local Persistence & Security
- **`flutter_secure_storage: ^10.3.1`**: Hardware-backed credential encryption (Android Keystore / iOS Keychain) for sensitive OAuth tokens.
- **`shared_preferences: ^2.2.3`**: Persistent key-value storage for user settings, wishlists, and cached profiles.

### Background Tasks & Push Notifications
- **`flutter_local_notifications: ^18.0.1`**: Native OS notification dispatch for store alerts.
- **`workmanager: ^0.10.6`**: Background execution engine running headless periodic tasks even when the app is closed.

### Development & Testing
- **`flutter_test`**: Flutter testing framework for unit and widget tests.
- **`flutter_lints: ^6.0.0`**: Official recommended static analysis and lint rules.
- **`flutter_launcher_icons: ^0.14.4`**: Automated app icon generation tool across Android and iOS densities.

---

## Build, CI/CD & Tooling

- **Build Systems**:
  - Flutter CLI (`flutter build apk`, `flutter build appbundle`, `flutter build ipa`)
  - Gradle (Android Build Tool)
  - CocoaPods / Xcode (iOS Build Tool)
- **Continuous Integration**:
  - GitHub Actions (`.github/workflows/mobile-ci.yml`): Automated `flutter analyze`, `flutter test`, and release APK artifact generation on push/PR.
- **Static Analysis**:
  - `analysis_options.yaml` enforcing zero-warning code quality.
