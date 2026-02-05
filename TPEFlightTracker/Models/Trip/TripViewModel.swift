import Foundation
import CoreLocation

@MainActor
class TripViewModel: ObservableObject {
    @Published var trips: [Trip] = []
    @Published var selectedTrip: Trip?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let tripService: TripServiceProtocol
    private let directionsService: DirectionsServiceProtocol

    init(
        tripService: TripServiceProtocol = TripService(),
        directionsService: DirectionsServiceProtocol = DirectionsService()
    ) {
        self.tripService = tripService
        self.directionsService = directionsService
        loadTrips()
    }

    func loadTrips() {
        trips = tripService.loadTrips()
    }

    func createTrip(name: String, startDate: Date, endDate: Date) {
        let trip = Trip(
            name: name,
            startDate: startDate,
            endDate: endDate
        )
        tripService.addTrip(trip)
        loadTrips()
    }

    /// Create a trip from a suggestion (with destinations pre-populated)
    func createTripFromSuggestion(_ trip: Trip) {
        tripService.addTrip(trip)
        loadTrips()
    }

    func updateTrip(_ trip: Trip) {
        tripService.updateTrip(trip)
        loadTrips()
        if selectedTrip?.id == trip.id {
            selectedTrip = trip
        }
    }

    func deleteTrip(_ trip: Trip) {
        tripService.deleteTrip(id: trip.id)
        loadTrips()
        if selectedTrip?.id == trip.id {
            selectedTrip = nil
        }
    }

    func selectTrip(_ trip: Trip) {
        selectedTrip = trip
    }

    // MARK: - Destination Management

    func addDestination(
        to trip: Trip,
        name: String,
        address: String,
        coordinate: CLLocationCoordinate2D,
        travelMode: TravelMode = .driving
    ) async {
        var updatedTrip = trip
        let newOrder = trip.destinations.count

        var destination = TripDestination(
            name: name,
            address: address,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            order: newOrder,
            travelMode: travelMode
        )

        // Calculate route from previous destination
        if let lastDest = trip.destinations.last {
            do {
                let route = try await directionsService.calculateRoute(
                    from: lastDest.coordinate,
                    to: coordinate,
                    mode: travelMode
                )
                destination.travelDistanceMeters = route.distanceMeters
                destination.travelDurationMinutes = route.durationMinutes
            } catch {
                print("Failed to calculate route: \(error)")
            }
        }

        updatedTrip.destinations.append(destination)
        updateTrip(updatedTrip)
    }

    func updateDestination(_ destination: TripDestination, in trip: Trip) async {
        var updatedTrip = trip
        guard let index = updatedTrip.destinations.firstIndex(where: { $0.id == destination.id }) else {
            return
        }

        var updatedDestination = destination

        // Recalculate route from previous destination
        if index > 0 {
            let prevDest = updatedTrip.destinations[index - 1]
            do {
                let route = try await directionsService.calculateRoute(
                    from: prevDest.coordinate,
                    to: updatedDestination.coordinate,
                    mode: updatedDestination.travelMode
                )
                updatedDestination.travelDistanceMeters = route.distanceMeters
                updatedDestination.travelDurationMinutes = route.durationMinutes
            } catch {
                print("Failed to calculate route: \(error)")
            }
        }

        updatedTrip.destinations[index] = updatedDestination
        updateTrip(updatedTrip)

        // Recalculate next destination's route if exists
        if index + 1 < updatedTrip.destinations.count {
            await recalculateRoute(forDestinationAt: index + 1, in: updatedTrip)
        }
    }

    func removeDestination(_ destination: TripDestination, from trip: Trip) async {
        var updatedTrip = trip
        guard let index = updatedTrip.destinations.firstIndex(where: { $0.id == destination.id }) else {
            return
        }

        updatedTrip.destinations.remove(at: index)

        // Reorder remaining destinations
        for i in 0..<updatedTrip.destinations.count {
            updatedTrip.destinations[i].order = i
        }

        updateTrip(updatedTrip)

        // Recalculate route for the destination that now follows
        if index < updatedTrip.destinations.count {
            await recalculateRoute(forDestinationAt: index, in: updatedTrip)
        }
    }

    func reorderDestinations(in trip: Trip, from source: IndexSet, to destination: Int) async {
        var updatedTrip = trip
        updatedTrip.destinations.move(fromOffsets: source, toOffset: destination)

        // Update order values
        for i in 0..<updatedTrip.destinations.count {
            updatedTrip.destinations[i].order = i
        }

        updateTrip(updatedTrip)

        // Recalculate all routes
        await recalculateAllRoutes(for: updatedTrip)
    }

    // MARK: - Route Calculation

    func recalculateAllRoutes(for trip: Trip) async {
        isLoading = true
        var updatedTrip = trip

        for i in 0..<updatedTrip.destinations.count {
            if i == 0 {
                updatedTrip.destinations[i].travelDistanceMeters = nil
                updatedTrip.destinations[i].travelDurationMinutes = nil
                continue
            }

            let prevDest = updatedTrip.destinations[i - 1]
            let currentDest = updatedTrip.destinations[i]

            do {
                let route = try await directionsService.calculateRoute(
                    from: prevDest.coordinate,
                    to: currentDest.coordinate,
                    mode: currentDest.travelMode
                )
                updatedTrip.destinations[i].travelDistanceMeters = route.distanceMeters
                updatedTrip.destinations[i].travelDurationMinutes = route.durationMinutes
            } catch {
                print("Failed to calculate route for destination \(i): \(error)")
            }
        }

        updateTrip(updatedTrip)
        isLoading = false
    }

    private func recalculateRoute(forDestinationAt index: Int, in trip: Trip) async {
        guard index > 0, index < trip.destinations.count else { return }

        var updatedTrip = tripService.getTrip(id: trip.id) ?? trip
        let prevDest = updatedTrip.destinations[index - 1]
        let currentDest = updatedTrip.destinations[index]

        do {
            let route = try await directionsService.calculateRoute(
                from: prevDest.coordinate,
                to: currentDest.coordinate,
                mode: currentDest.travelMode
            )
            updatedTrip.destinations[index].travelDistanceMeters = route.distanceMeters
            updatedTrip.destinations[index].travelDurationMinutes = route.durationMinutes
            updateTrip(updatedTrip)
        } catch {
            print("Failed to recalculate route: \(error)")
        }
    }
}
