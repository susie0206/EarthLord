# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**EarthLord (地球新主)** is a location-based post-apocalyptic survival mobile game for iOS. Players claim territories in the real world by walking GPS paths, explore Points of Interest (POIs), gather resources, build structures, and interact with other survivors. The game combines SwiftUI, MapKit, and Supabase backend services.

**Theme**: "Hopepunk" - post-apocalyptic with hope and rebirth, featuring warm tones and green life emerging from gray ruins.

**Status**: Early development (Beta phase) - UI framework complete, core features in progress.

## Commands

### Build & Run

- **Build in Xcode**: `Cmd+B` or via Xcode menu
- **Run on Simulator**: `Cmd+R`
- **Clean Build**: `Cmd+Shift+K`

### Testing

- **Run Unit Tests**: `Cmd+U` or via Xcode Test Navigator
- **Run UI Tests**: Select `EarthLordUITests` scheme and run
- **Run Single Test**: Click diamond icon next to test function

### Xcode Operations

- **Open Project**: `open EarthLord.xcodeproj`
- **Project uses file system synchronization** - Xcode automatically reflects source directory changes

### Supabase Integration

- **Test Connection**: Run app → navigate to "更多" (More) tab → "Supabase 连接测试"
- **Database URL**: `https://absexnnamqwkqedaaamt.supabase.co`
- **Core tables created**: `profiles`, `territories`, `pois`
- **RLS enabled** on all tables with performance-optimized policies

## Architecture

### Navigation Flow

```
EarthLordApp (Entry point)
  └─ RootView (Navigation controller)
      ├─ SplashView (2.5s animated intro with breathing logo)
      └─ MainTabView (4-tab bottom navigation)
          ├─ MapTabView (Territory claiming & exploration)
          ├─ TerritoryTabView (Territory management)
          ├─ ProfileTabView (User profile & stats)
          └─ MoreTabView (Development tools & settings)
              └─ SupabaseTestView (Database connection test)
```

### Directory Structure

```
EarthLord/
├── Theme/
│   └── ApocalypseTheme.swift        # Centralized color system
├── Views/
│   ├── RootView.swift               # Root navigation with splash transition
│   ├── SplashView.swift             # Animated loading screen
│   ├── MainTabView.swift            # Tab-based main interface
│   └── Tabs/                        # Individual tab implementations
├── Components/
│   └── PlaceholderView.swift        # Reusable placeholder component
├── EarthLordApp.swift               # App entry point with SwiftData setup
└── Item.swift                       # Data model (placeholder from template)
```

### Key Architectural Patterns

**1. Theme System (ApocalypseTheme.swift)**

