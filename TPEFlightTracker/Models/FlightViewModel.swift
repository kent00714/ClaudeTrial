import Foundation

@MainActor
class FlightViewModel: ObservableObject {
    @Published var arrivals: [Flight] = []
    @Published var departures: [Flight] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var selectedDirection: FlightDirection = .arrival
    @Published var lastUpdated: Date?
    @Published var nextRefresh: Date?

    private let flightService: FlightServiceProtocol
    private var refreshTask: Task<Void, Never>?

    init(flightService: FlightServiceProtocol = FlightService()) {
        self.flightService = flightService
    }

    var filteredFlights: [Flight] {
        let flights = selectedDirection == .arrival ? arrivals : departures

        if searchText.isEmpty {
            return flights
        }

        return flights.filter { flight in
            flight.flightNumber.localizedCaseInsensitiveContains(searchText) ||
            flight.airline.localizedCaseInsensitiveContains(searchText) ||
            flight.counterpartCity.localizedCaseInsensitiveContains(searchText) ||
            flight.counterpartIATA.localizedCaseInsensitiveContains(searchText)
        }
    }

    // MARK: - Compatibility Properties

    /// Combined flights from arrivals and departures for compatibility
    var flights: [Flight] {
        arrivals + departures
    }

    /// Alias for searchText for compatibility
    var searchQuery: String {
        get { searchText }
        set { searchText = newValue }
    }

    // MARK: - Loading Methods

    func loadFlights() async {
        isLoading = true
        errorMessage = nil

        do {
            async let fetchedArrivals = flightService.fetchFlights(direction: .arrival)
            async let fetchedDepartures = flightService.fetchFlights(direction: .departure)

            let (arr, dep) = try await (fetchedArrivals, fetchedDepartures)
            arrivals = arr
            departures = dep
            lastUpdated = Date()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func refresh() async {
        await loadFlights()
    }

    /// Alias for loadFlights() for compatibility
    func searchFlights() async {
        await loadFlights()
    }

    // MARK: - Auto Refresh Timer

    func startAutoRefresh() {
        stopAutoRefresh()
        refreshTask = Task { [weak self] in
            guard let self else { return }
            // Initial load
            await self.loadFlights()

            // Schedule repeating refreshes
            while !Task.isCancelled {
                let interval = APIConfig.autoRefreshInterval
                self.nextRefresh = Date().addingTimeInterval(interval)
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))

                guard !Task.isCancelled else { break }
                await self.loadFlights()
            }
        }
    }

    func stopAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
        nextRefresh = nil
    }
}
