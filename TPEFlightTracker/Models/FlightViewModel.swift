import Foundation

@MainActor
class FlightViewModel: ObservableObject {
    @Published var arrivals: [Flight] = []
    @Published var departures: [Flight] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var selectedDirection: FlightDirection = .arrival

    private let flightService = FlightService()

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

    func loadFlights() async {
        isLoading = true
        errorMessage = nil

        do {
            async let fetchedArrivals = flightService.fetchFlights(direction: .arrival)
            async let fetchedDepartures = flightService.fetchFlights(direction: .departure)

            let (arr, dep) = try await (fetchedArrivals, fetchedDepartures)
            arrivals = arr
            departures = dep
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func refresh() async {
        await loadFlights()
    }
}
