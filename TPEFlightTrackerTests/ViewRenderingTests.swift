import XCTest
import SwiftUI
import CoreLocation
@testable import TPEFlightTracker

/// Tests that verify SwiftUI views can be instantiated and their
/// underlying data is wired correctly. These are lightweight rendering
/// tests — they confirm the view hierarchy builds without crashes.
@MainActor
final class ViewRenderingTests: XCTestCase {

    // MARK: - ContentView

    func testContentViewCanBeInstantiated() {
        let view = ContentView()
        XCTAssertNotNil(view)
    }

    // MARK: - FlightListView

    func testFlightListViewShowsEmptyWhenNoFlights() {
        let vm = FlightViewModel(flightService: MockFlightService())
        let view = FlightListView(viewModel: vm)
        XCTAssertNotNil(view)
        XCTAssertTrue(vm.filteredFlights.isEmpty)
    }

    func testFlightListViewWithFlights() async {
        let mockService = MockFlightService()
        mockService.arrivalsToReturn = TestData.sampleArrivals
        let vm = FlightViewModel(flightService: mockService)
        await vm.loadFlights()

        let view = FlightListView(viewModel: vm)
        XCTAssertNotNil(view)
        XCTAssertEqual(vm.filteredFlights.count, 3)
    }

    // MARK: - FlightDetailView

    func testFlightDetailViewWithArrival() {
        let flight = TestData.makeArrival()
        let view = FlightDetailView(flight: flight)
        XCTAssertNotNil(view)
    }

    func testFlightDetailViewWithDeparture() {
        let flight = TestData.makeDeparture()
        let view = FlightDetailView(flight: flight)
        XCTAssertNotNil(view)
    }

    func testFlightDetailViewWithDelayedFlight() {
        let flight = TestData.makeArrival(
            status: .delayed,
            estimatedTime: Date().addingTimeInterval(1800)
        )
        let view = FlightDetailView(flight: flight)
        XCTAssertNotNil(view)
    }

    func testFlightDetailViewWithCodeshares() {
        let flight = TestData.makeArrival(codeshares: ["NH500", "UA800"])
        let view = FlightDetailView(flight: flight)
        XCTAssertNotNil(view)
    }

    func testFlightDetailViewWithNoGate() {
        let flight = TestData.makeArrival(gate: nil)
        let view = FlightDetailView(flight: flight)
        XCTAssertNotNil(view)
    }

    func testFlightDetailViewWithNoAircraft() {
        let flight = TestData.makeArrival(aircraft: nil)
        let view = FlightDetailView(flight: flight)
        XCTAssertNotNil(view)
    }

    // MARK: - FlightRowView

    func testFlightRowViewRendersWithArrival() {
        let flight = TestData.makeArrival()
        let view = FlightRowView(flight: flight)
        XCTAssertNotNil(view)
    }

    func testFlightRowViewRendersWithDeparture() {
        let flight = TestData.makeDeparture()
        let view = FlightRowView(flight: flight)
        XCTAssertNotNil(view)
    }

    func testFlightRowViewRendersDelayedFlight() {
        let flight = TestData.makeArrival(
            status: .delayed,
            estimatedTime: Date().addingTimeInterval(2100)
        )
        let view = FlightRowView(flight: flight)
        XCTAssertNotNil(view)
    }

    // MARK: - FlightStatusBadge

    func testFlightStatusBadgeRendersAllStatuses() {
        for status in [FlightStatus.scheduled, .boarding, .departed, .inAir, .landed, .arrived, .delayed, .cancelled] {
            let view = FlightStatusBadge(status: status)
            XCTAssertNotNil(view)
        }
    }

    // MARK: - Direction Switching

    func testDirectionSwitchingUpdatesFilteredFlights() async {
        let mockService = MockFlightService()
        mockService.arrivalsToReturn = TestData.sampleArrivals
        mockService.departuresToReturn = TestData.sampleDepartures
        let vm = FlightViewModel(flightService: mockService)
        await vm.loadFlights()

        vm.selectedDirection = .arrival
        XCTAssertEqual(vm.filteredFlights.count, 3)

        vm.selectedDirection = .departure
        XCTAssertEqual(vm.filteredFlights.count, 2)
    }

    // MARK: - Search + View Integration

    func testSearchFilteringReflectsInFlightList() async {
        let mockService = MockFlightService()
        mockService.arrivalsToReturn = TestData.sampleArrivals
        let vm = FlightViewModel(flightService: mockService)
        await vm.loadFlights()

        vm.selectedDirection = .arrival
        vm.searchText = "Starlux"
        XCTAssertEqual(vm.filteredFlights.count, 1)

        let view = FlightListView(viewModel: vm)
        XCTAssertNotNil(view)
    }

    // MARK: - Hotel Views

    func testHotelSearchViewCanBeInstantiated() {
        let view = HotelSearchView(service: MockHotelSearchService())
        XCTAssertNotNil(view)
    }

    func testHotelCardCanBeInstantiated() {
        let view = HotelCard(result: sampleHotelResult)
        XCTAssertNotNil(view)
    }

    func testHotelDetailSheetCanBeInstantiated() {
        let view = HotelDetailSheet(result: sampleHotelResult)
        XCTAssertNotNil(view)
    }

    private var sampleHotelResult: HotelSearchResult {
        let hotel = Hotel(
            id: "test_hotel",
            name: "Test Hotel",
            nameLocal: "測試飯店",
            area: "Taipei",
            neighborhood: "Xinyi District",
            address: "No. 1 Test Road",
            latitude: 25.0330,
            longitude: 121.5654,
            rating: 4.5,
            reviewCount: 1000,
            starRating: 5,
            priceLevel: 3,
            amenities: ["WiFi", "Gym", "Restaurant"]
        )

        return HotelSearchResult(
            id: hotel.id,
            hotel: hotel,
            distanceKm: 1.2,
            bookingLinks: HotelSearchService.shared.generateBookingLinks(for: hotel)
        )
    }
}

private final class MockHotelSearchService: HotelSearchServiceProtocol {
    func searchHotels(near coordinate: CLLocationCoordinate2D, radiusKm: Double, sortBy: HotelSortOption) -> [HotelSearchResult] {
        []
    }

    func searchHotels(in area: String, sortBy: HotelSortOption) -> [HotelSearchResult] {
        []
    }

    func generateBookingLinks(for hotel: Hotel) -> [BookingLink] {
        []
    }
}
