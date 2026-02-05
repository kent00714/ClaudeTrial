import XCTest
@testable import TPEFlightTracker

@MainActor
final class FlightViewModelTests: XCTestCase {

    private var mockService: MockFlightService!
    private var viewModel: FlightViewModel!

    override func setUp() {
        super.setUp()
        mockService = MockFlightService()
        viewModel = FlightViewModel(flightService: mockService)
    }

    override func tearDown() {
        viewModel = nil
        mockService = nil
        super.tearDown()
    }

    // MARK: - Initial State

    func testInitialStateIsEmpty() {
        XCTAssertTrue(viewModel.arrivals.isEmpty)
        XCTAssertTrue(viewModel.departures.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.searchText, "")
        XCTAssertEqual(viewModel.selectedDirection, .arrival)
        XCTAssertNil(viewModel.lastUpdated)
        XCTAssertNil(viewModel.nextRefresh)
    }

    // MARK: - Loading Flights

    func testLoadFlightsPopulatesArrivalsAndDepartures() async {
        mockService.arrivalsToReturn = TestData.sampleArrivals
        mockService.departuresToReturn = TestData.sampleDepartures

        await viewModel.loadFlights()

        XCTAssertEqual(viewModel.arrivals.count, 3)
        XCTAssertEqual(viewModel.departures.count, 2)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testLoadFlightsCallsServiceTwice() async {
        await viewModel.loadFlights()
        // Once for arrivals, once for departures
        XCTAssertEqual(mockService.fetchCallCount, 2)
    }

    func testLoadFlightsSetsErrorOnFailure() async {
        mockService.errorToThrow = TestError.networkFailure

        await viewModel.loadFlights()

        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, "Network connection failed")
        XCTAssertTrue(viewModel.arrivals.isEmpty)
        XCTAssertTrue(viewModel.departures.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testRefreshCallsLoadFlights() async {
        mockService.arrivalsToReturn = TestData.sampleArrivals
        mockService.departuresToReturn = TestData.sampleDepartures

        await viewModel.refresh()

        XCTAssertEqual(viewModel.arrivals.count, 3)
        XCTAssertEqual(viewModel.departures.count, 2)
    }

    // MARK: - Filtered Flights by Direction

    func testFilteredFlightsReturnsArrivalsWhenDirectionIsArrival() async {
        mockService.arrivalsToReturn = TestData.sampleArrivals
        mockService.departuresToReturn = TestData.sampleDepartures
        await viewModel.loadFlights()

        viewModel.selectedDirection = .arrival
        XCTAssertEqual(viewModel.filteredFlights.count, 3)

        viewModel.selectedDirection = .departure
        XCTAssertEqual(viewModel.filteredFlights.count, 2)
    }

    // MARK: - Search Filtering

    func testSearchByFlightNumber() async {
        mockService.arrivalsToReturn = TestData.sampleArrivals
        await viewModel.loadFlights()

        viewModel.selectedDirection = .arrival
        viewModel.searchText = "CI100"
        XCTAssertEqual(viewModel.filteredFlights.count, 1)
        XCTAssertEqual(viewModel.filteredFlights.first?.flightNumber, "CI100")
    }

    func testSearchByAirline() async {
        mockService.arrivalsToReturn = TestData.sampleArrivals
        await viewModel.loadFlights()

        viewModel.selectedDirection = .arrival
        viewModel.searchText = "EVA"
        XCTAssertEqual(viewModel.filteredFlights.count, 1)
        XCTAssertEqual(viewModel.filteredFlights.first?.airline, "EVA Air")
    }

    func testSearchByCity() async {
        mockService.arrivalsToReturn = TestData.sampleArrivals
        await viewModel.loadFlights()

        viewModel.selectedDirection = .arrival
        viewModel.searchText = "Tokyo"
        XCTAssertEqual(viewModel.filteredFlights.count, 1)
        XCTAssertEqual(viewModel.filteredFlights.first?.counterpartCity, "Tokyo")
    }

    func testSearchByIATACode() async {
        mockService.arrivalsToReturn = TestData.sampleArrivals
        await viewModel.loadFlights()

        viewModel.selectedDirection = .arrival
        viewModel.searchText = "ICN"
        XCTAssertEqual(viewModel.filteredFlights.count, 1)
        XCTAssertEqual(viewModel.filteredFlights.first?.counterpartIATA, "ICN")
    }

    func testSearchIsCaseInsensitive() async {
        mockService.arrivalsToReturn = TestData.sampleArrivals
        await viewModel.loadFlights()

        viewModel.selectedDirection = .arrival
        viewModel.searchText = "china airlines"
        XCTAssertEqual(viewModel.filteredFlights.count, 1)

        viewModel.searchText = "CHINA AIRLINES"
        XCTAssertEqual(viewModel.filteredFlights.count, 1)
    }

    func testEmptySearchReturnsAllFlights() async {
        mockService.arrivalsToReturn = TestData.sampleArrivals
        await viewModel.loadFlights()

        viewModel.selectedDirection = .arrival
        viewModel.searchText = ""
        XCTAssertEqual(viewModel.filteredFlights.count, 3)
    }

    func testSearchWithNoMatchesReturnsEmpty() async {
        mockService.arrivalsToReturn = TestData.sampleArrivals
        await viewModel.loadFlights()

        viewModel.selectedDirection = .arrival
        viewModel.searchText = "ZZZZZ"
        XCTAssertTrue(viewModel.filteredFlights.isEmpty)
    }

    func testSearchOnlyFiltersBySelectedDirection() async {
        mockService.arrivalsToReturn = TestData.sampleArrivals
        mockService.departuresToReturn = TestData.sampleDepartures
        await viewModel.loadFlights()

        // "CI" matches both arrival CI100 and departure CI101
        viewModel.selectedDirection = .arrival
        viewModel.searchText = "CI"
        XCTAssertEqual(viewModel.filteredFlights.count, 1)
        XCTAssertEqual(viewModel.filteredFlights.first?.flightNumber, "CI100")

        viewModel.selectedDirection = .departure
        viewModel.searchText = "CI"
        XCTAssertEqual(viewModel.filteredFlights.count, 1)
        XCTAssertEqual(viewModel.filteredFlights.first?.flightNumber, "CI101")
    }

    // MARK: - Loading State

    func testLoadFlightsClearsErrorMessage() async {
        mockService.errorToThrow = TestError.networkFailure
        await viewModel.loadFlights()
        XCTAssertNotNil(viewModel.errorMessage)

        // Now load successfully
        mockService.errorToThrow = nil
        mockService.arrivalsToReturn = TestData.sampleArrivals
        mockService.departuresToReturn = TestData.sampleDepartures
        await viewModel.loadFlights()
        XCTAssertNil(viewModel.errorMessage)
    }

    // MARK: - Last Updated

    func testLoadFlightsSetsLastUpdated() async {
        mockService.arrivalsToReturn = TestData.sampleArrivals
        mockService.departuresToReturn = TestData.sampleDepartures

        XCTAssertNil(viewModel.lastUpdated)
        await viewModel.loadFlights()
        XCTAssertNotNil(viewModel.lastUpdated)
    }

    func testLoadFlightsDoesNotSetLastUpdatedOnError() async {
        mockService.errorToThrow = TestError.networkFailure
        await viewModel.loadFlights()
        XCTAssertNil(viewModel.lastUpdated)
    }

    // MARK: - Auto Refresh

    func testStartAutoRefreshLoadsFlights() async {
        mockService.arrivalsToReturn = TestData.sampleArrivals
        mockService.departuresToReturn = TestData.sampleDepartures

        viewModel.startAutoRefresh()
        // Give the task a moment to run
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(viewModel.arrivals.count, 3)
        XCTAssertEqual(viewModel.departures.count, 2)
        XCTAssertNotNil(viewModel.lastUpdated)
        XCTAssertNotNil(viewModel.nextRefresh)

        viewModel.stopAutoRefresh()
    }

    func testStopAutoRefreshClearsNextRefresh() async {
        mockService.arrivalsToReturn = TestData.sampleArrivals
        mockService.departuresToReturn = TestData.sampleDepartures

        viewModel.startAutoRefresh()
        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertNotNil(viewModel.nextRefresh)

        viewModel.stopAutoRefresh()
        XCTAssertNil(viewModel.nextRefresh)
    }

    // MARK: - API Config Budget

    func testAutoRefreshIntervalIs90Minutes() {
        XCTAssertEqual(APIConfig.autoRefreshInterval, 90 * 60)
    }

    func testMonthlyBudgetCoversRefreshes() {
        let refreshesPerDay = (24 * 60 * 60) / APIConfig.autoRefreshInterval
        let requestsPerDay = refreshesPerDay * Double(APIConfig.requestsPerRefresh)
        let requestsPerMonth = requestsPerDay * 30
        XCTAssertLessThanOrEqual(requestsPerMonth, Double(APIConfig.monthlyRequestLimit),
                                  "Monthly requests should stay within free tier limit")
    }
}
