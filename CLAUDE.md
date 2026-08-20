# Fielmedina iOS

SwiftUI app for Tunisia medina tourism (offline-first). Talks to a Django/Strawberry
GraphQL backend (`FielMedina-API`, sibling directory) via Apollo iOS. Android sibling
app (`Fielmedina-Android-v3`) mirrors this one closely — when fixing a bug or adding a
feature here, check whether the same issue exists there.

## Non-negotiable: offline-first

The app must work with zero signal — a tourist inside a medina has no data. This
constrains how data loading and filtering must be written:

- **Never filter or paginate via a network request.** The offline prefetcher
  (`Services/Cache/OfflineContentPrefetcher.swift`) downloads the full catalogue for
  each entity type at app launch/daily refresh, using ONE specific query variant per
  entity (e.g. `LocationService.fetchLocations(cityId: nil, limit: 500, offset: 0)`).
  That exact variant is what's in the Apollo SQLite cache. Any *different* query
  variant (a filtered `cityId:`, a different `limit`) is NOT cached and forces a
  network round-trip — which fails offline. This bit us for real: filtering by
  region/category was implemented server-side once, breaking offline use, and had to
  be reverted to local filtering over the full cached catalogue.
- Pattern for list screens: load the full catalogue once (matching the prefetcher's
  variant → instant from cache online or offline) → filter/sort locally → paginate
  the *display* only (slice a growing `visibleCount` window), never re-fetch on
  scroll or on filter change.
- Offline data lives in **Application Support**, not Caches — iOS purges Caches under
  storage pressure. See `Services/Cache/CacheConfigurator.swift`.

## Cities/medinas are server-driven — never hardcode a list

`OfflineCityDataStore.cachedCities` is the single source of truth for "which medinas
exist". It is refreshed from the backend on every launch
(`OfflineMapsManager.refreshCitiesMetadata()`, reached via
`refreshDownloadedRegionsIfNeeded()`) and again from the Settings screen; the three
hardcoded cities inside `cachedCities` are only the pre-first-sync fallback.

Any "which medina is the user in / nearest to" question goes through
`OfflineCityDataStore.nearestCity(to:)` (or `getCityId(for:)`, which wraps it).
`MapView` used to keep its own hardcoded `medinaRegistry` of three cities for
centring the camera, so every region added in the backend was invisible to the map
while the rest of the app already knew about it. Don't reintroduce a local list —
adding a city must require **zero** app changes. Use real distance
(`CLLocation.distance(from:)`), never raw degree deltas: a degree of longitude is
~19% shorter than a degree of latitude at Tunisia's latitude, which mis-ranks
candidates (measurably — ~6% of the country even with only three cities, worse as
more are added).

## Presentation layer: `@Observable` models

Views used to hold all state/logic directly (`@State` in the View struct) — this
broke on view-recreation (state loss) and made nothing unit-testable. As of the
current refactor, list/detail screens follow an MVVM-like pattern:

- **Reference implementation:** `Core/Features/Locations/AllLocationsModel.swift` +
  `AllLocationList.swift`. Read the doc comment at the top of the model file for the
  full rationale.
- Shape: `@MainActor @Observable final class XModel { ... }` holds all state and
  logic, injected with production-default dependencies (`init(service: X = .shared)`)
  so it's testable. The View does `@State private var model = XModel()` (created
  once, survives body re-evaluation — SwiftUI's answer to Android's `ViewModel`).
- Internal, never-rendered properties (`Task` handles, `NSObjectProtocol` observer
  tokens) must be `@ObservationIgnored nonisolated(unsafe)` — otherwise `@Observable`
  turns them into tracked computed properties and `deinit` (non-isolated) can't touch
  them. See any existing `*Model.swift` for the exact incantation.
- Camera/viewport/navigation-path/scroll-offset type state stays in the View — that's
  SwiftUI rendering state, not app data (see `MapContentModel.swift` header comment
  for the reasoning, since Map is the one screen that splits data vs. rendering).
- Converted so far: Locations, Events, Merchants, Hiking (`HikingListModel` — note
  the `List` suffix, `HikingModel` is already taken by the API data model), Map
  (data half only), Home (flags + onboarding only — Home doesn't own much state).
  Detail views share `PlaceNavigationModel` (`Core/Features/Navigation/`) for
  turn-by-turn "navigate to this place" logic instead of duplicating it.
- Shared audio-guide pattern: `LocationVoiceoverPlayer`, used identically in
  `LocationDetailView` and `Components/Ui/Hiking/HikingLocationSheet.swift` (icon,
  color `#B66239`, 44×44 `Circle()`, accessibility label must switch between "Listen"
  and "Stop" based on `isPlaying`).

## Meta ads measurement (`Services/Analytics/MetaEvents.swift`)

Ad attribution, separate from Firebase Analytics (product analytics). Both are needed;
neither replaces the other. Three things must all be true or iOS measurement is dead:

1. **SDK initialised** — `MetaEvents.initializeSDK(...)` in `AppDelegate`. The SDK was
   once linked via SPM and configured in Info.plist but never initialised in code, so
   it sent *nothing* — not even install/activate — and every campaign optimised against
   an empty signal. A linked FBSDK is not an active FBSDK.
2. **`SKAdNetworkItems` in Info.plist** — Meta's two IDs (`v9wttpbfk9.skadnetwork`
   Facebook, `n38lu8286q.skadnetwork` Instagram). Without them Apple never sends an
   install postback to Meta, independent of anything the SDK does.
