# CLAUDE.md

This file provides guidance for Claude Code when working with this repository.

## Project Overview

TPE Flight Tracker is a Swift iOS app built with SwiftUI that provides real-time flight tracking for Taipei Taoyuan International Airport (TPE) and trip planning functionality.

## Tech Stack

- **Language**: Swift
- **UI Framework**: SwiftUI (iOS 16+)
- **Architecture**: MVVM with dependency injection
- **Mapping**: MapKit + Google Directions API
- **Testing**: XCTest

## Project Structure

```
TPEFlightTracker/
├── TPEFlightTrackerApp.swift    # App entry point (@main)
├── MainTabView.swift            # Tab navigation (Flights/Trips)
├── Models/                      # Data models (Flight, Trip)
├── Views/                       # SwiftUI views
├── Services/                    # API integrations & business logic
│   ├── APIConfig.swift          # API keys & rate limiting config
│   ├── FlightService.swift      # AirLabs API integration
│   ├── FlightViewModel.swift    # Flight state management
│   └── Trip/                    # Trip-related services
└── Assets.xcassets

TPEFlightTrackerTests/           # Unit tests
```

## External APIs

| API | Environment Variable | Purpose |
|-----|---------------------|---------|
| AirLabs | `AIRLABS_API_KEY` | Real-time flight data |
| Google Maps | `GOOGLE_MAPS_API_KEY` | Route directions & place search |

API keys are configured in `Services/APIConfig.swift`. The app falls back to mock data when keys are not configured.

## Build & Test Commands

```bash
# Build the project
xcodebuild -project TPEFlightTracker.xcodeproj -scheme TPEFlightTracker -destination 'platform=iOS Simulator,name=iPhone 15' build

# Run tests
xcodebuild -project TPEFlightTracker.xcodeproj -scheme TPEFlightTracker -destination 'platform=iOS Simulator,name=iPhone 15' test
```

## Key Files

- `Services/APIConfig.swift` - API configuration and rate limiting
- `Services/FlightService.swift` - Flight data fetching (protocol-based for DI)
- `Services/Trip/DirectionsService.swift` - Route calculation
- `Services/Trip/TripService.swift` - Trip persistence (UserDefaults)
- `Models/FlightModel.swift` - Core flight data models
- `Models/Trip/TripModels.swift` - Trip and destination models

## Architecture Notes

- ViewModels use `@MainActor` for thread safety
- Services use protocols for dependency injection and testability
- Flight auto-refresh is budgeted for AirLabs free tier (90-minute intervals)
- All times displayed in Asia/Taipei timezone
