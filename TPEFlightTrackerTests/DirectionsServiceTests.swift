import XCTest
import CoreLocation
import MapKit
@testable import TPEFlightTracker

final class DirectionsServiceTests: XCTestCase {

    // MARK: - RouteResult Tests

    func testRouteResultDurationMinutes() {
        let result = RouteResult(
            distanceMeters: 5000,
            durationSeconds: 1800, // 30 minutes
            polyline: nil
        )

        XCTAssertEqual(result.durationMinutes, 30)
    }

    func testRouteResultDurationMinutesRoundsDown() {
        let result = RouteResult(
            distanceMeters: 5000,
            durationSeconds: 1850, // 30 min 50 sec
            polyline: nil
        )

        XCTAssertEqual(result.durationMinutes, 30) // Should round down
    }

    func testRouteResultWithPolyline() {
        let coordinates = [
            CLLocationCoordinate2D(latitude: 25.0, longitude: 121.5),
            CLLocationCoordinate2D(latitude: 25.1, longitude: 121.6),
        ]
        let polyline = MKPolyline(coordinates: coordinates, count: 2)

        let result = RouteResult(
            distanceMeters: 10000,
            durationSeconds: 900,
            polyline: polyline
        )

        XCTAssertNotNil(result.polyline)
        XCTAssertEqual(result.polyline?.pointCount, 2)
    }

    // MARK: - TravelMode mkTransportType Tests

    func testDrivingMapsToAutomobile() {
        XCTAssertEqual(TravelMode.driving.mkTransportType, .automobile)
    }

    func testWalkingMapsToWalking() {
        XCTAssertEqual(TravelMode.walking.mkTransportType, .walking)
    }

    func testBicyclingFallsBackToWalking() {
        // MapKit doesn't support bicycling, so it falls back to walking
        XCTAssertEqual(TravelMode.bicycling.mkTransportType, .walking)
    }

    func testTransitMapsToTransit() {
        XCTAssertEqual(TravelMode.transit.mkTransportType, .transit)
    }

    // MARK: - DirectionsError Tests

    func testNoRouteFoundErrorDescription() {
        let error = DirectionsError.noRouteFound

        XCTAssertEqual(error.errorDescription, "No route found between these locations")
    }

    func testUnknownErrorDescription() {
        let underlyingError = NSError(domain: "test", code: 42, userInfo: [NSLocalizedDescriptionKey: "Something went wrong"])
        let error = DirectionsError.unknown(underlyingError)

        XCTAssertEqual(error.errorDescription, "Something went wrong")
    }

    // MARK: - Mock Directions Service Tests

    func testMockDirectionsServiceReturnsConfiguredRoute() async throws {
        let mock = MockDirectionsService()
        mock.routeToReturn = RouteResult(
            distanceMeters: 12345,
            durationSeconds: 678,
            polyline: nil
        )

        let result = try await mock.calculateRoute(
            from: TripTestData.taipei101,
            to: TripTestData.taipeiStation,
            mode: .driving
        )

        XCTAssertEqual(result.distanceMeters, 12345)
        XCTAssertEqual(result.durationSeconds, 678)
    }

    func testMockDirectionsServiceThrowsConfiguredError() async {
        let mock = MockDirectionsService()
        mock.errorToThrow = DirectionsError.noRouteFound

        do {
            _ = try await mock.calculateRoute(
                from: TripTestData.taipei101,
                to: TripTestData.taipeiStation,
                mode: .walking
            )
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is DirectionsError)
        }
    }

    func testMockDirectionsServiceTracksParameters() async throws {
        let mock = MockDirectionsService()

        _ = try await mock.calculateRoute(
            from: TripTestData.taipei101,
            to: TripTestData.shilinNightMarket,
            mode: .transit
        )

        XCTAssertEqual(mock.calculateRouteCallCount, 1)
        XCTAssertEqual(mock.lastOrigin?.latitude, TripTestData.taipei101.latitude, accuracy: 0.0001)
        XCTAssertEqual(mock.lastOrigin?.longitude, TripTestData.taipei101.longitude, accuracy: 0.0001)
        XCTAssertEqual(mock.lastDestination?.latitude, TripTestData.shilinNightMarket.latitude, accuracy: 0.0001)
        XCTAssertEqual(mock.lastDestination?.longitude, TripTestData.shilinNightMarket.longitude, accuracy: 0.0001)
        XCTAssertEqual(mock.lastMode, .transit)
    }

    func testMockDirectionsServiceReturnsDefaultRoute() async throws {
        let mock = MockDirectionsService()
        // No routeToReturn configured, should return default

        let result = try await mock.calculateRoute(
            from: TripTestData.taipei101,
            to: TripTestData.taipeiStation,
            mode: .driving
        )

        XCTAssertEqual(result.distanceMeters, 5000)
        XCTAssertEqual(result.durationSeconds, 600)
    }

    // MARK: - Protocol Conformance Tests

    func testDirectionsServiceProtocolConformance() {
        // Verify DirectionsService conforms to protocol
        let service: DirectionsServiceProtocol = DirectionsService()
        XCTAssertNotNil(service)
    }

    func testMockDirectionsServiceProtocolConformance() {
        // Verify MockDirectionsService conforms to protocol
        let service: DirectionsServiceProtocol = MockDirectionsService()
        XCTAssertNotNil(service)
    }

    // MARK: - Integration-style Tests (using mock)

    func testMultipleRouteCalculations() async throws {
        let mock = MockDirectionsService()
        var callCount = 0

        mock.routeToReturn = RouteResult(
            distanceMeters: 1000,
            durationSeconds: 120,
            polyline: nil
        )

        let locations = [
            TripTestData.taoyuanAirport,
            TripTestData.taipei101,
            TripTestData.taipeiStation,
            TripTestData.shilinNightMarket,
        ]

        for i in 0..<(locations.count - 1) {
            _ = try await mock.calculateRoute(
                from: locations[i],
                to: locations[i + 1],
                mode: .driving
            )
            callCount += 1
        }

        XCTAssertEqual(mock.calculateRouteCallCount, 3)
        XCTAssertEqual(callCount, 3)
    }

    func testDifferentTravelModes() async throws {
        let mock = MockDirectionsService()
        let modes: [TravelMode] = [.driving, .walking, .bicycling, .transit]

        for mode in modes {
            mock.routeToReturn = RouteResult(
                distanceMeters: Int(mode.hashValue) + 1000,
                durationSeconds: 600,
                polyline: nil
            )

            let result = try await mock.calculateRoute(
                from: TripTestData.taipei101,
                to: TripTestData.taipeiStation,
                mode: mode
            )

            XCTAssertEqual(mock.lastMode, mode)
            XCTAssertNotNil(result)
        }

        XCTAssertEqual(mock.calculateRouteCallCount, 4)
    }
}
