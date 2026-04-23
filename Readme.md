# Fielmedina iOS App v2.0 - Architecture

## Overview

Fielmedina is a modern iOS application built with SwiftUI, focusing on cultural events, locations, and hiking experiences in Tunisia. The app utilizes Apollo GraphQL for live data and is designed with a "Concurrency-First" approach using Swift 6.

## Project Structure

```bash
Fielmedina/
├── App/
│   └── FielmedinaApp.swift           # Application Entry Point & Delegate
├── Components/                       # Reusable UI Components
│   └── Ui/
│       ├── Events/                   # EventCard, EventItem, CarouselList
│       ├── Locations/                # LocationCard, LocationItem, CarouselListLocations
│       ├── Tips/                     # TipsCarousel, TipItem
│       ├── Hiking/                   # HikingMetricView, RouteOverlays
│       ├── FielmedinaImage.swift     # Dual-source (URL/Local) Image Component
│       └── SettingsButton.swift
├── Core/
│   ├── Features/                     # Main Feature Views
│   │   ├── Home/                     # Landing & Discovery
│   │   ├── Events/                   # Event Browsing & Details
│   │   ├── Locations/                # POI Discovery
│   │   ├── Hiking/                   # Hiking List, Navigator, Mapbox Bridge
│   │   ├── Map/                      # Global Exploration Map
│   │   ├── Transports/               # Public Transport Schedules
│   │   ├── AR/                       # Augmented Reality Experiences
│   │   ├── Profile/                  # Settings, Preferences, Offline Maps
│   │   └── Utils/                    # View Modifiers & Logic Helpers
│   ├── Network/
│   │   └── GraphQL/                  # Apollo Schema & .graphql Operations
│   ├── Security/                     # KeychainStore & API Interceptors
│   ├── Notifications/                # Push & Local Location Management
│   └── Extensions/                   # Native Type Extensions (Date, String, etc.)
├── Services/
│   ├── API/
│   │   ├── Models/                   # Pure Swift Domain Models (Decoupled from GraphQL)
│   │   ├── Sync/                     # Device Registration & Logic Sync
│   │   ├── data/                     # Mock data & Static providers
│   │   └── ...Service.swift          # Feature-specific API managers
│   ├── Offline/                      # Mapbox TileStore & Region Management
│   ├── Cache/                        # URLCache Config & Content Prefetcher
│   ├── Navigation/                   # Mapbox Routing Provider Stores
│   ├── Analytics/                    # Firebase & Crashlytics Integration
│   └── Locale/                       # Multilingual Logic (EN/FR)
└── Assets.xcassets                   # Thematic Media & SF Symbol Markers
```

## GraphQL & Data Flow

### Apollo iOS 2.0 Integration

The app uses the latest Apollo iOS 2.0.4 framework.

- **Code Generation**: Driven by `apollo-ios-cli`.
- **Namespace**: All generated types are under the `FielmedinaAPI` namespace.
- **Workflow**: Edit `.graphql` files in `Core/Network/GraphQL` and run `./apollo-ios-cli generate`.

### Live Data Services

Data is fetched asynchronously using native Swift concurrency.

- **EventService**: Centralized fetcher for individual and city-based events.
- **FielmedinaImage**: A smart image component that handles both remote URLs and local fallback assets (e.g., `event-e`).

## Architecture Patterns

### 1. Swift 6 Concurrency

We use `async/await` and `Actors` throughout the service layer to ensure thread safety and smooth UI performance.

### 2. Observation Framework

State management is handled using the modern `@Observable` macro (iOS 17+), replacing the legacy `ObservableObject` pattern.

### 3. Localization

The app supports English and French using modern **String Catalogs** (`.xcstrings`). Text is dynamically selected based on the user's system language via `displayName` properties in models.

### 4. Security & Persistence

- **KeychainStore**: Sensitive data like `deviceUUID` and `fcmToken` are stored securely in the iOS Keychain.
- **Security Interceptors**: API requests automatically include security headers (`X-Device-ID`) via Apollo interceptors.

### 5. Offline Mobility

- **OfflineMapsManager**: Manages Mapbox style packs and tile regions. Tracks active downloads and notifies the UI in real-time.
- **OfflineContentPrefetcher**: High-performance background prefetcher for Apollo data and media assets.
- **Hybrid Metrics**: Hiking metrics (duration/distance) automatically switch to the Navigation SDK's offline routing engine when disconnected.