- All colors accessed through `ApocalypseTheme` enum
- "Hopepunk" aesthetic: warm oranges (#FF6619) on dark backgrounds (#141416)
- Centralized theme enables easy global style updates
- Color palette includes background, card, primary, text, and status colors

**2. State Management**

- `@State` for local view state
- `@Binding` for parent-child communication
- `@Query` (SwiftData) for persistent data
- Example: `RootView` uses `@State private var splashFinished` to control navigation

**3. Navigation Pattern**

- `RootView` manages app-level navigation (splash → main)
- `MainTabView` provides tab-based navigation
- Individual tabs use `NavigationView` for sub-navigation
- Smooth transitions with `.animation(.easeInOut)` and `.transition(.opacity)`

**4. Placeholder Pattern**

- `PlaceholderView` component for stub implementations
- Takes `icon`, `title`, and `subtitle` parameters
- Used extensively in placeholder tabs during development

**5. Data Persistence**

- SwiftData for local storage (modern CoreData replacement)
- ModelContainer created at app startup
- Currently uses `Item` model (template placeholder)
- Cloud sync via Supabase for multiplayer features

### Backend Integration (Supabase)

**Database Schema** (already migrated):

```sql
-- profiles: User profiles linked to auth.users
-- territories: GPS polygon data with path (JSONB), area, user_id
-- pois: Points of Interest with type enum, lat/lng, discovered_by
```

**Connection Pattern**:

```swift
let supabase = SupabaseClient(
    supabaseURL: URL(string: "https://absexnnamqwkqedaaamt.supabase.co")!,
    supabaseKey: "sb_publishable_-jUhdtSZdLOBoDMNfIZXZA_5E-UTaU5"
)
```

**Important**: Create service layer for Supabase interactions instead of direct instantiation in views.

## Game Design Context

### Core Game Loop

1. **Claim Territory**: Walk GPS path to create closed polygon → claim virtual land
2. **Explore POIs**: Visit real-world locations → gather resources
3. **Build Structures**: Use resources → construct buildings on territories
4. **Trade & Socialize**: Exchange resources → communicate via PTT (push-to-talk)
5. **Compete**: Rankings based on territory area, exploration, wealth

### Resource System

- **Survival**: Food, water, medical supplies
- **Construction**: Wood, metal, concrete, glass
- **Trading**: In-game currency, valuables
- **Special**: Tech components, rare materials
- Rarity levels: Common (gray) → Rare (blue) → Epic (purple) → Legendary (gold)

### POI Types (from GDD)

- Hospital (medical supplies, rare materials)
- Supermarket (food 60%, water 30%, currency 10%)
- Factory (metal, parts, blueprints)
- Gas Station (fuel, tools, parts)
- Military Base (advanced equipment, rare 72h cooldown)

### Territory Rules

- Minimum area: 1000 m²
- Maximum area: 100,000 m² (0.1 km²)
- No overlapping territories
- 24-hour claiming cooldown
- Max 5 territories per user (expandable)

## Development Guidelines

### When Adding Features

**Always read existing code first** before making changes. The codebase uses specific patterns:

- Theme colors from `ApocalypseTheme` enum
- Composition-based SwiftUI views
- Navigation through state management, not complex routers
- Placeholder components for rapid prototyping

**For new screens**:

1. Create in `Views/` or appropriate subdirectory
2. Use `ApocalypseTheme` for all colors
3. Follow existing navigation patterns
4. Use `PlaceholderView` for incomplete sections

**For data models**:

1. Define SwiftData `@Model` classes for local storage
2. Mirror Supabase schema for cloud-synced data
3. Use Codable for API serialization
4. Implement local-first strategy (update local → sync to cloud)

**For Supabase integration**:

1. Create service layer (e.g., `TerritoryService`, `POIService`)
2. Use async/await for database operations
3. Handle RLS (Row Level Security) policies properly
4. Test with SupabaseTestView before production use

### Code Style

**SwiftUI Views**:

- Keep views focused and single-purpose
- Extract complex logic to computed properties or ViewModels
- Use `private` modifiers appropriately
- Prefer composition over inheritance

**Naming Conventions**:

- Views: `SomethingView` (e.g., `MapTabView`)
- Models: `Something` (e.g., `Territory`)
- Services: `SomethingService` (e.g., `AuthService`)
- Theme colors: lowercase with underscores (e.g., `background`, `text_primary`)

### Testing

**Unit Tests** (EarthLordTests):

- Currently uses Swift Testing framework (new in Swift 6)
- Structure: Empty placeholder test exists
- Add tests for business logic, not SwiftUI views

**UI Tests** (EarthLordUITests):

- Uses XCTest framework
- Includes launch performance measurement
- Test critical user flows (login, territory claiming)

## Technical Stack

### Frontend

- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Minimum iOS**: 16.0+
- **Maps**: MapKit
- **Location**: CoreLocation
- **Storage**: SwiftData (local), Supabase (cloud)
- **Networking**: Async/await with URLSession
- **Payments**: StoreKit 2 (planned)

### Backend

- **Platform**: Supabase (BaaS)
- **Database**: PostgreSQL 15+ with PostGIS extension
- **Authentication**: Supabase Auth (OAuth support planned)
- **Realtime**: Supabase Realtime for chat/updates
- **Storage**: Supabase Storage for assets
- **Functions**: Supabase Edge Functions (Deno runtime)

### Dependencies

- **supabase-swift** v2.39.0
- Indirect: swift-crypto, swift-http-types, swift-concurrency-extras

## Common Development Scenarios

### Adding a New Tab

1. Create new view in `Views/Tabs/` (e.g., `MarketTabView.swift`)
2. Add to `MainTabView.swift` with appropriate SF Symbol icon
3. Apply theme colors from `ApocalypseTheme`
4. Update tab bar tint color if needed

### Implementing Territory Claiming

1. Use CoreLocation to track GPS path
2. Store path as array of coordinates (lat/lng pairs)
3. Validate closed polygon (start point = end point within tolerance)
4. Calculate area using PostGIS `ST_Area` function
5. Check overlap with `ST_Intersects`
6. Store in `territories` table with JSONB path data

### Integrating POI Discovery

1. Query nearby POIs using PostGIS distance functions
2. Implement geofencing with CoreLocation
3. Trigger discovery when user within 50m of POI
4. Check cooldown in `poi_loots` table (24-72h depending on type)
5. Generate random loot based on POI type and rarity

### Adding Building System

1. Create building types enum matching POI types
2. Store building instances linked to territory_id
3. Implement construction queue with timestamps
4. Add resource collection mechanism (tap to collect)
5. Support upgrade system (building levels)

## Project Documentation

**Product Requirements**: See `PRD_地球新主.md` for detailed feature specs, user stories, acceptance criteria, and technical requirements.

**Game Design**: See `GDD_地球新主.md` for game mechanics, narrative, art style, core loops, and balancing.

**Key Documents Sections**:

- Territory claiming rules and validation
- POI types, loot tables, cooldowns
- Building types, construction costs, production rates
- Trading system with market listings
- PTT (Push-to-Talk) communication system
- Achievement and leaderboard logic
- Subscription tiers and IAP items

## Git Workflow

**Current Branch**: `feature/test-demo`
**Main Branch**: Not set (check with team)

**Recent History**:

- Day 01: UI framework + apocalypse theme
- Added TestView feature
- Added documentation (PRD/GDD)
- Initial commit

**Uncommitted Changes**:

- `EarthLord.xcodeproj/project.pbxproj` (Supabase integration)
- `.xcworkspace/xcshareddata/` (new workspace data)

## Known Issues & Considerations

1. **Security**: Supabase publishable key is hardcoded in `SupabaseTestView.swift` - move to secure configuration for production
2. **Data Model**: `Item.swift` is a template placeholder - replace with actual game models
3. **Localization**: Currently mixed Chinese/English text - implement proper i18n
4. **Error Handling**: Minimal error handling in place - expand as features grow
5. **Theme Switching**: Architecture supports it, but only static theme implemented
6. **GPS Accuracy**: Need to implement drift detection and manual correction (see GDD risk mitigation)
7. **Anti-cheat**: Plan for GPS spoofing detection and automated behavior analysis

## Future Architecture Evolution

As complexity grows, consider:

```
Views (SwiftUI)
  ↓
ViewModels (State management, business logic)
  ↓
Services (API calls, GPS tracking, data fetching)
  ↓
Repository (Data persistence abstraction layer)
  ↓
Models (Data structures with Codable/SwiftData)
```

Current pattern is composition-based SwiftUI without strict MVVM, which works well for early development. Refactor to proper MVVM when business logic complexity increases.

## Support & Resources

- **Xcode Version**: 26.2
- **Swift Version**: 5.x (latest)
- **Supabase Docs**: https://supabase.com/docs
- **MapKit Docs**: https://developer.apple.com/documentation/mapkit
- **Apple HIG**: https://developer.apple.com/design/human-interface-guidelines/

---

**Last Updated**: 2025-12-26
**Document Owner**: Development Team
**Status**: Living document - update as architecture evolves
