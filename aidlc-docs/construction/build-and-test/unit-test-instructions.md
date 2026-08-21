# Unit & Widget Test Instructions — ValoCheck

## Running Automated Tests

```bash
cd mobile
flutter test
```

## Test Suite Inventory

1. `bundle_detail_modal_test.dart`: Bundle metadata and sub-item list rendering.
2. `format_utils_test.dart`: Currency formatting, time remaining, date formatting.
3. `match_team_helper_test.dart`: Scoreboard sorting, MVP detection, player team grouping.
4. `saved_account_test.dart`: Account serialization and token expiry calculation.
5. `valorant_api_service_test.dart`: Valorant-API metadata resolution and fallback mechanisms.
6. `weapons_tab_test.dart`: Weapons inventory filtering and search.
7. `widget_smoke_test.dart`: Application bootstrap and unauthenticated state rendering.
8. `wishlist_test.dart`: Wishlist skin detection and match notifications.

---

## Test Verification Standards

- **Zero Test Failures**: All 21 tests must pass cleanly.
- **No Flakiness**: All asynchronous tests must properly await async tasks and mock network responses where necessary.
