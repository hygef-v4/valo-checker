# ValoCheck 🎯

An unofficial **Valorant** companion app for mobile, built with Flutter. Track your Daily Store, Night Market, Career Rank & RR, match scoreboards, and collection — signed in with your own Riot account.

> **Disclaimer**: ValoCheck is not endorsed by Riot Games and does not reflect the views or opinions of Riot Games or anyone officially involved in producing or managing Riot Games properties. Riot Games and all associated properties are trademarks or registered trademarks of Riot Games, Inc. This app uses unofficial client APIs; they can change or become unavailable at any time.

## Features

- 🛒 **Daily Shop** — your 4 daily skin offers with a live countdown and OWNED badges.
- 🌙 **Night Market** — discounted offers with real discount percentages and original prices.
- 💎 **Accessory Shop** — Kingdom Credits offers with reset countdown.
- 📦 **Featured Bundles** — active bundles with real total prices and expiry timers.
- 🎒 **Collection** — owned skins grouped by weapon family, with chromas, levels, and demo videos.
- 🎭 **Agents Gallery** — owned/locked status, roles, abilities, and lore.
- 🎖️ **Career** — current rank & RR, peak rank, seasonal win totals, active missions with real XP values.
- 📊 **Match Details** — real scoreboards (ACS/ADR/HS%/FK/FD), duels, economy, and round timelines. Sections show an honest "data unavailable" state when Riot doesn't return the data — nothing is ever invented.
- 🔐 **Secure sessions** — tokens live in the platform keystore (never plaintext), and the Riot SSO cookie is kept so re-login after token expiry is one tap.

## Project layout

```
mobile/
  lib/
    main.dart                  # App entry + theme
    theme/app_colors.dart      # Palette
    models/                    # Plain data classes
    services/
      riot_api_client.dart     # HTTP wrapper: timeouts, client version cache, session-expiry detection
      riot_auth_service.dart   # Riot RSO auth + player-data endpoints (pd.<shard>.a.pvp.net)
      valorant_api_service.dart# valorant-api.com metadata cache (skins, agents, maps, missions...)
      local_cache_service.dart # Secure token storage + profile cache
    screens/
      shop_screen.dart         # Coordinator: navigation, data loading, session handling
      riot_login_webview.dart  # Riot RSO login WebView
    widgets/
      common/                  # Header, sub-tabs, shimmer, empty states
      shop/                    # Daily shop, night market, accessories, bundles, skin modal
      profile/                 # Collection, agents, career
      accounts/                # Account card & switching
      match/                   # Match details modal + tabs
    utils/                     # Formatters, team builder, JSON helpers
  test/                        # Unit + widget tests
```

## Getting started

```bash
cd mobile
flutter pub get
flutter run
```

Sign in with your Riot account in the in-app WebView. Tokens expire after ~1 hour; thanks to the kept SSO cookie, tapping "Log in" again completes without retyping credentials.

## Quality gates

```bash
flutter analyze   # zero warnings expected
flutter test      # unit + widget tests
```

CI (`.github/workflows/mobile-ci.yml`) runs analyze + tests + a release APK build on every push/PR touching `mobile/`.

## Release build (Android)

1. Create a keystore (once) and keep it safe — losing it means you can never update the app on the Play Store:
   ```bash
   keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. Copy `mobile/android/key.properties.example` to `mobile/android/key.properties` and fill in your passwords/paths (git-ignored).
3. Build:
   ```bash
   flutter build appbundle --release   # Play Store upload (.aab)
   flutter build apk --release         # direct-install APK
   ```

Release builds are minified and resource-shrunk. Without `key.properties` the build falls back to debug signing (fine for local testing, rejected by the Play Store).

See `docs/RELEASE_CHECKLIST.md` for the full pre-release checklist.

## Privacy

ValoCheck talks directly to Riot endpoints from your device. Your Riot credentials are entered only on Riot's own login page inside the WebView; the app never sees your password. Auth tokens are stored in the platform keystore (Android Keystore / iOS Keychain) and can be wiped with Log Out. No data is sent to any third-party server. If you publish to an app store, host a privacy policy stating the above — stores require one for apps with login.

## License

Copyright (c) 2026 hygef-v4. All Rights Reserved.

This repository is **Source Available** (view-only for educational/personal purposes). You are welcome to inspect the code, but copying, modifying, rebranding, or redistributing this application or its assets without explicit permission is strictly prohibited. See [LICENSE](LICENSE) for full details.

