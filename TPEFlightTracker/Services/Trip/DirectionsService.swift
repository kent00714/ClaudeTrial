import Foundation
import CoreLocation

protocol DirectionsServiceProtocol {
    func calculateRoute(
        from origin: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D,
        mode: TravelMode
    ) async throws -> RouteResult
}

struct RouteResult {
    let distanceMeters: Int
    let durationSeconds: Int
    let polyline: String?

    var durationMinutes: Int {
        durationSeconds / 60
    }
}

class DirectionsService: DirectionsServiceProtocol {

    private let session: URLSession
    private let apiKey: String

    init(
        session: URLSession = .shared,
        apiKey: String = APIConfig.googleMapsAPIKey
    ) {
        self.session = session
        self.apiKey = apiKey
    }

    func calculateRoute(
        from origin: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D,
        mode: TravelMode
    ) async throws -> RouteResult {
        // Fall back to mock/estimate if no API key configured
        guard apiKey != "YOUR_GOOGLE_API_KEY_HERE" else {
            return estimateRoute(from: origin, to: destination, mode: mode)
        }

        let originStr = "\(origin.latitude),\(origin.longitude)"
        let destStr = "\(destination.latitude),\(destination.longitude)"

        var components = URLComponents(string: APIConfig.googleDirectionsBaseURL)!
        components.queryItems = [
            URLQueryItem(name: "origin", value: originStr),
            URLQueryItem(name: "destination", value: destStr),
            URLQueryItem(name: "mode", value: mode.googleMapsMode),
            URLQueryItem(name: "key", value: apiKey)
        ]

        guard let url = components.url else {
            throw DirectionsError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw DirectionsError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw DirectionsError.httpError(statusCode: httpResponse.statusCode)
        }

        let decoded = try JSONDecoder().decode(GoogleDirectionsResponse.self, from: data)

        guard decoded.status == "OK",
              let route = decoded.routes.first,
              let leg = route.legs.first else {
            throw DirectionsError.noRouteFound(status: decoded.status)
        }

        return RouteResult(
            distanceMeters: leg.distance.value,
            durationSeconds: leg.duration.value,
            polyline: route.overviewPolyline.points
        )
    }

    // MARK: - Fallback Estimation (no API key)

    private func estimateRoute(
        from origin: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D,
        mode: TravelMode
    ) -> RouteResult {
        let originLoc = CLLocation(latitude: origin.latitude, longitude: origin.longitude)
        let destLoc = CLLocation(latitude: destination.latitude, longitude: destination.longitude)
        let straightLineMeters = originLoc.distance(from: destLoc)

        // Rough estimate: actual road distance is ~1.3x straight line
        let estimatedDistance = Int(straightLineMeters * 1.3)

        // Estimate speed based on mode
        let speedKmh: Double
        switch mode {
        case .driving: speedKmh = 40 // city average
        case .walking: speedKmh = 5
        case .bicycling: speedKmh = 15
        case .transit: speedKmh = 25
        }

        let durationSeconds = Int((Double(estimatedDistance) / 1000.0 / speedKmh) * 3600)

        return RouteResult(
            distanceMeters: estimatedDistance,
            durationSeconds: durationSeconds,
            polyline: nil
        )
    }
}

// MARK: - Errors

enum DirectionsError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case noRouteFound(status: String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid directions URL"
        case .invalidResponse:
            return "Invalid response from directions service"
        case .httpError(let code):
            return "Directions API error (HTTP \(code))"
        case .noRouteFound(let status):
            return "No route found: \(status)"
        }
    }
}

// MARK: - Google Directions API Response Models

struct GoogleDirectionsResponse: Codable {
    let status: String
    let routes: [GoogleRoute]
}

struct GoogleRoute: Codable {
    let legs: [GoogleLeg]
    let overviewPolyline: GooglePolyline

    enum CodingKeys: String, CodingKey {
        case legs
        case overviewPolyline = "overview_polyline"
    }
}

struct GoogleLeg: Codable {
    let distance: GoogleValue
    let duration: GoogleValue
    let startAddress: String?
    let endAddress: String?

    enum CodingKeys: String, CodingKey {
        case distance
        case duration
        case startAddress = "start_address"
        case endAddress = "end_address"
    }
}

struct GoogleValue: Codable {
    let text: String
    let value: Int
}

struct GooglePolyline: Codable {
    let points: String
}
