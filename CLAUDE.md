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

Currently on **mapbox-navigation-ios 3.32.0** (Maps 11.32.0, Common 24.32.0,
NavNative 324.32.0). SPM requirement is `upToNextMinorVersion` from 3.32.0, so patch
releases within 3.32.x are picked up automatically — a minor bump is deliberate.

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
- The pin may only point at a version **every** downloaded region has fully on disk.
  Per-region records (`offline_nav_region_versions`) are trimmed when a region load
  starts and set when it succeeds; the pin moves to the newest version common to all
  regions. Every region load includes the pinned and runtime versions next to the
  latest one. `prepareNavigationForLaunch()` reconciles the pin against the TileStore
  before the navigation provider is created. The old code moved the pin when a refresh
  *started*: an interrupted refresh left the router pinned to tiles that were never
  downloaded, offline navigation stayed dead for a week, and users had to remove and
  re-download their city.
- Never wipe the tile store when the Mapbox SDK version changes. Regions and style
  packs survive SDK upgrades; `OfflineTileStore` only schedules a region refresh. The
  previous wipe deleted every user's offline maps on each app update that bumped
  Mapbox.
- `MapboxNavigationProviderStore.shared` is `@MainActor` and calls
  `getLatestNavigationTilesetDescriptor()` right after creating the provider. It looks
  like dead code but forces the SDK's shared `NativeHandlersFactory` (unsynchronised
  `lazy var`s, `@unchecked Sendable`) to initialise once on the main thread. Without
  it, `HikingListModel`'s parallel route requests raced on first use and crashed in
  `MapboxRoutingProvider.routerClient` (unrecognized selector). Still unfixed upstream
  as of 3.33.0-rc.1.
- `RouteWaypointSanitizer` (`Services/Navigation/`) cleans waypoints (drops invalid/
  `(0,0)`/duplicate points, caps at Mapbox's 25-coordinate limit) before they reach
  the router — malformed input can crash the onboard router natively (a Swift
  `catch` can't recover from that).
- Route-calculation fan-out must be **bounded concurrency** (max ~3 at once) and
  **debounced on GPS movement** (bucket coordinates to ~100m) — see
  `HikingListModel.updateMetrics()`. Unbounded "one route request per item" saturates
  the device and made the hiking list feel slow.

## iPhone Duo (foldable) layout

Follows Apple's HIG "Designing for iPhone Duo". On the outer display and the inner
display in landscape the system puts the tab bar, toolbar and status bar on the side,
so safe areas are asymmetric.

- Never put `.ignoresSafeArea(edges: .horizontal)` on a scroll view or any container of
  controls: it pushed every "Show All", the search bar and cards under the side tab bar.
  Only backgrounds may bleed — `HeroBanner` ignores the horizontal safe area itself, and
  detail-page panels draw their rounded background with `.ignoresSafeArea(edges:
  .horizontal)` inside `.background { }` while the content stays inset.
- Toolbar items are separate items in a `ToolbarItemGroup`, each a `Label` with a title
  and a symbol (see `SettingsButton`, Home's sticky shortcuts). Never wrap several items in
  one `HStack`: the system can't lay it out vertically.
- No fixed screen-width layouts: carousels (`CarouselListMerchants`, `CarouselListEvent`)
  stretch their cards to fill the row when there are too few to scroll.
- The system hides the side toolbar while content scrolls down and shows it again on
  scroll up — expected, not a bug.
- Test on an "iPhone Duo" simulator (Xcode 27.1). `simctl` cannot fold/unfold; the inner
  display is 951×669 pt in landscape.

## App review prompt (`Services/Review/AppReviewPrompter.swift`)

StoreKit's `AppStore.requestReview(in:)` only. App Store guideline 5.6.1 disallows
custom review prompts, so never add a pre-prompt alert. Same rules as Android
(`core/review/AppReviewPrompter.kt`): significant events are a place/walk arrival, an
audio guide played to the end and an offline city download; the request fires after
navigation is closed following an arrival, or 3 s after the app becomes active, and
only with ≥3 active days, ≥2 events, a new event since the last request, 120 days since
the last request, a new app version and a connection. iOS itself caps the dialog at 3
per year and always shows it in development builds. Settings has a "Rate Fielmedina"
row that opens `?action=write-review` on the App Store.

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
