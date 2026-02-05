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
}