3. **ATT authorisation requested** — the prompt fires after onboarding, not at cold
   start (where it stacks on the notification and location prompts and gets denied).
   Asking is all the app must do: `Settings.isAdvertiserTrackingEnabled` is deprecated
   and ignored on iOS 17+, and our deployment target is 18.6, so FBSDK v18 reads
   `ATTrackingManager.trackingAuthorizationStatus` itself. Don't re-add that setter —
   it compiles with a deprecation warning and does nothing.

**Event names must stay byte-identical to Android** (`core/analytics/MetaEvents.kt`).
Ads Manager optimises per event *name*; a mismatch means one campaign cannot optimise
across both platforms, and it fails silently — no error, just wasted budget.

Two rules that apply to both platforms:
- **Never send raw user input as an event parameter.** Meta treats App Event parameters
  as Event Data usable for ad delivery, so free-text (search queries above all) can
  export a phone number or email a user typed. `logSearch` deliberately takes only a
  result count — no `.searchString`. IDs and our own display names are fine; anything
  the user typed is not.
- **Log a conversion only where the action truly succeeded.** `StartHiking` fires after
  `calculateRoutes` returns, not after the offline guard passes — otherwise GPS,
  waypoint-sanitisation and routing failures all count as starts.

Verify with `Settings.shared.enableLoggingBehavior(.appEvents)` (already on in DEBUG) →
look for `Created app event` in the log, and cross-check in Events Manager → Test Events.

## GraphQL / codegen

- Queries live in `Core/Network/GraphQL/Queries/queries.graphql`.
- After editing a `.graphql` file, regenerate:
  `./apollo-ios-cli generate --ignore-version-mismatch` (run from
  `Fielmedina-ios-v3/`; CLI/library version mismatch warning is expected and
  harmless).
- Backend resolvers for `locations` / `events` already accept `cityId`,
  `categoryId`, `limit`, `offset` — but per the offline-first rule above, don't wire
  those into per-filter network calls on list screens; they're fine for the
  prefetcher's own warm-up calls.

## Mapbox offline navigation (fragile — read before touching)

Currently on **mapbox-navigation-ios 3.28.3** (Maps 11.28.3, Common 24.28.3,
NavNative 324.28.3). SPM requirement is `upToNextMinorVersion` from 3.28.1, so patch
releases within 3.28.x are picked up automatically — a minor bump is deliberate.

Nav SDK has had breaking regressions across versions (worked at 3.19, broke at
3.20+), so **after any version bump, verify turn-by-turn on device**, not just that it
compiles. 3.26 → 3.28.3 was verified: map renders, route calculates, turn banner and
ETA display. Key fixes already in place, don't unwind them without understanding why:
- `OfflineTileStore.swift` pins one **explicit** TileStore path shared by map
  rendering, region downloads, and the nav engine — the SDK's default resolves a
  *different* location per consumer otherwise, silently splitting downloaded tiles
  from what the router can see.
- `NavigationTilesVersionStore` / `MapboxNavigationProviderStore.swift` pin the
  routing-tiles version explicitly — the SDK's "latest" resolution fails offline.
- `RouteWaypointSanitizer` (`Services/Navigation/`) cleans waypoints (drops invalid/
  `(0,0)`/duplicate points, caps at Mapbox's 25-coordinate limit) before they reach
  the router — malformed input can crash the onboard router natively (a Swift
  `catch` can't recover from that).
- Route-calculation fan-out must be **bounded concurrency** (max ~3 at once) and
  **debounced on GPS movement** (bucket coordinates to ~100m) — see
  `HikingListModel.updateMetrics()`. Unbounded "one route request per item" saturates
  the device and made the hiking list feel slow.

## Image loading

`Services/Cache/ImagePipeline.swift` + `Components/FielmedinaImage.swift` — decodes
images **downsampled to display size** (`CGImageSourceCreateThumbnailAtIndex`) and
**off the main thread**, with an in-memory `NSCache` of decoded bitmaps. Pass
`maxPixelSize:` explicitly for small thumbnails (list rows, search results) — the
default is sized for full-width hero images, and skipping this means a 44pt avatar
decodes a multi-MB photo.

## Build & test

```bash
xcodebuild -project Fielmedina.xcodeproj -scheme Fielmedina \
  -destination 'platform=iOS Simulator,id=<UDID>' -configuration Debug build
```

- `xcrun simctl location <UDID> set <lat>,<lon>` — fake GPS, required to test
  anything location-dependent (navigation, distance sort, hiking metrics) since the
  simulator has none by default.
- Install/launch: `xcrun simctl install <UDID> <path-to-.app>` then
  `xcrun simctl launch <UDID> com.dacnis.Fielmedina`.
- Bundle ID: `com.dacnis.Fielmedina`.
