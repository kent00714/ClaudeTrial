import XCTest
import CoreLocation
@testable import TPEFlightTracker

@MainActor
final class TripViewModelTests: XCTestCase {

    var sut: TripViewModel!
    var mockTripService: MockTripService!
    var mockDirectionsService: MockDirectionsService!

    override func setUp() {
        super.setUp()
        mockTripService = MockTripService()
        mockDirectionsService = MockDirectionsService()
        sut = TripViewModel(
            tripService: mockTripService,
            directionsService: mockDirectionsService
        )
    }

    override func tearDown() {
        sut = nil
        mockTripService = nil
        mockDirectionsService = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState() {
        XCTAssertTrue(sut.trips.isEmpty)
        XCTAssertNil(sut.selectedTrip)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }

    func testLoadTripsOnInit() {
        mockTripService.trips = [TripTestData.sampleTrip]
        let viewModel = TripViewModel(
            tripService: mockTripService,
            directionsService: mockDirectionsService
        )

        XCTAssertEqual(viewModel.trips.count, 1)
        XCTAssertEqual(mockTripService.loadTripsCallCount, 2) // Once for original, once for new
    }

    // MARK: - Trip CRUD Tests

    func testCreateTrip() {
        let name = "New Trip"
        let startDate = Date()
        let endDate = Date().addingTimeInterval(86400 * 5)

        sut.createTrip(name: name, startDate: startDate, endDate: endDate)

        XCTAssertEqual(mockTripService.addTripCallCount, 1)
        XCTAssertEqual(mockTripService.trips.count, 1)
        XCTAssertEqual(mockTripService.trips.first?.name, name)
    }

    func testUpdateTrip() {
        var trip = TripTestData.makeTrip(name: "Original Name")
        mockTripService.trips = [trip]
        sut.loadTrips()

        trip.name = "Updated Name"
        sut.updateTrip(trip)

        XCTAssertEqual(mockTripService.updateTripCallCount, 1)
        XCTAssertEqual(mockTripService.trips.first?.name, "Updated Name")
    }

    func testUpdateSelectedTrip() {
        var trip = TripTestData.makeTrip()
        mockTripService.trips = [trip]
        sut.loadTrips()
        sut.selectTrip(trip)

        trip.name = "Updated"
        sut.updateTrip(trip)

        XCTAssertEqual(sut.selectedTrip?.name, "Updated")
    }

    func testDeleteTrip() {
        let trip = TripTestData.makeTrip()
        mockTripService.trips = [trip]
        sut.loadTrips()

        sut.deleteTrip(trip)

        XCTAssertEqual(mockTripService.deleteTripCallCount, 1)
        XCTAssertTrue(mockTripService.trips.isEmpty)
    }

    func testDeleteSelectedTripClearsSelection() {
        let trip = TripTestData.makeTrip()
        mockTripService.trips = [trip]
        sut.loadTrips()
        sut.selectTrip(trip)

        sut.deleteTrip(trip)

        XCTAssertNil(sut.selectedTrip)
    }

    func testSelectTrip() {
        let trip = TripTestData.makeTrip()
        mockTripService.trips = [trip]
        sut.loadTrips()

        sut.selectTrip(trip)

        XCTAssertEqual(sut.selectedTrip?.id, trip.id)
    }

    // MARK: - Destination Management Tests

    func testAddFirstDestination() async {
        let trip = TripTestData.makeTrip()
        mockTripService.trips = [trip]
        sut.loadTrips()

        await sut.addDestination(
            to: trip,
            name: "Taipei 101",
            address: "Xinyi District",
            coordinate: TripTestData.taipei101,
            travelMode: .driving
        )

        XCTAssertEqual(mockTripService.updateTripCallCount, 1)
        XCTAssertEqual(mockTripService.trips.first?.destinations.count, 1)
        // First destination should not trigger route calculation
        XCTAssertEqual(mockDirectionsService.calculateRouteCallCount, 0)
    }

    func testAddSecondDestinationCalculatesRoute() async {
        var trip = TripTestData.makeTrip()
        let firstDest = TripTestData.makeDestination(
            name: "First",
            coordinate: TripTestData.taoyuanAirport,
            order: 0
        )
        trip.destinations = [firstDest]
        mockTripService.trips = [trip]
        sut.loadTrips()

        mockDirectionsService.routeToReturn = RouteResult(
            distanceMeters: 40000,
            durationSeconds: 2700, // 45 minutes
            polyline: nil
        )

        await sut.addDestination(
            to: trip,
            name: "Second",
            address: "Address",
            coordinate: TripTestData.taipei101,
            travelMode: .driving
        )

        XCTAssertEqual(mockDirectionsService.calculateRouteCallCount, 1)
        XCTAssertEqual(mockDirectionsService.lastMode, .driving)

        let updatedTrip = mockTripService.trips.first!
        let secondDest = updatedTrip.destinations[1]
        XCTAssertEqual(secondDest.travelDistanceMeters, 40000)
        XCTAssertEqual(secondDest.travelDurationMinutes, 45)
    }

    func testAddDestinationWithRouteError() async {
        var trip = TripTestData.makeTrip()
        trip.destinations = [TripTestData.makeDestination(order: 0)]
        mockTripService.trips = [trip]
        sut.loadTrips()

        mockDirectionsService.errorToThrow = TestError.directionsFailure

        await sut.addDestination(
            to: trip,
            name: "Second",
            address: "Address",
            coordinate: TripTestData.shilinNightMarket,
            travelMode: .walking
        )

        // Should still add destination even if route calculation fails
        XCTAssertEqual(mockTripService.trips.first?.destinations.count, 2)
        let secondDest = mockTripService.trips.first!.destinations[1]
        XCTAssertNil(secondDest.travelDistanceMeters)
        XCTAssertNil(secondDest.travelDurationMinutes)
    }

    func testRemoveDestination() async {
        var trip = TripTestData.makeTrip()
        trip.destinations = TripTestData.sampleDestinations
        mockTripService.trips = [trip]
        sut.loadTrips()

        let destToRemove = trip.destinations[1]
        await sut.removeDestination(destToRemove, from: trip)

        XCTAssertEqual(mockTripService.trips.first?.destinations.count, 2)
    }

    func testRemoveDestinationUpdatesOrder() async {
        var trip = TripTestData.makeTrip()
        trip.destinations = [
            TripTestData.makeDestination(name: "A", order: 0),
            TripTestData.makeDestination(name: "B", order: 1),
            TripTestData.makeDestination(name: "C", order: 2),
        ]
        mockTripService.trips = [trip]
        sut.loadTrips()

        await sut.removeDestination(trip.destinations[1], from: trip)

        let updatedDests = mockTripService.trips.first!.destinations
        XCTAssertEqual(updatedDests[0].order, 0)
        XCTAssertEqual(updatedDests[1].order, 1)
        XCTAssertEqual(updatedDests[1].name, "C")
    }

    func testUpdateDestinationRecalculatesRoute() async {
        var trip = TripTestData.makeTrip()
        trip.destinations = [
            TripTestData.makeDestination(name: "First", coordinate: TripTestData.taoyuanAirport, order: 0),
            TripTestData.makeDestination(name: "Second", coordinate: TripTestData.taipei101, order: 1),
        ]
        mockTripService.trips = [trip]
        sut.loadTrips()

        mockDirectionsService.routeToReturn = RouteResult(
            distanceMeters: 10000,
            durationSeconds: 1200,
            polyline: nil
        )

        var updatedDest = trip.destinations[1]
        updatedDest.travelMode = .walking

        await sut.updateDestination(updatedDest, in: trip)

        XCTAssertEqual(mockDirectionsService.calculateRouteCallCount, 1)
        XCTAssertEqual(mockDirectionsService.lastMode, .walking)
    }

    // MARK: - Route Calculation Tests

    func testRecalculateAllRoutes() async {
        var trip = TripTestData.makeTrip()
        trip.destinations = TripTestData.sampleDestinations
        mockTripService.trips = [trip]
        sut.loadTrips()

        mockDirectionsService.routeToReturn = RouteResult(
            distanceMeters: 5000,
            durationSeconds: 600,
            polyline: nil
        )

        await sut.recalculateAllRoutes(for: trip)

        // Should calculate routes for all but first destination
        XCTAssertEqual(mockDirectionsService.calculateRouteCallCount, 2)
        XCTAssertFalse(sut.isLoading)
    }

    func testRecalculateAllRoutesFirstDestinationHasNoRoute() async {
        var trip = TripTestData.makeTrip()
        trip.destinations = [
            TripTestData.makeDestination(order: 0, travelDurationMinutes: 99, travelDistanceMeters: 9999),
            TripTestData.makeDestination(order: 1),
        ]
        mockTripService.trips = [trip]
        sut.loadTrips()

        await sut.recalculateAllRoutes(for: trip)

        let firstDest = mockTripService.trips.first!.destinations[0]
        XCTAssertNil(firstDest.travelDurationMinutes)
        XCTAssertNil(firstDest.travelDistanceMeters)
    }

    func testReorderDestinations() async {
        var trip = TripTestData.makeTrip()
        trip.destinations = [
            TripTestData.makeDestination(name: "A", order: 0),
            TripTestData.makeDestination(name: "B", order: 1),
            TripTestData.makeDestination(name: "C", order: 2),
        ]
        mockTripService.trips = [trip]
        sut.loadTrips()

        await sut.reorderDestinations(in: trip, from: IndexSet(integer: 2), to: 0)

        let reordered = mockTripService.trips.first!.destinations
        XCTAssertEqual(reordered[0].name, "C")
        XCTAssertEqual(reordered[0].order, 0)
        XCTAssertEqual(reordered[1].name, "A")
        XCTAssertEqual(reordered[1].order, 1)
        XCTAssertEqual(reordered[2].name, "B")
        XCTAssertEqual(reordered[2].order, 2)
    }

    // MARK: - Edge Cases

    func testUpdateNonexistentDestination() async {
        var trip = TripTestData.makeTrip()
        trip.destinations = [TripTestData.makeDestination()]
        mockTripService.trips = [trip]
        sut.loadTrips()

        let nonExistentDest = TripTestData.makeDestination(id: UUID())

        await sut.updateDestination(nonExistentDest, in: trip)

        // Should not call update when destination not found
        XCTAssertEqual(mockTripService.updateTripCallCount, 0)
    }

    func testRemoveNonexistentDestination() async {
        var trip = TripTestData.makeTrip()
        trip.destinations = [TripTestData.makeDestination()]
        mockTripService.trips = [trip]
        sut.loadTrips()

        let nonExistentDest = TripTestData.makeDestination(id: UUID())

        await sut.removeDestination(nonExistentDest, from: trip)

        // Should not modify trip when destination not found
        XCTAssertEqual(mockTripService.updateTripCallCount, 0)
    }
}
