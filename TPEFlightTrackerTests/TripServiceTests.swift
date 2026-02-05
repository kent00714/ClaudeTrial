import XCTest
@testable import TPEFlightTracker

final class TripServiceTests: XCTestCase {

    var sut: TripService!
    var testDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        testDefaults = UserDefaults(suiteName: "TripServiceTests")!
        testDefaults.removePersistentDomain(forName: "TripServiceTests")
        sut = TripService(defaults: testDefaults)
    }

    override func tearDown() {
        testDefaults.removePersistentDomain(forName: "TripServiceTests")
        testDefaults = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Load Tests

    func testLoadTripsReturnsEmptyArrayWhenNoData() {
        let trips = sut.loadTrips()

        XCTAssertTrue(trips.isEmpty)
    }

    func testLoadTripsReturnsStoredTrips() {
        let trip = TripTestData.makeTrip(name: "Stored Trip")
        sut.addTrip(trip)

        let loaded = sut.loadTrips()

        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.name, "Stored Trip")
    }

    func testLoadTripsSortsByStartDate() {
        let laterTrip = TripTestData.makeTrip(
            name: "Later",
            startDate: Date().addingTimeInterval(86400 * 10)
        )
        let earlierTrip = TripTestData.makeTrip(
            name: "Earlier",
            startDate: Date().addingTimeInterval(86400)
        )

        sut.addTrip(laterTrip)
        sut.addTrip(earlierTrip)

        let loaded = sut.loadTrips()

        XCTAssertEqual(loaded[0].name, "Earlier")
        XCTAssertEqual(loaded[1].name, "Later")
    }

    // MARK: - Save Tests

    func testSaveTrips() {
        let trips = [
            TripTestData.makeTrip(name: "Trip 1"),
            TripTestData.makeTrip(name: "Trip 2"),
        ]

        sut.saveTrips(trips)

        let loaded = sut.loadTrips()
        XCTAssertEqual(loaded.count, 2)
    }

    func testSaveTripsOverwritesExisting() {
        sut.addTrip(TripTestData.makeTrip(name: "Old"))
        sut.saveTrips([TripTestData.makeTrip(name: "New")])

        let loaded = sut.loadTrips()

        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.name, "New")
    }

    // MARK: - Add Tests

    func testAddTrip() {
        let trip = TripTestData.makeTrip(name: "New Trip")

        sut.addTrip(trip)

        let loaded = sut.loadTrips()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.id, trip.id)
    }

    func testAddMultipleTrips() {
        sut.addTrip(TripTestData.makeTrip(name: "Trip 1"))
        sut.addTrip(TripTestData.makeTrip(name: "Trip 2"))
        sut.addTrip(TripTestData.makeTrip(name: "Trip 3"))

        let loaded = sut.loadTrips()

        XCTAssertEqual(loaded.count, 3)
    }

    // MARK: - Update Tests

    func testUpdateTrip() {
        var trip = TripTestData.makeTrip(name: "Original")
        sut.addTrip(trip)

        trip.name = "Updated"
        sut.updateTrip(trip)

        let loaded = sut.loadTrips()
        XCTAssertEqual(loaded.first?.name, "Updated")
    }

    func testUpdateTripUpdatesTimestamp() {
        let trip = TripTestData.makeTrip()
        sut.addTrip(trip)
        let originalUpdatedAt = sut.loadTrips().first!.updatedAt

        // Small delay to ensure different timestamp
        Thread.sleep(forTimeInterval: 0.01)

        var modified = trip
        modified.name = "Modified"
        sut.updateTrip(modified)

        let loaded = sut.loadTrips().first!
        XCTAssertGreaterThan(loaded.updatedAt, originalUpdatedAt)
    }

    func testUpdateNonexistentTripDoesNothing() {
        let existingTrip = TripTestData.makeTrip(name: "Existing")
        sut.addTrip(existingTrip)

        let nonExistent = TripTestData.makeTrip(name: "Ghost")
        sut.updateTrip(nonExistent)

        let loaded = sut.loadTrips()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.name, "Existing")
    }

    func testUpdateTripPreservesDestinations() {
        var trip = TripTestData.makeTrip()
        trip.destinations = TripTestData.sampleDestinations
        sut.addTrip(trip)

        trip.name = "Updated"
        sut.updateTrip(trip)

        let loaded = sut.loadTrips().first!
        XCTAssertEqual(loaded.destinations.count, 3)
        XCTAssertEqual(loaded.destinations[0].name, "Taoyuan Airport")
    }

    // MARK: - Delete Tests

    func testDeleteTrip() {
        let trip = TripTestData.makeTrip()
        sut.addTrip(trip)

        sut.deleteTrip(id: trip.id)

        XCTAssertTrue(sut.loadTrips().isEmpty)
    }

    func testDeleteTripPreservesOthers() {
        let trip1 = TripTestData.makeTrip(name: "Keep")
        let trip2 = TripTestData.makeTrip(name: "Delete")
        sut.addTrip(trip1)
        sut.addTrip(trip2)

        sut.deleteTrip(id: trip2.id)

        let loaded = sut.loadTrips()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.name, "Keep")
    }

    func testDeleteNonexistentTrip() {
        let trip = TripTestData.makeTrip()
        sut.addTrip(trip)

        sut.deleteTrip(id: UUID())

        XCTAssertEqual(sut.loadTrips().count, 1)
    }

    // MARK: - Get Trip Tests

    func testGetTripReturnsTrip() {
        let trip = TripTestData.makeTrip(name: "Find Me")
        sut.addTrip(trip)

        let found = sut.getTrip(id: trip.id)

        XCTAssertNotNil(found)
        XCTAssertEqual(found?.name, "Find Me")
    }

    func testGetTripReturnsNilWhenNotFound() {
        sut.addTrip(TripTestData.makeTrip())

        let found = sut.getTrip(id: UUID())

        XCTAssertNil(found)
    }

    // MARK: - Persistence Tests

    func testTripPersistsAcrossServiceInstances() {
        let trip = TripTestData.makeTrip(name: "Persistent")
        sut.addTrip(trip)

        let newService = TripService(defaults: testDefaults)
        let loaded = newService.loadTrips()

        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.name, "Persistent")
    }

    func testDestinationsPersist() {
        var trip = TripTestData.makeTrip()
        trip.destinations = TripTestData.sampleDestinations
        sut.addTrip(trip)

        let newService = TripService(defaults: testDefaults)
        let loaded = newService.loadTrips().first!

        XCTAssertEqual(loaded.destinations.count, 3)
        XCTAssertEqual(loaded.destinations[1].travelDurationMinutes, 45)
        XCTAssertEqual(loaded.destinations[1].travelDistanceMeters, 40000)
    }

    // MARK: - Edge Cases

    func testLoadCorruptedDataReturnsEmptyArray() {
        testDefaults.set(Data([0x00, 0x01, 0x02]), forKey: "com.tpeflighttracker.trips")

        let loaded = sut.loadTrips()

        XCTAssertTrue(loaded.isEmpty)
    }

    func testTripWithManyDestinations() {
        var trip = TripTestData.makeTrip()
        trip.destinations = (0..<50).map { i in
            TripTestData.makeDestination(
                name: "Destination \(i)",
                order: i,
                travelDurationMinutes: 10,
                travelDistanceMeters: 1000
            )
        }

        sut.addTrip(trip)
        let loaded = sut.loadTrips().first!

        XCTAssertEqual(loaded.destinations.count, 50)
    }
}
