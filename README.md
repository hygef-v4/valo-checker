# ValoCheck 🎯

[![Flutter](https://img.shields.io/badge/Flutter-3.11.5+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-green.svg)](https://flutter.dev)
[![CI/CD Status](https://github.com/hygef-v4/valo-checker/actions/workflows/mobile-ci.yml/badge.svg)](https://github.com/hygef-v4/valo-checker/actions)
[![AI-DLC](https://img.shields.io/badge/AI--DLC-Active-brightgreen)](aidlc-docs/aidlc-state.md)
[![License: Source Available](https://img.shields.io/badge/License-Source%20Available-orange.svg)](LICENSE)

> An unofficial, privacy-first **Valorant** companion mobile application built with Flutter. Track your Daily Store, Night Market, Career Rank & RR, match scoreboards, weapon collection, and wishlist notifications on-the-go — directly authenticated with your Riot account.

---

## ⚠️ Disclaimer

**ValoCheck** is an independent, unofficial project and is **not** endorsed by, affiliated with, or supported by Riot Games, Inc. Valorant and all related properties, assets, and logos are trademarks or registered trademarks of Riot Games, Inc. This application interacts with unofficial Riot client endpoints; these interfaces can change, rotate, or become unavailable at any time without notice.

---

## 📑 Table of Contents

- [Key Features](#-key-features)
- [Architecture & Tech Stack](#-architecture--tech-stack)
- [Project Structure](#-project-structure)
- [Security & Privacy Architecture](#-security--privacy-architecture)
- [Getting Started](#-getting-started)
- [Quality Gates & Testing](#-quality-gates--testing)
- [Release Builds](#-release-builds)
- [AI-DLC Lifecycle Documentation](#-ai-dlc-lifecycle-documentation)
- [License & Terms](#-license--terms)

---

## ✨ Key Features

| Category | Features | Description |
|---|---|---|
| **🛒 Store & Deals** | **Daily 4-Skin Rotation** | Real-time 4-skin rotation with live countdown timer and `OWNED` badge detection. |
| | **Night Market** | Real-time discount percentages, original prices, and discounted VP costs. |
| | **Featured Bundles** | Active promotional bundles with aggregated price calculations and expiration timers. |
| | **Accessory Store** | Kingdom Credits (KC) offers, gun buddies, player cards, titles, and reset countdowns. |
| **🔔 Wishlist & Alerts** | **Smart Wishlist** | Add desired weapon skins to a local monitored wishlist. |
| | **Background Sync** | Scheduled background checks via `Workmanager` notifying you the moment a wishlist skin appears. |
| **🎖️ Career & MMR** | **Rank & RR Tracker** | Current competitive rank tier, Ranked Rating (RR 0-100), and historical peak rank. |
| | **RR Match History** | Chronological list of competitive matches displaying RR deltas (+/- RR) and tier updates. |
| | **Missions & Contracts** | Active daily/weekly missions with real XP rewards and progress trackers. |
| **📊 Match Insights** | **Detailed Scoreboard** | Full scoreboard breakdown with ACS, KDA, ADR, Headshot %, First Kills (FK), and First Deaths (FD). |
| | **Combat Performance** | Head-to-head duels matrix, kill-feed breakdown, and weapon effectiveness. |
| | **Economy & Timeline** | Loadout value and credits spent per round, with round-by-round win conditions. |
| **🎒 Collection & Media** | **Weapon Catalog** | Owned skins grouped by weapon class (Sidearms, SMGs, Rifles, Snipers, Shotguns, Heavies, Melee). |
| | **Levels & Chromas** | Inspect animation levels, sound effects, finishers, color variants, and streamable video previews. |
| **🎭 Agents & Lore** | **Agent Roster** | Complete roster with ownership status, role filters (Duelist, Initiator, Sentinel, Controller), and voice lore. |
| **👥 Accounts** | **Multi-Account Manager** | Seamless 1-tap switching between multiple saved accounts with encrypted token storage. |

---

## 🏛️ Architecture & Tech Stack

ValoCheck is engineered with a modular, service-oriented Flutter architecture:

```
[ UI Layer: Screens & Modular Widgets ]
                    │
                    ▼
[ Business Services: RiotAuthService | ValorantApiService | LocalCacheService | NotificationService ]
                    │
       ┌────────────┴────────────┐
       ▼                         ▼
[ Riot Client APIs ]    [ Valorant-API.com ]
  (pd.<shard>.a.pvp.net)  (Static Assets & Metadata)
```

- **Framework**: [Flutter](https://flutter.dev) (SDK `^3.11.5`) & [Dart](https://dart.dev)
- **State Management & UI**: Native Flutter reactive state (`StatefulWidget`, `ValueNotifier`, `InheritedWidget`)
- **Networking**: `http` with centralized timeout handling, client version caching, and 401 session recovery
- **Secure Persistence**: `flutter_secure_storage` (Android Keystore / iOS Keychain)
- **Local Cache**: `shared_preferences` for offline profile & metadata caching
- **Background Tasks**: `workmanager` for scheduled store checks
- **Local Notifications**: `flutter_local_notifications`
- **In-App WebView**: `webview_flutter` for secure Riot Sign-On (RSO) authentication
- **Media & Assets**: `cached_network_image` and `video_player` / `chewie` for skin preview playback

---

## 📂 Project Structure

```
valo-checker/
├── .github/
│   └── workflows/
│       └── mobile-ci.yml        # CI/CD: Static analysis, unit tests, APK build
├── aidlc-docs/                  # AI-DLC Adaptive Lifecycle Documentation
│   ├── inception/               # Inception phase: Reverse engineering, requirements, plans
│   ├── construction/            # Construction phase: Build & test instructions, summaries
│   ├── aidlc-state.md           # Lifecycle stage tracker
│   └── audit.md                 # Complete audit trail of decisions & user inputs
├── docs/
│   └── RELEASE_CHECKLIST.md     # Production release pre-flight checklist
├── mobile/                      # Flutter Application Root
│   ├── lib/
│   │   ├── main.dart            # Application entrypoint & theme initialization
│   │   ├── theme/
│   │   │   └── app_colors.dart  # ValoCheck dark-mode color palette & styling tokens
│   │   ├── models/              # Plain Data Classes & JSON serialization
│   │   │   ├── saved_account.dart
│   │   │   ├── rank_info.dart
│   │   │   └── match_details.dart
│   │   ├── services/            # Core business logic & API clients
│   │   │   ├── riot_api_client.dart       # HTTP client with timeouts & version caching
│   │   │   ├── riot_auth_service.dart     # RSO authentication & Player Data API
│   │   │   ├── valorant_api_service.dart  # Metadata cache for valorant-api.com
│   │   │   ├── local_cache_service.dart   # Keystore storage & profile persistence
│   │   │   └── notification_service.dart  # Wishlist background notification worker
│   │   ├── screens/             # Top-level screen coordinators
│   │   │   ├── shop_screen.dart           # Primary tab coordinator & state orchestrator
│   │   │   └── riot_login_webview.dart    # Riot OAuth WebView interceptor
│   │   ├── widgets/             # Domain-specific UI widgets
│   │   │   ├── common/          # Shimmer loaders, headers, tab bars, empty states
│   │   │   ├── shop/            # Daily shop cards, night market, bundles, skin modals
│   │   │   ├── profile/         # Collection grid, career overview, agent browser
│   │   │   ├── match/           # Match detail dialogs (Scoreboard, Economy, Duels, Rounds)
│   │   │   └── accounts/        # Account switcher modal & active card
│   │   └── utils/               # Formatting, team building, error parsing
│   └── test/                    # Unit and widget test suite
├── privacy_policy.html          # Privacy policy document for app stores
├── LICENSE                      # Source-available license
└── README.md                    # Project documentation
```

---

## 🔒 Security & Privacy Architecture

ValoCheck is engineered from the ground up to protect user credentials:

1. **Zero Password Interception**: Credentials are typed exclusively on Riot's official login webpage hosted inside a sandboxed in-app WebView. The app never captures, reads, or transmits raw usernames or passwords.
2. **Hardware-Backed Encryption**: OAuth tokens (`accessToken`, `entitlementsToken`) are stored using the device's hardware security module (`Android Keystore` on Android, `Keychain` on iOS).
3. **Frictionless SSO Re-Authentication**: Riot SSO cookies are retained securely in the WebView session cookie jar, enabling instant 1-tap re-login when 1-hour OAuth access tokens expire.
4. **Direct Client-to-Server Communication**: All network requests originate directly from the user's mobile device to Riot's regional servers (`pd.<shard>.a.pvp.net`) or `valorant-api.com`. No third-party intermediary servers or telemetry collectors are involved.
5. **Instant Data Wipe**: Tapping **Log Out** immediately wipes tokens from the Keystore and flushes stored profile data from local storage.

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`^3.11.5` or higher)
- [Dart SDK](https://dart.dev/get-dart) (`^3.0.0`)
- Android Studio / Android SDK (for Android builds) or Xcode (for iOS builds)

### Installation & Local Run

1. **Clone the repository**:
   ```bash
   git clone https://github.com/hygef-v4/valo-checker.git
   cd valo-checker/mobile
   ```

2. **Install Flutter dependencies**:
   ```bash
   flutter pub get
   ```

3. **Launch the application**:
   ```bash
   flutter run
   ```

4. **Authenticate**:
   - Tap **Log in with Riot Account** in the in-app WebView.
   - Complete 2-Factor Authentication (2FA) if prompted.
   - ValoCheck will automatically extract your session tokens and load your store and stats.

---

## 🧪 Quality Gates & Testing

ValoCheck enforces strict quality standards before any code is merged:

```bash
# Navigate to mobile project directory
cd mobile

# 1. Run static analysis (0 warnings expected)
flutter analyze

# 2. Run the automated test suite
flutter test
```

### Automated CI/CD Pipeline
Every pull request and push touching `mobile/` triggers [`.github/workflows/mobile-ci.yml`](.github/workflows/mobile-ci.yml), which executes:
- Flutter environment setup
- Dependency resolution (`flutter pub get`)
- Static code analysis (`flutter analyze --fatal-infos`)
- Automated test execution (`flutter test`)
- Release APK build verification (`flutter build apk --release`)

---

## 📦 Release Builds

### Android Setup

1. **Generate a keystore** (one-time setup for release signing):
   ```bash
   keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. **Configure Signing Keys**:
   Copy `mobile/android/key.properties.example` to `mobile/android/key.properties` and fill in your keystore passwords and path (this file is excluded by `.gitignore`).
3. **Compile Release Artifacts**:
   ```bash
   cd mobile
   
   # For Google Play Store submission (.aab)
   flutter build appbundle --release
   
   # For direct distribution (.apk)
   flutter build apk --release
   ```

> 📖 For comprehensive pre-release steps, review [docs/RELEASE_CHECKLIST.md](docs/RELEASE_CHECKLIST.md).

---

## 📖 AI-DLC Lifecycle Documentation

This repository follows the **AI-DLC (Adaptive AI-Driven Lifecycle)** methodology. Detailed technical artifacts, reverse engineering specifications, and audit records are documented in [`aidlc-docs/`](aidlc-docs/):

- **🔵 Inception Artifacts**:
  - [Business Overview](aidlc-docs/inception/reverse-engineering/business-overview.md) — System transactions, business glossary, and value propositions.
  - [Architecture Map](aidlc-docs/inception/reverse-engineering/architecture.md) — High-level architecture, module relationships, and data flow.
  - [Code Structure](aidlc-docs/inception/reverse-engineering/code-structure.md) — Detailed codebase map across all 43 source files.
  - [API Documentation](aidlc-docs/inception/reverse-engineering/api-documentation.md) — Detailed Riot RSO & Player Data endpoint specifications.
  - [Component Inventory](aidlc-docs/inception/reverse-engineering/component-inventory.md) — Complete inventory of models, services, screens, and widgets.
  - [Technology Stack](aidlc-docs/inception/reverse-engineering/technology-stack.md) — Deep dive into libraries, frameworks, and tools.
- **🟢 Construction Artifacts**:
  - [Build Instructions](aidlc-docs/construction/build-and-test/build-instructions.md) — Step-by-step build instructions for local and CI environments.
  - [Unit Test Instructions](aidlc-docs/construction/build-and-test/unit-test-instructions.md) — Testing execution and coverage guidelines.
  - [Build & Test Summary](aidlc-docs/construction/build-and-test/build-and-test-summary.md) — Validation report (21/21 tests passing, 0 lint warnings).
- **📋 Tracking & Governance**:
  - [AI-DLC State Tracker](aidlc-docs/aidlc-state.md) — Current lifecycle status.
  - [AI-DLC Audit Log](aidlc-docs/audit.md) — Immutable log of actions, user prompts, and execution history.

---

## 📄 License & Terms

Copyright (c) 2026 **hygef-v4**. All Rights Reserved.

This repository is **Source Available** (view-only for educational and personal research purposes). You are welcome to inspect and learn from the code, but copying, modifying, rebranding, or redistributing this application or its assets without explicit written permission is strictly prohibited.

For complete license terms, refer to the [LICENSE](LICENSE) file.
