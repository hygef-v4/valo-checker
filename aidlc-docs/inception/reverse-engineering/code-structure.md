# Code Structure — ValoCheck

## Build System

- **Type**: Flutter / Dart Build System (Pub) with Platform Build Systems (Gradle for Android, CocoaPods/Xcode for iOS).
- **Configuration Files**:
  - `mobile/pubspec.yaml`: Core dependency declarations and project metadata.
  - `mobile/analysis_options.yaml`: Static analysis rules with `flutter_lints: ^6.0.0`.
  - `mobile/android/app/build.gradle`: Android SDK levels, Proguard shrinking, keystore signing configs.
  - `.github/workflows/mobile-ci.yml`: Automated CI pipeline (lint, test, build).

---

## Directory & Module Hierarchy

```
mobile/lib/
├── main.dart                          # Application entry point, NotificationService initialization, dark theme
├── models/                            # Domain Data Transfer Objects (DTOs)
│   ├── accessory_item.dart            # Accessory Store item model
│   ├── bundle_item.dart               # Featured Bundle and bundle sub-items model
│   ├── match_summary.dart             # Match overview and parsed player stats model
│   ├── quest_item.dart                # Missions / Contracts progress model
│   ├── rank_info.dart                 # Competitive Rank, RR, and match updates model
│   ├── saved_account.dart             # Multi-account state, credentials, and wishlist model
│   ├── skin_item.dart                 # Weapon skin, chromas, and video level model
│   └── user_profile.dart              # User profile, wallet balances, IGN & tagline
├── screens/                           # Root Screen Coordinators
│   ├── riot_login_webview.dart        # In-app WebView for Riot Sign-On
│   └── shop_screen.dart               # Main multi-tab coordinator & session management
├── services/                          # API, Network & Persistence Layer
│   ├── local_cache_service.dart       # Secure storage, preferences, account management
│   ├── notification_service.dart      # Local push notifications & Workmanager background sync
│   ├── riot_api_client.dart           # HTTP client wrapper, client version cache, timeout handling
│   ├── riot_auth_service.dart         # Riot API aggregator (storefront, MMR, matches, contracts)
│   └── valorant_api_service.dart      # In-memory static metadata cache from valorant-api.com
├── theme/
│   └── app_colors.dart                # Centralized color palette (Valorant Dark Red/Black design)
├── utils/
│   ├── format_utils.dart              # Duration formatters, number formatting helpers
│   ├── json_utils.dart                # Safe JSON parsing and collection lookup utilities
│   └── match_team_helper.dart         # Match scoreboard & player team extraction logic
└── widgets/                           # Reusable UI Components
    ├── accounts/                      # Account switcher & management bottom sheets
    ├── common/                        # Shared UI components (TopHeader, SubTabBar, Skeleton loader)
    ├── match/                         # Deep-dive match modals (Scoreboard, Duels, Economy, Rounds)
    ├── profile/                       # Career, Collection, Weapons inventory, Agents tabs
    └── shop/                          # Daily shop, Night Market, Bundles, Accessory store, Skin modal
```

---

## Existing Files Inventory

