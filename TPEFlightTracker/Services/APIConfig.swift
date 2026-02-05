import Foundation

enum APIConfig {
    // MARK: - AirLabs (Flight Tracking)

    /// AirLabs API key. Get a free key at https://airlabs.co/
    /// Free tier: 1,000 requests/month.
    ///
    /// Set your key here or via the AIRLABS_API_KEY environment variable.
    static var airLabsAPIKey: String {
        if let envKey = ProcessInfo.processInfo.environment["AIRLABS_API_KEY"], !envKey.isEmpty {
            return envKey
        }
        // Replace with your actual API key
        return "YOUR_API_KEY_HERE"
    }

    static let airLabsBaseURL = "https://airlabs.co/api/v9"
    static let airportCode = "TPE"

    // MARK: - AirLabs Rate Budget

    /// Free tier: 1,000 requests/month
    static let monthlyRequestLimit = 1000
    /// Each refresh calls 2 endpoints (arrivals + departures)
    static let requestsPerRefresh = 2
    /// Spread evenly across 30 days: 1000 / 2 / 30 ≈ 16 refreshes/day
    /// 24h * 60min / 16 ≈ 90 minutes between refreshes
    static let autoRefreshInterval: TimeInterval = 90 * 60 // 90 minutes

    // MARK: - Google Maps (Trip Planning)

    /// Google Maps API key. Get a free key at https://console.cloud.google.com/
    /// Free tier: $200/month credit (~40,000 Directions API calls).
    ///
    /// Set your key here or via the GOOGLE_MAPS_API_KEY environment variable.
    /// Required APIs: Directions API, Places API, Geocoding API
    static var googleMapsAPIKey: String {
        if let envKey = ProcessInfo.processInfo.environment["GOOGLE_MAPS_API_KEY"], !envKey.isEmpty {
            return envKey
        }
        // Replace with your actual API key
        return "YOUR_GOOGLE_API_KEY_HERE"
    }

    static let googleDirectionsBaseURL = "https://maps.googleapis.com/maps/api/directions/json"
    static let googlePlacesBaseURL = "https://maps.googleapis.com/maps/api/place"
    static let googleGeocodingBaseURL = "https://maps.googleapis.com/maps/api/geocode/json"
}
