# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ChargeLog is a native iOS app for tracking electric vehicle charging sessions, built with SwiftUI and SwiftData. UI language is German.

## Build & Test Commands

```bash
# List available schemes
xcodebuild -list

# Build for simulator
xcodebuild -scheme ChargeLog -configuration Debug -sdk iphonesimulator build

# Run tests
xcodebuild -scheme ChargeLog -destination 'platform=iOS Simulator,name=iPhone 16' test
```

The app targets iOS 26.2+. Open `ChargeLog.xcodeproj` in Xcode and use Cmd+R to run, Cmd+U to test.

## Architecture

**Stack**: SwiftUI + SwiftData (no external dependencies)

### Data Layer

`PersistenceManager.swift` is a singleton (`@Observable @MainActor`) that owns the SwiftData `ModelContainer`. It provides:
- `EmptyPersistencePreview` and `SampleDataPersistencePreview` modifiers for SwiftUI previews
- An in-memory configuration for tests

Three `@Model` classes in `Model/`:
- **ChargeSession**: A charging event with `startTime`, `endTime`, `energyKwh`, SoC percentages, odometer, and a `sessionStatus` enum (`running` / `finished` / `paid`). The `amount` (cost) is a transient computed property (energyKwh × pricePerKwh), not persisted.
- **ChargeStation**: Location with a `StationType` enum (`standardAC`, `fastDC`, `powerDC`) that carries display color and SF Symbol name.
- **ChargeTariff**: Pricing with `pricePerKwh` and `basePrice`.

### UI Layer

`MainView.swift` is a `TabView` with four tabs. The Sessions tab is fully implemented; Dashboard, Stations, and Settings are stubs.

Key views in `ChargeSessions/`:
- `ChargingSessionsListView` — main list, sorted newest-first via `@Query`
- `NewChargeSessionSheet` — initiates a session; prevents concurrent sessions
- `EndChargeSessionSheet` — completes a session; validates time range and odometer

Sheets for creating stations/tariffs (`NewChargeStationSheet`, `NewChargeTariffSheet`) can be presented inline from `NewChargeSessionSheet`.

### Decimal Input Convention

German locale uses comma as the decimal separator. Views convert user input (replacing `,` with `.`) before parsing `Double`/`Decimal` values.
