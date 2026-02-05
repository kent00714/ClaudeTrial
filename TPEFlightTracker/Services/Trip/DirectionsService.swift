import Foundation
import CoreLocation
import MapKit

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
    let polyline: MKPolyline?

    var durationMinutes: Int {
        durationSeconds / 60
    }
}

/// Directions service using Apple MapKit (completely free, no API key required)
class DirectionsService: DirectionsServiceProtocol {

    func calculateRoute(
        from origin: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D,
        mode: TravelMode
    ) async throws -> RouteResult {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: origin))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = mode.mkTransportType

        let directions = MKDirections(request: request)

        do {
            let response = try await directions.calculate()

            guard let route = response.routes.first else {
                throw DirectionsError.noRouteFound
            }

            return RouteResult(
                distanceMeters: Int(route.distance),
                durationSeconds: Int(route.expectedTravelTime),
                polyline: route.polyline
            )
        } catch let error as MKError {
            throw DirectionsError.mapKitError(error)
        } catch let error as DirectionsError {
            throw error
        } catch {
            throw DirectionsError.unknown(error)
        }
    }
}

// MARK: - Travel Mode Extension

extension TravelMode {
    var mkTransportType: MKDirectionsTransportType {
        switch self {
        case .driving: return .automobile
        case .walking: return .walking
        case .bicycling: return .walking // MapKit doesn't support bicycling, fallback to walking
        case .transit: return .transit
        case .taxi: return .automobile // Taxi uses driving routes
        }
    }
}

// MARK: - Errors

enum DirectionsError: LocalizedError {
    case noRouteFound
    case mapKitError(MKError)
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .noRouteFound:
            return "No route found between these locations"
        case .mapKitError(let error):
            switch error.code {
            case .placemarkNotFound:
                return "Location not found"
            case .directionsNotFound:
                return "No directions available for this route"
            case .serverFailure:
                return "Server error, please try again"
            default:
                return "Directions error: \(error.localizedDescription)"
            }
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}
