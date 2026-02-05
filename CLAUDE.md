# TPE Flight Tracker

iOS app for tracking flights at Taiwan Taoyuan International Airport (TPE) with trip planning features.

## Project Overview

- **Platform**: iOS 17.0+
- **Language**: Swift 5.0
- **UI Framework**: SwiftUI
- **Architecture**: MVVM with protocol-based dependency injection

## Features

### Flight Tracking
- Real-time arrivals and departures at TPE airport
- AirLabs API integration (1,000 free requests/month)
- Auto-refresh every 90 minutes (budgeted for free tier)
- Search by flight number, airline, or city
- Flight details including terminal, gate, status

### Trip Arrangement
- Create and manage trips with multiple destinations
- Apple MapKit integration for route calculation (free, no API key)
- Travel time and distance between destinations
- Support for driving, walking, bicycling, and transit modes
- Persistent storage via UserDefaults

## Project Structure

```
TPEFlightTracker/
├── TPEFlightTrackerApp.swift      # App entry point
├── MainTabView.swift              # Tab navigation (Flights/Trips)
├── ContentView.swift              # Legacy view
├── Models/
│   ├── FlightModel.swift          # Flight, Airport, FlightStatus
│   ├── FlightViewModel.swift      # Flight list state management
│   └── Trip/
│       ├── TripModels.swift       # Trip, TripDestination, TravelMode
│       └── TripViewModel.swift    # Trip state management
├── Views/
│   ├── FlightListView.swift       # Flight list UI
│   ├── FlightDetailView.swift     # Flight details UI
│   └── Trip/
│       ├── TripListView.swift     # Trip list UI
│       ├── TripDetailView.swift   # Trip details with map
│       └── AddDestinationView.swift # Location search
├── Services/
│   ├── APIConfig.swift            # API keys and rate limits
│   ├── AirLabsModels.swift        # AirLabs API response models
│   ├── AirportLookup.swift        # IATA code to airport mapping
│   ├── AirlineLookup.swift        # Airline code to name mapping
│   ├── FlightService.swift        # Flight data fetching
│   └── Trip/
│       ├── DirectionsService.swift # MapKit directions
│       └── TripService.swift       # Trip persistence

TPEFlightTrackerTests/
├── TestHelpers.swift              # Mocks and test data factories
├── FlightModelTests.swift         # Flight model tests
├── FlightViewModelTests.swift     # Flight VM tests
├── FlightServiceTests.swift       # Flight service tests
├── ViewRenderingTests.swift       # SwiftUI view tests
├── TripModelTests.swift           # Trip model tests
├── TripViewModelTests.swift       # Trip VM tests
├── TripServiceTests.swift         # Trip persistence tests
└── DirectionsServiceTests.swift   # Directions tests
```

## API Configuration

### AirLabs (Flight Data)
- Free tier: 1,000 requests/month
- Set API key via `AIRLABS_API_KEY` environment variable
- Or edit `APIConfig.swift` directly
- Auto-refresh: 90-minute intervals to stay within budget

### Apple MapKit (Directions)
- Completely free, no API key required
- Supports driving, walking, and transit
- Bicycling falls back to walking (not supported by MapKit)

## Key Protocols

- `FlightServiceProtocol` - Flight data fetching
- `TripServiceProtocol` - Trip CRUD operations
- `DirectionsServiceProtocol` - Route calculation

All services are injectable for testability.

## Testing

75+ unit tests covering:
- Model initialization and Codable conformance
- ViewModel state management
- Service layer persistence
- Mock-based async operations
