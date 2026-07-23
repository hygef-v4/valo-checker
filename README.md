# ValoCheck Mobile 🎯

An all-in-one Flutter mobile application for tracking **Valorant** Daily Store, Night Market, Career Rank & RR, Match Scoreboards, and Agent Collections directly using official Riot Games Client APIs.

## 🚀 Features

- 🛒 **Daily Shop**: View your 4 daily weapon skin offers with real-time countdown timer.
- 🌙 **Night Market**: Track discounted skins with discount percentage and line-through original VP prices.
- 💎 **Accessory Shop**: Check Kingdom Credits accessories and countdown timers.
- 📦 **Featured Bundles**: Browse active featured collections and VP bundle deals.
- 🎒 **Grouped Collection**: View owned weapon skins cleanly grouped by weapon family.
- 🎭 **Playable Agents Gallery**: Interactive agent selector displaying owned status (`Owned` vs `Locked`), role badges, and HD portrait art.
- 🎖️ **Career & Rank Tracker**: Accurate Rank display (`Bronze 2 - 52 RR`), Peak Rank, and match history scoreboards.
- 👥 **Multi-Account Management**: Account switching card with player level badge and card banner art.

## 🛠️ Tech Stack

- **Framework**: Flutter 3.x / Dart 3.x
- **Network**: `http` with direct Riot Games RSO Authentication
- **Images**: `cached_network_image`
- **UI Architecture**: Custom Recon / ValoStore Dark Theme Aesthetic

## 📱 How to Run

```bash
cd mobile
flutter pub get
flutter run
```