# API Documentation — ValoCheck

## External Riot Games Player-Data (PD) REST Endpoints

### 1. Entitlements Token API
- **Method**: `POST`
- **Path**: `https://entitlements.auth.riotgames.com/api/token/v1`
- **Headers**: `Authorization: Bearer <accessToken>`, `Content-Type: application/json`
- **Purpose**: Exchanges standard OAuth access token for Riot's Entitlements JWT required for player-data queries.
- **Response**:
  ```json
  {
    "entitlements_token": "<jwt_string>"
  }
  ```

### 2. User Info API
- **Method**: `GET`
- **Path**: `https://auth.riotgames.com/userinfo`
- **Headers**: `Authorization: Bearer <accessToken>`
- **Purpose**: Retrieves player's PUUID (`sub`), Game Name (`acct.game_name`), and Tagline (`acct.tag_line`).

### 3. Player Affinity Service (PAS Geo)
- **Method**: `PUT`
- **Path**: `https://riot-geo.pas.si.riotgames.com/pas/v1/product/valorant`
- **Headers**: `Authorization: Bearer <accessToken>`, `X-Riot-Entitlements-JWT: <entitlementsToken>`
- **Body**: `{"id_token": "<idToken>"}`
- **Purpose**: Detects player's routing cluster shard (`ap`, `eu`, `na`, `kr`).

### 4. Storefront API
- **Method**: `POST`
- **Path**: `https://pd.{shard}.a.pvp.net/store/v3/storefront/{puuid}`
- **Headers**: `Authorization: Bearer <accessToken>`, `X-Riot-Entitlements-JWT: <entitlementsToken>`, `X-Riot-ClientVersion: <version>`, `X-Riot-ClientPlatform: <platform>`
- **Purpose**: Returns active Daily Shop skin offers, Night Market discounts, Featured Bundles, and Accessory Store items with remaining time durations.

### 5. Wallet API
- **Method**: `GET`
- **Path**: `https://pd.{shard}.a.pvp.net/store/v1/wallet/{puuid}`
- **Purpose**: Retrieves currency balances for VP, Radianite Points, and Kingdom Credits.

### 6. Player Entitlements (Inventory)
- **Method**: `GET`
- **Path**: `https://pd.{shard}.a.pvp.net/store/v1/entitlements/{puuid}/{itemTypeId}`
- **Item Types**:
  - `e7c63390-eda7-46e0-bb7a-a6abdacd2433` -> Weapon Skins
  - `01bb38e1-da47-4e6a-9b3d-945fe4655707` -> Agents
- **Purpose**: Queries list of owned items to display in Collection and mark `OWNED` badges in Store.

### 7. Match History & Match Details
- **Method**: `GET`
- **Path**:
  - `https://pd.{shard}.a.pvp.net/match-history/v1/history/{puuid}?startIndex=0&endIndex=20`
  - `https://pd.{shard}.a.pvp.net/match-details/v1/matches/{matchId}`
- **Purpose**: Retrieves recent match history and comprehensive post-match statistics including scoreboards, rounds, economy, and player stats.

### 8. MMR & Competitive Updates API
- **Method**: `GET`
- **Path**:
  - `https://pd.{shard}.a.pvp.net/mmr/v1/players/{puuid}`
  - `https://pd.{shard}.a.pvp.net/mmr/v1/players/{puuid}/competitiveupdates?startIndex=0&endIndex=20`
- **Purpose**: Retrieves current seasonal tier, RR, peak rank, win counts, and match-by-match RR movements.

### 9. Name Service API
- **Method**: `PUT` / `POST`
- **Path**: `https://pd.{shard}.a.pvp.net/name-service/v2/players`
- **Body**: Array of PUUID strings (chunked by 30)
- **Purpose**: Resolves PUUIDs to player In-Game Names (IGN) and Taglines for match scoreboards.

---

## Public Valorant-API.com Metadata Endpoints

- `GET https://valorant-api.com/v1/version` — Real-time Riot client version.
- `GET https://valorant-api.com/v1/weapons/skins` — Weapon skin definitions, chromas, and video level assets.
- `GET https://valorant-api.com/v1/weapons/skinlevels` — Level definitions, VFX, animation clips.
- `GET https://valorant-api.com/v1/contenttiers` — Skin edition rarity tiers (Select, Deluxe, Premium, Exclusive, Ultra).
- `GET https://valorant-api.com/v1/bundles` — Bundle names and promotional banners.
- `GET https://valorant-api.com/v1/sprays` — Spray assets and animations.
- `GET https://valorant-api.com/v1/playercards` — Player card avatars and wide splash arts.
- `GET https://valorant-api.com/v1/buddies` & `/buddies/levels` — Gun buddy models and icons.
- `GET https://valorant-api.com/v1/competitivetiers` — Rank tier icons, colors, and tier names (Iron -> Radiant).
- `GET https://valorant-api.com/v1/agents?isPlayableCharacter=true` — Playable agent roster, abilities, voice lines.
- `GET https://valorant-api.com/v1/maps` — Map names, splash arts, minimaps.
- `GET https://valorant-api.com/v1/missions` — Daily/weekly quest objectives, XP reward grants.
- `GET https://valorant-api.com/v1/seasons` — Episode and Act season identifiers.

---

## Internal Dart Service APIs

### `RiotAuthService`
```dart
class RiotAuthService {
  static Future<String> getEntitlements(String accessToken);
  static Future<Map<String, dynamic>> getUserInfo(String accessToken);
  static Future<String> getRiotGeo(String accessToken, String idToken, String entitlementToken);
  static Future<Map<String, int>> getWallet(String accessToken, String entitlementToken, String puuid, String shard);
  static Future<RankInfo?> fetchRankInfo(String accessToken, String entitlementToken, String puuid, String shard);
  static Future<List<MatchSummary>> fetchMatchHistory(String accessToken, String entitlementToken, String puuid, String shard);
  static Future<List<QuestItem>> fetchQuestsAndBattlePass(String accessToken, String entitlementToken, String puuid, String shard);
  static Future<Set<String>> fetchOwnedAgents(String accessToken, String entitlementToken, String puuid, String shard);
  static Future<Map<String, dynamic>> fetchStorefrontData(String accessToken, String idToken);
}
```

### `ValorantApiService`
```dart
class ValorantApiService {
  static Future<void> loadMetadataCache();
  static SkinItem resolveSkinItem(String itemId, int cost, {String itemTypeId = ''});
  static AccessoryItem resolveAccessoryItem(String itemId, String itemTypeId, int costKC);
  static Map<String, String> resolveRankTier(int tierNumber);
  static Map<String, String> resolveAgent(String agentUuid);
  static Map<String, String> resolveMap(String mapPathOrUuid);
  static Map<String, dynamic> resolveMission(String missionUuid);
  static Map<String, String> resolveBundleMeta(String bundleUuid);
}
```

### `LocalCacheService`
```dart
class LocalCacheService {
  static Future<void> saveTokens(String accessToken, String idToken);
  static Future<Map<String, String>?> getValidTokens();
  static Future<void> clearTokens();
  static Future<void> saveProfile(Map<String, dynamic> profileJson);
  static Future<Map<String, dynamic>?> getCachedProfile();
  static Future<List<SavedAccount>> getSavedAccounts();
  static Future<void> saveAccount(SavedAccount account);
  static Future<void> removeAccount(String puuid);
  static Future<void> setActiveAccount(String puuid);
  static Future<SavedAccount?> getActiveAccount();
  static Future<void> toggleWishlist(String puuid, String skinUuid);
  static Future<bool> isWishlisted(String puuid, String skinUuid);
}
```
