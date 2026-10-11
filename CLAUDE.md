# TPE Flight Tracker

iOS app for tracking flights at Taiwan Taoyuan International Airport (TPE) with trip planning and AI-curated travel suggestions for visitors.

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

### Discover Taiwan (AI Trip Suggestions)
- Curated trip itineraries for first-time visitors
- 10 categories: First Time, Cultural, Foodie, Nature, Nightlife, Shopping, Family, Romantic, Adventure, Trending
- Multiple trip durations: Half Day, Full Day, Weekend, 3 Days, 1 Week
- Detailed destination info with local tips
- Budget levels and difficulty ratings
- One-tap add to personal trips
- Search across all suggestions

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
├── MainTabView.swift              # Tab navigation (Flights/Discover/Trips)
├── ContentView.swift              # Legacy view
├── Models/
│   ├── FlightModel.swift          # Flight, Airport, FlightStatus
│   ├── FlightViewModel.swift      # Flight list state management
│   └── Trip/
│       ├── TripModels.swift       # Trip, TripDestination, TravelMode
│       ├── TripSuggestionModels.swift  # Suggestion categories, destinations
│       └── TripViewModel.swift    # Trip state management
├── Views/
│   ├── FlightListView.swift       # Flight list UI
│   ├── FlightDetailView.swift     # Flight details UI
│   └── Trip/
│       ├── TripListView.swift     # Trip list UI
│       ├── TripDetailView.swift   # Trip details with map
│       ├── AddDestinationView.swift    # Location search
│       ├── TripSuggestionsView.swift   # Browse suggestions by category
│       └── SuggestionDetailView.swift  # Suggestion details with map
├── Services/
│   ├── APIConfig.swift            # API keys and rate limits
│   ├── AirLabsModels.swift        # AirLabs API response models
│   ├── AirportLookup.swift        # IATA code to airport mapping
│   ├── AirlineLookup.swift        # Airline code to name mapping
│   ├── FlightService.swift        # Flight data fetching
│   └── Trip/
│       ├── DirectionsService.swift     # MapKit directions
│       ├── TripService.swift           # Trip persistence
│       └── TripSuggestionService.swift # Curated trip suggestions

TPEFlightTrackerTests/
├── TestHelpers.swift              # Mocks and test data factories
├── FlightModelTests.swift         # Flight model tests
├── FlightViewModelTests.swift     # Flight VM tests
├── FlightServiceTests.swift       # Flight service tests
├── ViewRenderingTests.swift       # SwiftUI view tests
├── TripModelTests.swift           # Trip model tests
├── TripViewModelTests.swift       # Trip VM tests
├── TripServiceTests.swift         # Trip persistence tests
├── DirectionsServiceTests.swift   # Directions tests
└── TripSuggestionServiceTests.swift # Suggestion service tests
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
- `TripSuggestionServiceProtocol` - Trip suggestions

All services are injectable for testability.

## Suggestion Categories

| Category | Description |
|----------|-------------|
| First Time | Must-see attractions for newcomers |
| Cultural | Temples, museums, historic sites |
| Foodie | Street food, night markets, restaurants |
| Nature | Mountains, waterfalls, national parks |
| Nightlife | Night markets, entertainment areas |
| Shopping | Malls, markets, boutiques |
| Family | Kid-friendly attractions |
| Romantic | Scenic spots for couples |
| Adventure | Hiking, outdoor activities |
| Trending | Currently popular spots |

## Testing

90+ unit tests covering:
- Model initialization and Codable conformance
- ViewModel state management
- Service layer persistence
- Mock-based async operations
- Suggestion service and model tests

## Ticket Release Monitor (`ticket-monitor/`)

Standalone Python 3.11+ tool (separate from the iOS app) that polls Taiwanese ticketing sites
(tixCraft, KKTIX, plus generic keyword scanning of ibon/年代/遠大/OPENTIX/udn/FamiTicket) and
alerts on ticket releases (釋票) via console, ntfy, Telegram or Discord. Read-only: no login,
no auto-purchase. First target: 金智媛 WONEDERLAND Taipei (see `ticket-monitor/config.toml`).

- Run: `cd ticket-monitor && python -m ticket_monitor [--once | --discover-only]`
- Test: `cd ticket-monitor && python -m unittest discover -s tests -t .`
- Scheduled run: `.github/workflows/ticket-monitor.yml` (every 5 min, state kept in Actions cache)
