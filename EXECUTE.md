# Build and Test Instructions

## Prerequisites

- macOS 14.0 (Sonoma) or later
- Xcode 15.0 or later
- Apple Developer account (free tier is sufficient for simulator testing)

## Setup

### 1. Clone the Repository

```bash
git clone <repository-url>
cd ClaudeTrial
```

### 2. Configure API Key (Optional)

For real-time flight data, you need an AirLabs API key:

1. Sign up at https://airlabs.co/ (free tier: 1,000 requests/month)
2. Set the API key using one of these methods:

**Option A: Environment Variable (Recommended)**
```bash
export AIRLABS_API_KEY="your_api_key_here"
```

Or in Xcode:
- Edit Scheme → Run → Arguments → Environment Variables
- Add `AIRLABS_API_KEY` with your key

**Option B: Direct Edit**
- Open `TPEFlightTracker/Services/APIConfig.swift`
- Replace `"YOUR_API_KEY_HERE"` with your actual key

> **Note**: Without an API key, the app will use mock flight data.

## Building

### Using Xcode

1. Open the project:
```bash
open TPEFlightTracker.xcodeproj
```

2. Select a simulator or device from the scheme selector (e.g., "iPhone 15 Pro")

3. Build the project:
   - Press `Cmd + B` or
   - Menu: Product → Build

### Using Command Line

```bash
# Build for simulator
xcodebuild -project TPEFlightTracker.xcodeproj \
           -scheme TPEFlightTracker \
           -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
           build

# Build for device (requires signing)
xcodebuild -project TPEFlightTracker.xcodeproj \
           -scheme TPEFlightTracker \
           -destination 'generic/platform=iOS' \
           build
```

## Running Tests

### Using Xcode

1. Open the project in Xcode
2. Run all tests:
   - Press `Cmd + U` or
   - Menu: Product → Test

3. Run specific test file:
   - Open the test file in the editor
   - Click the diamond icon next to the test class or method

### Using Command Line

```bash
# Run all tests
xcodebuild test \
    -project TPEFlightTracker.xcodeproj \
    -scheme TPEFlightTracker \
    -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Run with verbose output
xcodebuild test \
    -project TPEFlightTracker.xcodeproj \
    -scheme TPEFlightTracker \
    -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
    -resultBundlePath TestResults.xcresult

# View test results
xcrun xcresulttool get --path TestResults.xcresult --format json
```

## Running the App

### On Simulator

1. Open Xcode and select a simulator
2. Press `Cmd + R` or click the Play button
3. The app will launch in the iOS Simulator

### On Physical Device

1. Connect your iPhone via USB
2. Select your device from the scheme selector
3. You may need to:
   - Trust the developer certificate on your device (Settings → General → Device Management)
   - Sign the app with your Apple ID in Xcode (Signing & Capabilities)
4. Press `Cmd + R` to build and run

## Test Coverage

The project includes 75+ unit tests:

| Test File | Coverage |
|-----------|----------|
| FlightModelTests | Flight, Airport, FlightStatus models |
| FlightViewModelTests | Flight list state, filtering, refresh |
| FlightServiceTests | API calls, mock data fallback |
| ViewRenderingTests | SwiftUI view instantiation |
| TripModelTests | Trip, TripDestination, TravelMode |
| TripViewModelTests | CRUD, destinations, route calculation |
| TripServiceTests | UserDefaults persistence |
| DirectionsServiceTests | RouteResult, mock directions |

## Troubleshooting

### Build Errors

**"No such module 'TPEFlightTracker'"**
- Clean build folder: `Cmd + Shift + K`
- Rebuild: `Cmd + B`

**Signing errors**
- Open project settings → Signing & Capabilities
- Select your team or personal Apple ID
- Enable "Automatically manage signing"

### Test Failures

**Tests timeout**
- Some tests are async; ensure simulator is running
- Try running tests individually

**"Failed to load bundle"**
- Clean derived data:
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData
```

### Runtime Issues

**No flight data showing**
- Check API key configuration
- Verify network connectivity
- App falls back to mock data if API fails

**Map not loading**
- MapKit requires network access
- Check simulator/device has internet connection

## Project Configuration

| Setting | Value |
|---------|-------|
| iOS Deployment Target | 17.0 |
| Swift Version | 5.0 |
| Xcode Version | 15.0+ |
| Bundle Identifier | com.example.TPEFlightTracker |
