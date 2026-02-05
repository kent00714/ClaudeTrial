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

    // MARK: - Trip Sharing Tests

    func testShareableTextBasic() {
        let trip = TripTestData.makeTrip(name: "Weekend Getaway")
        let text = trip.shareableText

        XCTAssertTrue(text.contains("Weekend Getaway"))
        XCTAssertTrue(text.contains("TPE Flight Tracker"))
    }

    func testShareableTextWithDestinations() {
        let trip = TripTestData.sampleTrip
        let text = trip.shareableText

        XCTAssertTrue(text.contains("Taiwan Adventure"))
        XCTAssertTrue(text.contains("3 stops"))
        XCTAssertTrue(text.contains("Taipei 101"))
        XCTAssertTrue(text.contains("Taoyuan Airport"))
        XCTAssertTrue(text.contains("Shilin Night Market"))
    }

    func testShareableTextWithLinkedFlight() {
        let trip = TripTestData.makeTrip(
            name: "Flight Trip",
            linkedFlightNumber: "CI123"
        )
        let text = trip.shareableText

        XCTAssertTrue(text.contains("Flight: CI123"))
    }

    func testShareableTextWithNotes() {
        let trip = TripTestData.makeTrip(
            name: "Noted Trip",
            notes: "Remember to bring umbrella"
        )
        let text = trip.shareableText

        XCTAssertTrue(text.contains("Notes: Remember to bring umbrella"))
    }

    func testShareableTextFromSuggestion() {
        let trip = TripTestData.makeTrip(
            name: "Suggested Trip",
            sourceSuggestionName: "Best of Taipei"
        )
        let text = trip.shareableText

        XCTAssertTrue(text.contains("Based on: Best of Taipei"))
    }

    func testExportAsJSON() throws {
        let trip = TripTestData.sampleTrip
        let jsonData = try trip.exportAsJSON()

        // Verify it's valid JSON
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        XCTAssertTrue(jsonObject is [String: Any])

        // Verify it can be imported back
        let imported = try Trip.importFromJSON(jsonData)
        XCTAssertEqual(imported.name, trip.name)
        XCTAssertEqual(imported.destinations.count, trip.destinations.count)
    }

    func testImportFromJSON() throws {
        let original = TripTestData.makeTrip(
            name: "Import Test",
            notes: "Test notes",
            sourceSuggestionName: "Test Source",
            linkedFlightNumber: "BR001"
        )

        let jsonData = try original.exportAsJSON()
        let imported = try Trip.importFromJSON(jsonData)

        XCTAssertEqual(imported.name, "Import Test")
        XCTAssertEqual(imported.notes, "Test notes")
        XCTAssertEqual(imported.sourceSuggestionName, "Test Source")
        XCTAssertEqual(imported.linkedFlightNumber, "BR001")
    }

    func testExportFilename() {
        let calendar = Calendar.current
        let date = calendar.date(from: DateComponents(year: 2024, month: 6, day: 15))!
        let trip = TripTestData.makeTrip(name: "My Summer Trip", startDate: date)

        XCTAssertEqual(trip.exportFilename, "trip_My_Summer_Trip_20240615.json")
    }

    func testExportFilenameWithSpecialCharacters() {
        let date = Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 1))!
        let trip = TripTestData.makeTrip(name: "Trip/With Special @#$ Chars!", startDate: date)

        // Should sanitize special characters
        let filename = trip.exportFilename
        XCTAssertTrue(filename.hasSuffix(".json"))
        XCTAssertFalse(filename.contains("/"))
        XCTAssertFalse(filename.contains("@"))
        XCTAssertFalse(filename.contains("#"))
    }

    func testHasLinkedFlight() {
        let tripWithFlight = TripTestData.makeTrip(linkedFlightNumber: "CI123")
        XCTAssertTrue(tripWithFlight.hasLinkedFlight)

        let tripWithoutFlight = TripTestData.makeTrip()
        XCTAssertFalse(tripWithoutFlight.hasLinkedFlight)

        let tripWithEmptyFlight = TripTestData.makeTrip(linkedFlightNumber: "")
        XCTAssertFalse(tripWithEmptyFlight.hasLinkedFlight)
    }

    func testIsFromSuggestion() {
        let tripFromSuggestion = TripTestData.makeTrip(sourceSuggestionName: "Best of Taipei")
        XCTAssertTrue(tripFromSuggestion.isFromSuggestion)

        let regularTrip = TripTestData.makeTrip()
        XCTAssertFalse(regularTrip.isFromSuggestion)
    }

    // MARK: - Shareable Link Tests

    func testShareableLinkGeneration() {
        let trip = TripTestData.makeTrip(name: "Link Test Trip")
        let link = trip.shareableLink

        XCTAssertNotNil(link)
        XCTAssertEqual(link?.scheme, "tpetracker")
        XCTAssertEqual(link?.host, "trip")
    }

    func testShareableLinkRoundtrip() throws {
        let original = TripTestData.makeTrip(
            name: "Roundtrip Test",
            notes: "Test notes for link",
            sourceSuggestionName: "Test Source",
            linkedFlightNumber: "CI123"
        )

        guard let link = original.shareableLink else {
            XCTFail("Failed to generate shareable link")
            return
        }

        let imported = try Trip.importFromLink(link)

        XCTAssertEqual(imported.name, "Roundtrip Test")
        XCTAssertEqual(imported.notes, "Test notes for link")
        XCTAssertEqual(imported.sourceSuggestionName, "Test Source")
        XCTAssertEqual(imported.linkedFlightNumber, "CI123")
    }

    func testShareableLinkWithDestinations() throws {
        let trip = TripTestData.sampleTrip
        guard let link = trip.shareableLink else {
            XCTFail("Failed to generate shareable link")
            return
        }

        let imported = try Trip.importFromLink(link)

        XCTAssertEqual(imported.destinations.count, trip.destinations.count)
        XCTAssertEqual(imported.destinations.first?.name, trip.destinations.first?.name)
    }

    func testImportFromInvalidLink() {
        let invalidURL = URL(string: "tpetracker://trip?data=invalid_data")!

        XCTAssertThrowsError(try Trip.importFromLink(invalidURL)) { error in
            XCTAssertTrue(error is TripImportError)
        }
    }

    func testImportFromWrongScheme() {
        let wrongSchemeURL = URL(string: "https://example.com/trip?data=abc")!

        XCTAssertThrowsError(try Trip.importFromLink(wrongSchemeURL)) { error in
            XCTAssertTrue(error is TripImportError)
        }
    }

    func testShareableTextWithLink() {
        let trip = TripTestData.makeTrip(name: "Text With Link Test")
        let text = trip.shareableTextWithLink

        XCTAssertTrue(text.contains("Text With Link Test"))
        XCTAssertTrue(text.contains("tpetracker://"))
        XCTAssertTrue(text.contains("Open in TPE Flight Tracker"))
    }
}
