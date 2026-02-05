import Foundation

enum APIConfig {
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

    // MARK: - Rate Budget

    /// Free tier: 1,000 requests/month
    static let monthlyRequestLimit = 1000
    /// Each refresh calls 2 endpoints (arrivals + departures)
    static let requestsPerRefresh = 2
    /// Spread evenly across 30 days: 1000 / 2 / 30 ≈ 16 refreshes/day
    /// 24h * 60min / 16 ≈ 90 minutes between refreshes
    static let autoRefreshInterval: TimeInterval = 90 * 60 // 90 minutes
}
