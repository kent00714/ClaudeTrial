import XCTest
import CoreLocation
@testable import TPEFlightTracker

final class TripModelTests: XCTestCase {

    // MARK: - Trip Tests

    func testTripInitialization() {
        let trip = TripTestData.makeTrip(name: "Test Trip")

        XCTAssertEqual(trip.name, "Test Trip")
        XCTAssertTrue(trip.destinations.isEmpty)
        XCTAssertEqual(trip.totalDestinations, 0)
    }

    func testTripWithDestinations() {
        let trip = TripTestData.sampleTrip

        XCTAssertEqual(trip.name, "Taiwan Adventure")
        XCTAssertEqual(trip.totalDestinations, 3)
    }

    func testTripTotalDistance() {
        let trip = TripTestData.sampleTrip

        // 40000 + 8000 = 48000 meters
        XCTAssertEqual(trip.totalDistanceMeters, 48000)
    }

    func testTripTotalDuration() {
        let trip = TripTestData.sampleTrip

        // 45 + 20 = 65 minutes
        XCTAssertEqual(trip.totalDurationMinutes, 65)
    }

    func testTripFormattedTotalDistance() {
        let trip = TripTestData.sampleTrip

        // 48000 meters = 48.0 km
        XCTAssertEqual(trip.formattedTotalDistance, "48.0 km")
    }

    func testTripFormattedTotalDuration() {
        let trip = TripTestData.sampleTrip

        // 65 minutes = 1h 5m
        XCTAssertEqual(trip.formattedTotalDuration, "1h 5m")
    }

    func testTripFormattedDurationUnderOneHour() {
        let destinations = [
            TripTestData.makeDestination(order: 0),
            TripTestData.makeDestination(order: 1, travelDurationMinutes: 30),
        ]
        let trip = TripTestData.makeTrip(destinations: destinations)

        XCTAssertEqual(trip.formattedTotalDuration, "30 min")
    }

    func testTripFormattedDistanceUnderOneKm() {
        let destinations = [
            TripTestData.makeDestination(order: 0),
            TripTestData.makeDestination(order: 1, travelDistanceMeters: 500),
        ]
        let trip = TripTestData.makeTrip(destinations: destinations)

        XCTAssertEqual(trip.formattedTotalDistance, "500 m")
    }

    func testTripCodable() throws {
        let original = TripTestData.sampleTrip
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Trip.self, from: encoded)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.name, original.name)
        XCTAssertEqual(decoded.destinations.count, original.destinations.count)
    }

    func testTripEquatable() {
        let trip1 = TripTestData.makeTrip(name: "Trip A")
        let trip2 = trip1
        let trip3 = TripTestData.makeTrip(name: "Trip B")

        XCTAssertEqual(trip1, trip2)
        XCTAssertNotEqual(trip1, trip3)
    }

    // MARK: - TripDestination Tests

    func testDestinationInitialization() {
        let dest = TripTestData.makeDestination(
            name: "Test Place",
            address: "123 Test St"
        )

        XCTAssertEqual(dest.name, "Test Place")
        XCTAssertEqual(dest.address, "123 Test St")
        XCTAssertEqual(dest.travelMode, .driving)
    }

    func testDestinationCoordinate() {
        let dest = TripTestData.makeDestination(coordinate: TripTestData.taipei101)

        XCTAssertEqual(dest.coordinate.latitude, TripTestData.taipei101.latitude, accuracy: 0.0001)
        XCTAssertEqual(dest.coordinate.longitude, TripTestData.taipei101.longitude, accuracy: 0.0001)
    }

    func testDestinationFormattedTravelDistance() {
        let destKm = TripTestData.makeDestination(travelDistanceMeters: 5500)
        XCTAssertEqual(destKm.formattedTravelDistance, "5.5 km")

        let destM = TripTestData.makeDestination(travelDistanceMeters: 800)
        XCTAssertEqual(destM.formattedTravelDistance, "800 m")

        let destNil = TripTestData.makeDestination(travelDistanceMeters: nil)
        XCTAssertNil(destNil.formattedTravelDistance)
    }

    func testDestinationFormattedTravelDuration() {
        let destHours = TripTestData.makeDestination(travelDurationMinutes: 90)
        XCTAssertEqual(destHours.formattedTravelDuration, "1h 30m")

        let destMins = TripTestData.makeDestination(travelDurationMinutes: 45)
        XCTAssertEqual(destMins.formattedTravelDuration, "45 min")

        let destNil = TripTestData.makeDestination(travelDurationMinutes: nil)
        XCTAssertNil(destNil.formattedTravelDuration)
    }

    func testDestinationCodable() throws {
        let original = TripTestData.makeDestination(
            name: "Test",
            travelDurationMinutes: 30,
            travelDistanceMeters: 5000,
            travelMode: .walking
        )
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(TripDestination.self, from: encoded)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.name, original.name)
        XCTAssertEqual(decoded.travelDurationMinutes, 30)
        XCTAssertEqual(decoded.travelDistanceMeters, 5000)
        XCTAssertEqual(decoded.travelMode, .walking)
    }

    // MARK: - TravelMode Tests

    func testTravelModeAllCases() {
        let allModes = TravelMode.allCases
        XCTAssertEqual(allModes.count, 4)
        XCTAssertTrue(allModes.contains(.driving))
        XCTAssertTrue(allModes.contains(.walking))
        XCTAssertTrue(allModes.contains(.bicycling))
        XCTAssertTrue(allModes.contains(.transit))
    }

    func testTravelModeDisplayNames() {
        XCTAssertEqual(TravelMode.driving.displayName, "Driving")
        XCTAssertEqual(TravelMode.walking.displayName, "Walking")
        XCTAssertEqual(TravelMode.bicycling.displayName, "Bicycling")
        XCTAssertEqual(TravelMode.transit.displayName, "Transit")
    }

    func testTravelModeSystemImages() {
        XCTAssertEqual(TravelMode.driving.systemImage, "car.fill")
        XCTAssertEqual(TravelMode.walking.systemImage, "figure.walk")
        XCTAssertEqual(TravelMode.bicycling.systemImage, "bicycle")
        XCTAssertEqual(TravelMode.transit.systemImage, "bus.fill")
    }

    func testTravelModeMKTransportType() {
        XCTAssertEqual(TravelMode.driving.mkTransportType, .automobile)
        XCTAssertEqual(TravelMode.walking.mkTransportType, .walking)
        XCTAssertEqual(TravelMode.bicycling.mkTransportType, .walking) // Fallback
        XCTAssertEqual(TravelMode.transit.mkTransportType, .transit)
    }

    func testTravelModeCodable() throws {
        for mode in TravelMode.allCases {
            let encoded = try JSONEncoder().encode(mode)
            let decoded = try JSONDecoder().decode(TravelMode.self, from: encoded)
            XCTAssertEqual(decoded, mode)
        }
    }
}