### Source Files (`mobile/lib/`)
- `mobile/lib/main.dart` — App bootstrap, notification setup, global theme configuration.
- `mobile/lib/models/accessory_item.dart` — Data class for Accessory Store items.
- `mobile/lib/models/bundle_item.dart` — Data class for Featured Bundles.
- `mobile/lib/models/match_summary.dart` — Data class for match history items and raw match payload wrapper.
- `mobile/lib/models/quest_item.dart` — Data class for daily/weekly missions and contracts.
- `mobile/lib/models/rank_info.dart` — Data class for current tier, peak tier, RR, and competitive updates.
- `mobile/lib/models/saved_account.dart` — Data class for stored accounts, active selection, and wishlist items.
- `mobile/lib/models/skin_item.dart` — Data class for weapon skins, chromas, tiers, and videos.
- `mobile/lib/models/user_profile.dart` — Data class for player IGN, tagline, PUUID, and wallet balances.
- `mobile/lib/screens/riot_login_webview.dart` — WebView screen handling Riot RSO OAuth interactive flow.
- `mobile/lib/screens/shop_screen.dart` — Primary navigation and data coordinator screen.
- `mobile/lib/services/local_cache_service.dart` — Hardware-backed token storage and SharedPreferences cache.
- `mobile/lib/services/notification_service.dart` — Scheduled background task and local push notifications.
- `mobile/lib/services/riot_api_client.dart` — HTTP wrapper with client version caching and error handling.
- `mobile/lib/services/riot_auth_service.dart` — Comprehensive service aggregating Riot PD endpoints.
- `mobile/lib/services/valorant_api_service.dart` — Metadata caching and asset resolver for valorant-api.com.
- `mobile/lib/theme/app_colors.dart` — Valorant theme colors (Red `#FD4556`, Dark `#0F1923`, etc.).
- `mobile/lib/utils/format_utils.dart` — Time, currency, and date formatting utilities.
- `mobile/lib/utils/json_utils.dart` — Helper functions for safe JSON and list extraction.
- `mobile/lib/utils/match_team_helper.dart` — Match stats processing and team scoreboard grouping.
- `mobile/lib/widgets/accounts/accounts_tab.dart` — Multi-account list, login trigger, and active account switch.
- `mobile/lib/widgets/common/data_unavailable.dart` — Fallback widget for empty/unavailable data states.
- `mobile/lib/widgets/common/shimmer_loading_skeleton.dart` — Loading placeholder animations.
- `mobile/lib/widgets/common/sub_tab_bar.dart` — Reusable secondary tab bar.
- `mobile/lib/widgets/common/top_header.dart` — App header with wallet balances, user avatar, and account selector.
- `mobile/lib/widgets/match/match_details_modal.dart` — Modal popup displaying comprehensive match breakdown.
- `mobile/lib/widgets/match/match_duels_tab.dart` — First blood / opening duels analysis tab.
- `mobile/lib/widgets/match/match_economy_tab.dart` — Credit spend and loadout cost timeline tab.
- `mobile/lib/widgets/match/match_performance_tab.dart` — Headshot %, ADR, and combat score tab.
- `mobile/lib/widgets/match/match_rounds_tab.dart` — Round-by-round kill events and plant/defuse tab.
- `mobile/lib/widgets/match/match_scoreboard_tab.dart` — Team scoreboard with ACS, K/D/A, and plants.
- `mobile/lib/widgets/profile/agent_detail_modal.dart` — Agent abilities, portrait, and biography modal.
- `mobile/lib/widgets/profile/agents_tab.dart` — Playable agent grid with owned/locked filters.
- `mobile/lib/widgets/profile/career_tab.dart` — Rank badge, peak rank, win rate, and recent match list.
- `mobile/lib/widgets/profile/collection_tab.dart` — Player weapon skin inventory organized by weapon type.
- `mobile/lib/widgets/profile/weapons_tab.dart` — Comprehensive weapons catalog with skin inspect.
- `mobile/lib/widgets/shop/accessory_shop_tab.dart` — Kingdom Credits accessory offers tab.
- `mobile/lib/widgets/shop/bundle_detail_modal.dart` — Featured bundle breakdown and weapon list modal.
- `mobile/lib/widgets/shop/bundles_tab.dart` — Active featured bundles list.
- `mobile/lib/widgets/shop/daily_shop_tab.dart` — Daily 4-skin store grid with countdown timer.
- `mobile/lib/widgets/shop/night_market_tab.dart` — Night Market discounted cards tab.
- `mobile/lib/widgets/shop/shop_shared.dart` — Shared shop countdown timers and currency tags.
- `mobile/lib/widgets/shop/skin_detail_modal.dart` — Skin level, video preview, and chroma selection modal.

### Test Files (`mobile/test/`)
- `mobile/test/bundle_detail_modal_test.dart` — Unit tests for bundle parsing and modal display.
- `mobile/test/format_utils_test.dart` — Unit tests for date/time and currency formatting.
- `mobile/test/match_team_helper_test.dart` — Unit tests for match scoreboards and player sorting.
- `mobile/test/saved_account_test.dart` — Unit tests for account serialization and wishlist operations.
- `mobile/test/valorant_api_service_test.dart` — Unit tests for metadata resolution.
- `mobile/test/weapons_tab_test.dart` — Widget tests for weapons explorer tab.
- `mobile/test/widget_smoke_test.dart` — Basic app widget smoke test.
- `mobile/test/wishlist_test.dart` — Unit tests for wishlist matching and notifications.

---

## Design Patterns & Architectural Practices

1. **Layered Architecture**: Strict boundary separation between Presentation (`widgets/`, `screens/`), Domain/Models (`models/`), and Services (`services/`).
2. **Repository / In-Memory Cache Pattern**: `ValorantApiService` fetches static metadata once and serves subsequent requests from fast in-memory Maps.
3. **Session Interceptor Pattern**: `RiotApiClient` intercepts `401/403` status codes and raises `SessionExpiredException` to prompt clean re-authentication rather than crash or corrupt cache.
4. **Secure Keystore Integration**: Sensitive tokens are isolated in OS-native secure enclaves via `flutter_secure_storage`.
5. **Background Task Worker**: `Workmanager` background scheduler executing headless background checks with battery-friendly constraints.
