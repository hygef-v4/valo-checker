# Component Inventory — ValoCheck

## Application Packages / Modules

### 1. Root & Coordinators
- `mobile/lib/main.dart` — App startup, theme configuration, push notification setup.
- `mobile/lib/screens/shop_screen.dart` — Root multi-tab navigation host, pull-to-refresh coordinator, session manager.
- `mobile/lib/screens/riot_login_webview.dart` — In-app WebView OAuth login dialog.

### 2. Domain Models (`mobile/lib/models/`)
- `accessory_item.dart` — Accessory Store item representation.
- `bundle_item.dart` — Featured Bundle item representation.
- `match_summary.dart` — Match history summary and player statistics payload.
- `quest_item.dart` — Missions, contracts, and daily/weekly goals.
- `rank_info.dart` — Competitive MMR rank info and rating deltas.
- `saved_account.dart` — Multi-account data structure with wishlist skin IDs.
- `skin_item.dart` — Weapon skin data class with chromas and video levels.
- `user_profile.dart` — Player metadata and currency balances.

### 3. Business & Data Services (`mobile/lib/services/`)
- `riot_api_client.dart` — Core HTTP transport client, timeouts, and error interception.
- `riot_auth_service.dart` — High-level player-data aggregation engine.
- `valorant_api_service.dart` — In-memory caching engine for Valorant-API metadata.
- `local_cache_service.dart` — Secure keystore storage and local JSON cache manager.
- `notification_service.dart` — Workmanager task runner and local notifications.

### 4. Presentation & UI Widgets (`mobile/lib/widgets/`)
- **Accounts**:
  - `accounts/accounts_tab.dart` — Account list, quick switch, and account removal UI.
- **Common**:
  - `common/data_unavailable.dart` — Standardized fallback placeholder.
  - `common/shimmer_loading_skeleton.dart` — Shimmer skeleton animation for async loads.
  - `common/sub_tab_bar.dart` — Sub-tab selection bar.
  - `common/top_header.dart` — App top bar with wallet pills and profile avatar.
- **Match Analysis**:
  - `match/match_details_modal.dart` — Comprehensive match dialog.
  - `match/match_scoreboard_tab.dart` — Scoreboard with ACS, KDA, Plants/Defuses.
  - `match/match_performance_tab.dart` — Combat performance, ADR, HS percentage.
  - `match/match_duels_tab.dart` — First Blood and opening duel breakdown.
  - `match/match_economy_tab.dart` — Loadout value and credit economy tracker.
  - `match/match_rounds_tab.dart` — Round-by-round win conditions and timeline.
- **Profile & Catalog**:
  - `profile/career_tab.dart` — MMR rank card, win rate, and recent match list.
  - `profile/collection_tab.dart` — Owned weapon inventory grouped by category.
  - `profile/weapons_tab.dart` — Weapons browser with inspection modal.
  - `profile/agents_tab.dart` — Agent roster grid.
  - `profile/agent_detail_modal.dart` — Agent portrait, abilities, and lore modal.
- **Shop & Storefront**:
  - `shop/daily_shop_tab.dart` — Daily 4-skin rotation offers with countdown timer.
  - `shop/night_market_tab.dart` — Night Market discount cards.
  - `shop/bundles_tab.dart` — Active featured bundles list.
  - `shop/bundle_detail_modal.dart` — Bundle breakdown modal.
  - `shop/accessory_shop_tab.dart` — Kingdom Credits accessory offers.
  - `shop/skin_detail_modal.dart` — Skin level preview, video playback, and chromas.
  - `shop/shop_shared.dart` — Shared shop formatting components.

### 5. Utilities & Theme (`mobile/lib/utils/`, `mobile/lib/theme/`)
- `utils/format_utils.dart` — Date, time, and number formatting helper.
- `utils/json_utils.dart` — Safe null-tolerant JSON accessors.
- `utils/match_team_helper.dart` — Team sorting and scoreboard calculations.
- `theme/app_colors.dart` — Centralized color scheme.

### 6. Test Suite (`mobile/test/`)
- `bundle_detail_modal_test.dart` — Bundle parser and UI tests.
- `format_utils_test.dart` — Utility formatting unit tests.
- `match_team_helper_test.dart` — Match team sorting and calculation tests.
- `saved_account_test.dart` — Account model serialization tests.
- `valorant_api_service_test.dart` — Metadata caching tests.
- `weapons_tab_test.dart` — Weapons widget interaction tests.
- `widget_smoke_test.dart` — Widget smoke test.
- `wishlist_test.dart` — Wishlist matching logic tests.

---

## Component Totals

- **Total Source Files in `mobile/lib/`**: 43 files
- **Total Test Files in `mobile/test/`**: 8 files
- **Total Configuration & Doc Files**: 6 files
- **Breakdown by Category**:
  - Models: 8 files
  - Services: 5 files
  - Screens: 2 files
  - Widgets: 23 files
  - Utils & Theme: 4 files
  - Entry Point: 1 file