## How to Build

1. **Dependencies**: Managed via Swift Package Manager (Apollo, Firebase, Mapbox).
2. **Configuration**: Ensure `GoogleService-Info.plist` is present.
3. **GraphQL**: Run `./apollo-ios-cli generate` to ensure all API models are up to date.
4. **Build**: Use Xcode 16+ / iOS 18+ Target.

## Developer Guide & Onboarding

This section is designed to help new engineers (especially interns) understand the project's design patterns and workflows.

### 1. The GraphQL Workflow (Local to Live)

We decouple our UI from the network layer. **Never** use generated `FielmedinaAPI` types directly in your Views.

1. **Define Operation**: Create or edit a `.graphql` file in `Core/Network/GraphQL/Queries/`.
2. **Generate**: Run the following in the project root:

    ```bash
    ./apollo-ios-cli generate
    ```

3. **Model Mapping**:
    - Create/Update a domain model in `Services/API/Models/` (e.g., `Event.swift`).
    - Add an extension to your model with a `convenience init` or `init` that accepts the specific `FielmedinaAPI` fragment or data type.
4. **Service Integration**: Implement a method in a `Service` class (e.g., `EventService`) that:
    - Calls `Network.shared.apollo.fetch(query: MyQuery())`.
    - Maps the response to your domain models using `.map { Event(from: $0) }`.

### 2. State & UI Architecture (MVVM+S)

We strictly follow the **Model-View-ViewModel + Services** pattern.

- **Models**: Pure data structures. Use `computed properties` for presentation logic (like date formatting or price strings).
- **Services**: Singletons or Actors that manage the heavy lifting (API fetching, Keychain security, File system).
- **ViewModels**: Marked with the `@Observable` macro. They orchestrate data flow from Services to the UI.
- **Views**: Declarative SwiftUI. They should only respond to state and pass user actions to the ViewModel.

### 3. Navigation & Mapbox (UIKit-SwiftUI Bridge)

Mapbox is a UIKit-based SDK. We bridge it using a "Logic-Visual" separation:

- **The Navigator (`HikingNavigator.swift`)**: A SwiftUI view that manages the **session state**. It handles loading timers, error screens, and saving progress to disk.
- **The Bridge (`MapboxHikingNavigationView.swift`)**: A `UIViewControllerRepresentable` that holds the Mapbox `NavigationViewController`.
- **The Coordinator**: An internal class that acts as the `NavigationViewControllerDelegate`. It translates UIKit events (like "user arrived at destination") into SwiftUI state changes.

### 4. Offline Map & Content Management

The app targets travelers in low-connectivity areas. Our offline system has two parts:

1. **Map Data**: Managed by `OfflineMapsManager`. It handles Style Packs (colors/icons) and Tile Regions (vector data). We use a global notification system (`.tileRegionProgressChanged`) to keep the UI updated.
2. **Content Data**: Managed by `OfflineContentPrefetcher`. It warms the Apollo cache and downloads images for events/locations so the app feels 100% functional without 4G.

## Architecture Highlights & Standards

- **Concurrency**: Always use `async/await` or `TaskGroup` for parallel loading. Never block the main thread.
- **Images**: Use `FielmedinaImage`. It automatically checks for bundled "fallback" assets before attempting a network download.
- **Security**: Anything sensitive (User IDs, Tokens) **must** be stored in `KeychainStore`. Non-sensitive state (Hike progress, City ID) goes to `UserDefaults`.
- **Localization**: Use `String(localized: "Key")` for code strings. This ensures they are automatically extracted into `Localizable.xcstrings`.

## Troubleshooting Common Issues

- **Codegen Errors**: If `FielmedinaAPI` types aren't found, check for syntax errors in your `.graphql` files and regenerate.
- **Module Import Errors**: Do **not** `import FielmedinaAPI`. The code is generated directly into the main target's namespace.
- **Simulating Hikes**: Use the Xcode Simulator's `Features > Location` menu to test navigation logic without leaving your desk.

---
*Developed by Muhammad Aslan & The Fielmedina Engineering Team - 2025-2026* 🚀
